from rest_framework import serializers
from .models import Venue, Sport, VenueSport, Amenity, PreRegisteredVenue

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
    
    class Meta:
        model = Venue
        fields = [
            'id', 'name', 'description', 'location', 'distance', 
            'latitude', 'longitude', 'rating', 'reviews_count', 
            'image_url', 'price_per_hour', 'sports', 'amenities', 
            'owner', 'owner_details'
        ]

    def get_owner_details(self, obj):
        if obj.owner:
            return {
                'id': obj.owner.id,
                'name': obj.owner.first_name or obj.owner.username,
                'phone': obj.owner.profile.phone_number if hasattr(obj.owner, 'profile') else None,
            }
        return None

class PreRegisteredVenueSerializer(serializers.ModelSerializer):
    class Meta:
        model = PreRegisteredVenue
        fields = '__all__'
        read_only_fields = ['executive', 'status']

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
