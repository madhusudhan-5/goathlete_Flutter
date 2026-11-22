from rest_framework import serializers
from .models import Venue, Sport, VenueSport, Amenity, PreRegisteredVenue, VenueImage

class SportSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sport
        fields = ['id', 'name', 'icon_name']

class VenueSportSerializer(serializers.ModelSerializer):
    sport = SportSerializer(read_only=True)
    
    class Meta:
        model = VenueSport
        fields = ['sport']

class AmenitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Amenity
        fields = ['id', 'name', 'icon_name']

class VenueSerializer(serializers.ModelSerializer):
    sports = VenueSportSerializer(many=True, read_only=True)
    amenities = AmenitySerializer(many=True, read_only=True)
    owner_details = serializers.SerializerMethodField(read_only=True)
    distance = serializers.SerializerMethodField(read_only=True)
    images = serializers.SerializerMethodField(read_only=True)
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)
    rating = serializers.FloatField(required=False, default=0.0)
    price_per_hour = serializers.FloatField(required=False, default=0.0)
    
    class Meta:
        model = Venue
        fields = [
            'id', 'name', 'description', 'location', 'distance', 
            'latitude', 'longitude', 'rating', 'reviews_count', 
            'image_url', 'images', 'price_per_hour', 'ground_type',
            'license_number', 'sports_prices', 'sports', 'amenities', 
            'owner', 'owner_details'
        ]

    def get_images(self, obj):
        request = self.context.get('request')
        urls = []
        for img in obj.images.all():
            if img.image:
                url = img.image.url
                if request is not None:
                    url = request.build_absolute_uri(url)
                urls.append(url)
        if not urls and obj.image_url:
            url = obj.image_url
            if request is not None and url.startswith('/'):
                url = request.build_absolute_uri(url)
            urls.append(url)
        return urls

    def get_distance(self, obj):
        if obj.latitude is not None and obj.longitude is not None:
            request = self.context.get('request')
            lat = None
            lng = None
            if self.context.get('search_lat') is not None and self.context.get('search_lng') is not None:
                lat = self.context.get('search_lat')
                lng = self.context.get('search_lng')
            elif request:
                lat = request.query_params.get('lat')
                lng = request.query_params.get('lng')
            if lat is not None and lng is not None:
                try:
                    import math
                    lat1, lon1 = float(lat), float(lng)
                    lat2, lon2 = float(obj.latitude), float(obj.longitude)
                    r = 6371.0
                    dlat = math.radians(lat2 - lat1)
                    dlon = math.radians(lon2 - lon1)
                    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
                    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
                    km = r * c
                    if km < 1.0:
                        return f"{int(round(km * 1000))} m away"
                    return f"{km:.1f} km away"
                except Exception:
                    pass
        return obj.distance or ""

    def get_owner_details(self, obj):
        if obj.owner:
            return {
                'id': obj.owner.id,
                'name': obj.owner.first_name or obj.owner.username,
                'phone': obj.owner.profile.phone_number if hasattr(obj.owner, 'profile') else None,
            }
        return None

class PreRegisteredVenueSerializer(serializers.ModelSerializer):
    images = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = PreRegisteredVenue
        fields = '__all__'
        read_only_fields = ['executive', 'status']

    def get_images(self, obj):
        request = self.context.get('request')
        urls = []
        for img in obj.images.all():
            if img.image:
                url = img.image.url
                if request is not None:
                    url = request.build_absolute_uri(url)
                urls.append(url)
        return urls

from .models import VendorPartner, RentalItem

class VendorPartnerSerializer(serializers.ModelSerializer):
    class Meta:
        model = VendorPartner
        fields = '__all__'

class RentalItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = RentalItem
        fields = '__all__'

from .models import Court, CourtSlotPricing

class CourtSlotPricingSerializer(serializers.ModelSerializer):
    class Meta:
        model = CourtSlotPricing
        fields = '__all__'

class CourtSerializer(serializers.ModelSerializer):
    slot_pricings = CourtSlotPricingSerializer(many=True, read_only=True)
    class Meta:
        model = Court
        fields = '__all__'
