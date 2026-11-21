import json
import ssl
import urllib.parse
import urllib.request
from django.conf import settings
from django.db.models import Q, F, FloatField, ExpressionWrapper
from django.db.models.functions import Power
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Venue, PreRegisteredVenue
from .serializers import VenueSerializer, PreRegisteredVenueSerializer

_SSL_CTX = ssl._create_unverified_context()


def _reverse_geocode_coords(lat, lng):
    """
    Reverse-geocodes (lat, lng) into a human-readable locality/city string.
    Uses Google Maps Geocoding API if a valid MAPS_API_KEY is configured,
    otherwise falls back to free OpenStreetMap Nominatim API.
    """
    try:
        lat_f, lng_f = float(lat), float(lng)
    except (TypeError, ValueError):
        return None

    maps_key = getattr(settings, 'MAPS_API_KEY', '') or ''
    if maps_key and not maps_key.startswith('your_'):
        try:
            g_url = (
                f"https://maps.googleapis.com/maps/api/geocode/json"
                f"?latlng={lat_f},{lng_f}&key={maps_key}"
            )
            req = urllib.request.Request(g_url, headers={'User-Agent': 'GoAthleteApp/1.0'})
            with urllib.request.urlopen(req, timeout=4, context=_SSL_CTX) as resp:
                g_data = json.loads(resp.read().decode())
                if g_data.get('status') == 'OK' and g_data.get('results'):
                    return g_data['results'][0].get('formatted_address')
        except Exception:
            pass

    try:
        url = (
            f"https://nominatim.openstreetmap.org/reverse"
            f"?format=json&lat={lat_f}&lon={lng_f}&zoom=16&addressdetails=1"
        )
        req = urllib.request.Request(url, headers={'User-Agent': 'GoAthleteApp/1.0'})
        with urllib.request.urlopen(req, timeout=5, context=_SSL_CTX) as resp:
            data = json.loads(resp.read().decode())
            addr = data.get('address', {})
            locality = (
                addr.get('suburb')
                or addr.get('neighbourhood')
                or addr.get('residential')
                or addr.get('quarter')
                or addr.get('village')
                or addr.get('town')
            )
            district = addr.get('city_district') or addr.get('county')
            city = (
                addr.get('city')
                or addr.get('town')
                or addr.get('state_district')
                or addr.get('state')
            )
            parts = []
            for p in (locality, district, city):
                if p and p not in parts:
                    parts.append(p)
            if parts:
                return ', '.join(parts[:3])
            return data.get('display_name')
    except Exception:
        return None


def _search_places_api(query, limit=6):
    """
    Searches places/localities matching `query`.
    Uses Google Maps Geocoding API if MAPS_API_KEY is configured,
    with automatic fallback to free OpenStreetMap Nominatim API.
    """
    q = (query or '').strip()
    if not q:
        return []

    results = []
    maps_key = getattr(settings, 'MAPS_API_KEY', '') or ''
    if maps_key and not maps_key.startswith('your_'):
        try:
            params = urllib.parse.urlencode({'address': q, 'region': 'in', 'key': maps_key})
            g_url = f"https://maps.googleapis.com/maps/api/geocode/json?{params}"
            req = urllib.request.Request(g_url, headers={'User-Agent': 'GoAthleteApp/1.0'})
            with urllib.request.urlopen(req, timeout=4, context=_SSL_CTX) as resp:
                g_data = json.loads(resp.read().decode())
                if g_data.get('status') == 'OK':
                    for item in g_data.get('results', [])[:limit]:
                        loc = item.get('geometry', {}).get('location', {})
                        fmt = item.get('formatted_address', '')
                        short = ', '.join([p.strip() for p in fmt.split(',')[:2]])
                        if 'lat' in loc and 'lng' in loc:
                            results.append({
                                'short_name': short or fmt,
                                'display_name': fmt,
                                'lat': float(loc['lat']),
                                'lng': float(loc['lng']),
                            })
                    if results:
                        return results
        except Exception:
            pass

    try:
        params = urllib.parse.urlencode({
            'q': q,
            'format': 'json',
            'addressdetails': 1,
            'limit': limit,
            'countrycodes': 'in',
        })
        url = f"https://nominatim.openstreetmap.org/search?{params}"
        req = urllib.request.Request(url, headers={'User-Agent': 'GoAthleteApp/1.0'})
        with urllib.request.urlopen(req, timeout=5, context=_SSL_CTX) as resp:
            items = json.loads(resp.read().decode())
            seen = set()
            for it in items:
                addr = it.get('address', {})
                name = (
                    it.get('name')
                    or addr.get('suburb')
                    or addr.get('neighbourhood')
                    or addr.get('village')
                    or addr.get('town')
                    or addr.get('city')
                    or ''
                )
                city = (
                    addr.get('city')
                    or addr.get('town')
                    or addr.get('state_district')
                    or addr.get('state')
                    or ''
                )
                short = f"{name}, {city}".strip(', ') if name and name != city else (name or city)
                if not short:
                    short = ', '.join([p.strip() for p in it.get('display_name', '').split(',')[:2]])
                dedup_key = (short.lower(), round(float(it['lat']), 2), round(float(it['lon']), 2))
                if dedup_key in seen:
                    continue
                seen.add(dedup_key)
                results.append({
                    'short_name': short,
                    'display_name': it.get('display_name', short),
                    'lat': float(it['lat']),
                    'lng': float(it['lon']),
                })
    except Exception:
        pass

    return results


class VenueViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows venues to be viewed, searched by location, and geocoded.
    """
    queryset = Venue.objects.all()
    serializer_class = VenueSerializer

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        if hasattr(self, '_resolved_lat') and self._resolved_lat is not None:
            ctx['search_lat'] = self._resolved_lat
            ctx['search_lng'] = self._resolved_lng
        return ctx

    def get_queryset(self):
        from django.db.models import Q, F, FloatField, ExpressionWrapper
        from django.db.models.functions import Power

        queryset = Venue.objects.all()
        location_query = (self.request.query_params.get('location') or self.request.query_params.get('q') or '').strip()
        lat = self.request.query_params.get('lat')
        lng = self.request.query_params.get('lng')

        lat_f = None
        lng_f = None
        if lat is not None and lng is not None:
            try:
                lat_f = float(lat)
                lng_f = float(lng)
            except (TypeError, ValueError):
                pass

        if location_query and location_query.lower() not in ('all', 'all locations', 'fetching location...'):
            # If no coordinates were passed for the searched location, geocode the query
            if lat_f is None or lng_f is None:
                places = _search_places_api(location_query, limit=1)
                if places:
                    lat_f = places[0]['lat']
                    lng_f = places[0]['lng']

            parts = [p.strip() for p in location_query.split(',') if p.strip()]
            primary_part = parts[0] if parts else location_query

            q_filter = Q(location__icontains=location_query) | Q(name__icontains=location_query)
            q_filter |= Q(location__icontains=primary_part) | Q(name__icontains=primary_part)

            if primary_part.lower() == 'bengaluru':
                q_filter |= Q(location__icontains='Bangalore')
            elif primary_part.lower() == 'bangalore':
                q_filter |= Q(location__icontains='Bengaluru')

            # Include venues within ~2.5km (~0.022 degrees lat/lng) of the searched locality's coordinates
            if lat_f is not None and lng_f is not None and primary_part.lower() not in ('bengaluru', 'bangalore', 'karnataka', 'india'):
                radius_deg = 0.022
                q_filter |= Q(
                    latitude__isnull=False,
                    longitude__isnull=False,
                    latitude__gte=lat_f - radius_deg,
                    latitude__lte=lat_f + radius_deg,
                    longitude__gte=lng_f - radius_deg,
                    longitude__lte=lng_f + radius_deg,
                )

            queryset = queryset.filter(q_filter)

        self._resolved_lat = lat_f
        self._resolved_lng = lng_f

        if lat_f is not None and lng_f is not None:
            try:
                distance_expr = ExpressionWrapper(
                    Power(F('latitude') - lat_f, 2) + Power(F('longitude') - lng_f, 2),
                    output_field=FloatField()
                )
                queryset = queryset.annotate(computed_distance=distance_expr).order_by(
                    F('computed_distance').asc(nulls_last=True), '-rating'
                )
                return queryset
            except Exception:
                pass

        return queryset.order_by('-rating')

    @action(detail=False, methods=['get'], permission_classes=[permissions.AllowAny])
    def search_places(self, request):
        q = (request.query_params.get('q') or '').strip()
        if not q:
            return Response([])

        results = []
        # 1. Include matching registered venues/locations first
        matching_venues = Venue.objects.filter(
            Q(name__icontains=q) | Q(location__icontains=q)
        )[:4]
        for v in matching_venues:
            loc_str = v.location if v.location and not v.location.startswith('Lat:') else v.name
            results.append({
                'short_name': loc_str,
                'display_name': f"{v.name} — {v.location}" if v.location else v.name,
                'lat': float(v.latitude) if v.latitude is not None else None,
                'lng': float(v.longitude) if v.longitude is not None else None,
                'is_venue': True,
            })

        # 2. Append OpenStreetMap / Google Maps place suggestions
        map_places = _search_places_api(q, limit=6)
        results.extend(map_places)
        return Response(results)

    @action(detail=False, methods=['get'], permission_classes=[permissions.AllowAny])
    def reverse_geocode(self, request):
        lat = request.query_params.get('lat')
        lng = request.query_params.get('lng')
        if not lat or not lng:
            return Response({'error': 'lat and lng are required'}, status=400)
        place_name = _reverse_geocode_coords(lat, lng)
        return Response({
            'location_name': place_name or f"{float(lat):.4f}, {float(lng):.4f}",
            'lat': float(lat),
            'lng': float(lng),
        })

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
        lat = serializer.validated_data.get('latitude')
        lng = serializer.validated_data.get('longitude')
        addr = (serializer.validated_data.get('address') or '').strip()
        extra = {'executive': self.request.user, 'status': 'PENDING_APPROVAL'}
        if lat is not None and lng is not None and (not addr or addr.startswith('Lat:')):
            resolved = _reverse_geocode_coords(lat, lng)
            if resolved:
                extra['address'] = resolved
        serializer.save(**extra)

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

            resolved_loc = (venue.address or '').strip()
            if venue.latitude is not None and venue.longitude is not None and (not resolved_loc or resolved_loc.startswith('Lat:')):
                geocoded_name = _reverse_geocode_coords(venue.latitude, venue.longitude)
                if geocoded_name:
                    resolved_loc = geocoded_name
                    venue.address = geocoded_name

            real_venue = Venue.objects.create(
                name=venue.name,
                location=resolved_loc,
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


