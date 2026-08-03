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
    
    class Meta:
        model = Venue
        fields = [
            'id', 'name', 'description', 'location', 'distance', 
            'rating', 'reviews_count', 'image_url', 'price_per_hour',
            'sports', 'amenities'
        ]

class PreRegisteredVenueSerializer(serializers.ModelSerializer):
    class Meta:
        model = PreRegisteredVenue
        fields = '__all__'
        read_only_fields = ['executive', 'status']

