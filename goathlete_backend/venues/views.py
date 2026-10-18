from rest_framework import viewsets, permissions
from rest_framework.response import Response
from .models import Venue, PreRegisteredVenue
from .serializers import VenueSerializer, PreRegisteredVenueSerializer

class VenueViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows venues to be viewed.
    """
    queryset = Venue.objects.all()
    serializer_class = VenueSerializer

    def get_queryset(self):
        queryset = Venue.objects.all()
        lat = self.request.query_params.get('lat')
        lng = self.request.query_params.get('lng')
        
        if lat and lng:
            try:
                from django.db.models import F, FloatField, ExpressionWrapper
                from django.db.models.functions import Power, Sin, Cos, Radians
                
                lat_f = float(lat)
                lng_f = float(lng)
                
                dlat = Radians(F('latitude') - lat_f)
                dlng = Radians(F('longitude') - lng_f)
                
                a = Power(Sin(dlat / 2.0), 2) + Cos(Radians(lat_f)) * Cos(Radians(F('latitude'))) * Power(Sin(dlng / 2.0), 2)
                c = 2.0 * 6371.0 # Earth radius in km
                
                # Approximate distance calculation
                # For simplicity in sqlite/django without postgis, we can just order by rough euclidean distance squared
                # because the trig functions might not be available in sqlite
                distance_expr = ExpressionWrapper(
                    Power(F('latitude') - lat_f, 2) + Power(F('longitude') - lng_f, 2),
                    output_field=FloatField()
                )
                
                queryset = queryset.annotate(computed_distance=distance_expr).order_by(F('computed_distance').asc(nulls_last=True), '-rating')
                return queryset
            except Exception as e:
                pass
                
        return queryset.order_by('-rating')

class PreRegisteredVenueViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows executives to pre-register venues.
    """
    serializer_class = PreRegisteredVenueSerializer

    def get_queryset(self):
        # Executives only see their own venues. Admin sees all.
        user = self.request.user
        if not user.is_authenticated:
            return PreRegisteredVenue.objects.all()
        if getattr(user, 'profile', None) and user.profile.role == 'SUPER_ADMIN':
            return PreRegisteredVenue.objects.all()
        return PreRegisteredVenue.objects.filter(executive=user)

    def perform_create(self, serializer):
        serializer.save(executive=self.request.user, status='PENDING_APPROVAL')

    from rest_framework.decorators import action
    from rest_framework.response import Response

    @action(detail=True, methods=['post'], permission_classes=[permissions.AllowAny])
    def approve(self, request, pk=None):
        venue = self.get_object()
        venue.status = 'APPROVED'
        
        # Create a real Venue here if it doesn't exist
        if not venue.real_venue:
            from django.contrib.auth.models import User
            import uuid
            
            username = venue.phone_number if venue.phone_number else venue.email
            if not username:
                username = f"vendor_{uuid.uuid4().hex[:8]}"
                
            user, created = User.objects.get_or_create(username=username)
            if created:
                user.first_name = venue.owner_name
                user.email = venue.email or ''
                password = 'Test@12345'
                user.set_password(password)
                user.save()
                
                print(f"EMAIL SENT: Vendor login details for {venue.name}: Username: {username}, Password: {password}")

                if hasattr(user, 'profile'):
                    profile = user.profile
                    profile.requires_password_change = True
                    profile.save()

            if hasattr(user, 'profile'):
                profile = user.profile
                if profile.role != 'VENDOR':
                    profile.role = 'VENDOR'
                if not profile.phone_number and venue.phone_number:
                    profile.phone_number = venue.phone_number
                profile.save()

            real_venue = Venue.objects.create(
                name=venue.name,
                location=venue.address,
                owner=user,
                latitude=venue.latitude,
                longitude=venue.longitude,
                license_number=venue.license_number,
                sports_prices=venue.sports_prices
            )
            venue.real_venue = real_venue
            
        venue.save()
        return Response({'status': 'venue approved'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.AllowAny])
    def reject(self, request, pk=None):
        venue = self.get_object()
        venue.status = 'REJECTED'
        venue.save()
        return Response({'status': 'venue rejected'})

    @action(detail=False, methods=['get'])
    def dashboard_stats(self, request):
        user = request.user
        venues = PreRegisteredVenue.objects.filter(executive=user)
        total_onboarded = venues.count()
        pending = venues.filter(status__in=['DRAFT', 'PENDING_APPROVAL']).count()
        approved = venues.filter(status='APPROVED').count()
        
        real_venue_ids = venues.filter(real_venue__isnull=False).values_list('real_venue_id', flat=True)
        from bookings.models import Booking
        bookings = Booking.objects.filter(venue_id__in=real_venue_ids)
        total_bookings = bookings.count()
        recent_bookings = bookings.order_by('-created_at')[:5]
        
        from bookings.serializers import BookingSerializer
        
        return Response({
            'total_onboarded': total_onboarded,
            'pending_approval': pending,
            'approved_venues': approved,
            'total_bookings': total_bookings,
            'recent_bookings': BookingSerializer(recent_bookings, many=True).data
        })

