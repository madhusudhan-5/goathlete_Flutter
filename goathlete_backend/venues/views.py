from rest_framework import viewsets, permissions
from rest_framework.response import Response
from .models import Venue, PreRegisteredVenue
from .serializers import VenueSerializer, PreRegisteredVenueSerializer

class VenueViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows venues to be viewed.
    """
    queryset = Venue.objects.all().order_by('-rating')
    serializer_class = VenueSerializer

class PreRegisteredVenueViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows executives to pre-register venues.
    """
    serializer_class = PreRegisteredVenueSerializer

    def get_queryset(self):
        # Executives only see their own venues. Admin sees all.
        user = self.request.user
        if not user.is_authenticated:
            return PreRegisteredVenue.objects.none()
        if getattr(user, 'profile', None) and user.profile.role == 'SUPER_ADMIN':
            return PreRegisteredVenue.objects.all()
        return PreRegisteredVenue.objects.filter(executive=user)

    def perform_create(self, serializer):
        serializer.save(executive=self.request.user)

    from rest_framework.decorators import action
    from rest_framework.response import Response

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        venue = self.get_object()
        venue.status = 'APPROVED'
        
        # Create a real Venue here if it doesn't exist
        if not venue.real_venue:
            real_venue = Venue.objects.create(
                name=venue.name,
                location=venue.address,
                # Link owner if possible, or just leave it blank for now
            )
            venue.real_venue = real_venue
            
        venue.save()
        return Response({'status': 'venue approved'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
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

