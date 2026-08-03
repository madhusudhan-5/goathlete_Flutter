from rest_framework import serializers
from .models import Booking
from datetime import datetime, date

class BookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = '__all__'
        read_only_fields = ('user', 'total_price', 'status', 'created_at', 'updated_at')

    def validate(self, data):
        """
        Check that start_time is before end_time and handle conflict checks.
        """
        if data['start_time'] >= data['end_time']:
            raise serializers.ValidationError({"end_time": "End time must be after start time."})
            
        # Basic check for past dates
        if data['date'] < date.today():
            raise serializers.ValidationError({"date": "Cannot book in the past."})

        # Basic conflict check
        conflicting_bookings = Booking.objects.filter(
            venue=data['venue'],
            date=data['date'],
            status__in=['pending', 'confirmed']
        ).exclude(
            end_time__lte=data['start_time']
        ).exclude(
            start_time__gte=data['end_time']
        )
        
        if conflicting_bookings.exists():
            raise serializers.ValidationError("This venue is already booked for the specified time slot.")

        return data