from rest_framework import permissions

class VendorVenueViewSet(viewsets.ModelViewSet):
    """
    API endpoint for vendors to edit their owned venues.
    """
    serializer_class = VenueSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return Venue.objects.none()
        return Venue.objects.filter(owner=user)

    def create(self, request, *args, **kwargs):
        data = request.data
        user = request.user
        phone = ''
        if hasattr(user, 'profile') and user.profile.phone_number:
            phone = user.profile.phone_number

        from .models import PreRegisteredVenue
        prereg = PreRegisteredVenue.objects.create(
            executive=user,
            name=data.get('name', ''),
            owner_name=user.first_name or user.username,
            phone_number=phone,
            email=user.email,
            address=data.get('location', ''),
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
            status='PENDING_APPROVAL'
        )
        return Response({'message': 'Venue submitted for KYC approval.', 'id': prereg.id}, status=201)

from .serializers import VendorPartnerSerializer, RentalItemSerializer
from .models import VendorPartner, RentalItem

class VendorPartnerViewSet(viewsets.ModelViewSet):
    serializer_class = VendorPartnerSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return VendorPartner.objects.none()
        return VendorPartner.objects.filter(venue__owner=user)

    def create(self, request, *args, **kwargs):
        venue_id = request.data.get('venue')
        user_email = request.data.get('user_email')
        
        from django.contrib.auth.models import User
        from users.models import UserProfile
        if user_email:
            try:
                user = User.objects.get(email=user_email)
            except User.DoesNotExist:
                import uuid
                username = f"partner_{uuid.uuid4().hex[:8]}"
                user = User.objects.create_user(username=username, email=user_email)
                user.set_password('Test@12345')
                user.save()
                profile, _ = UserProfile.objects.get_or_create(user=user)
                profile.role = request.data.get('role', 'MANAGER')
                profile.requires_password_change = True
                profile.save()
            
            data = request.data.copy()
            data['user'] = user.id
            serializer = self.get_serializer(data=data)
            serializer.is_valid(raise_exception=True)
            partner = serializer.save()
        else:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            partner = serializer.save()
            user = partner.user
            
        if hasattr(user, 'profile'):
            if user.profile.role != 'VENDOR':
                user.profile.role = 'VENDOR'
                user.profile.save()
        
        return Response(serializer.data, status=201)

class RentalItemViewSet(viewsets.ModelViewSet):
    serializer_class = RentalItemSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        queryset = RentalItem.objects.all()
        venue_id = self.request.query_params.get('venue')
        if venue_id:
            queryset = queryset.filter(venue_id=venue_id)
        return queryset

from .models import Court, CourtSlotPricing
from .serializers import CourtSerializer, CourtSlotPricingSerializer

class CourtViewSet(viewsets.ModelViewSet):
    serializer_class = CourtSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        queryset = Court.objects.all()
        # Restrict mutations to venue owner if possible via permissions, but for simplicity
        # limit what they can see/edit if they are not admin.
        # But wait, IsAuthenticatedOrReadOnly allows any authenticated to create/edit.
        
        venue_id = self.request.query_params.get('venue')
        if venue_id:
            queryset = queryset.filter(venue_id=venue_id)
        
        # If not a GET request, restrict to owned venues
        if self.request.method not in permissions.SAFE_METHODS:
            queryset = queryset.filter(venue__owner=user)
            
        return queryset

    def perform_create(self, serializer):
        venue = serializer.validated_data.get('venue')
        if venue.owner != self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You do not own this venue.")
        serializer.save()

class CourtSlotPricingViewSet(viewsets.ModelViewSet):
    serializer_class = CourtSlotPricingSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        queryset = CourtSlotPricing.objects.all()
        court_id = self.request.query_params.get('court')
        if court_id:
            queryset = queryset.filter(court_id=court_id)
            
        # If not a GET request, restrict to owned venues
        if self.request.method not in permissions.SAFE_METHODS:
            queryset = queryset.filter(court__venue__owner=user)
            
        return queryset

    def perform_create(self, serializer):
        court = serializer.validated_data.get('court')
        if court.venue.owner != self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You do not own this court.")
        serializer.save()


