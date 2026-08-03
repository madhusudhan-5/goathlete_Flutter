from rest_framework import viewsets, permissions
from .models import Booking
from .serializers import BookingSerializer
from datetime import datetime, date

class BookingViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows bookings to be viewed or edited.
    """
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        This view should return a list of all the bookings
        for the currently authenticated user.
        """
        user = self.request.user
        return Booking.objects.filter(user=user).order_by('-date', '-start_time')

    def perform_create(self, serializer):
        """
        Calculate total price and attach user to the booking before saving.
        """
        venue = serializer.validated_data['venue']
        start_time = serializer.validated_data['start_time']
        end_time = serializer.validated_data['end_time']
        
        # Calculate duration in hours
        duration_delta = datetime.combine(date.today(), end_time) - datetime.combine(date.today(), start_time)
        duration_hours = duration_delta.total_seconds() / 3600.0
        
        # Calculate total price
        total_price = venue.price_per_hour * type(venue.price_per_hour)(duration_hours)
        
        serializer.save(user=self.request.user, total_price=total_price)

from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Sum

class VendorDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        # Find all venues owned by this user
        owned_venues = user.owned_venues.all()
        if not owned_venues.exists():
            return Response({"total_revenue": 0, "total_bookings": 0, "upcoming_bookings": []})
        
        # Get bookings for these venues
        bookings = Booking.objects.filter(venue__in=owned_venues)
        total_revenue = bookings.filter(status='confirmed').aggregate(Sum('total_price'))['total_price__sum'] or 0
        total_bookings = bookings.count()
        
        upcoming = bookings.filter(date__gte=date.today()).order_by('date', 'start_time')[:5]
        upcoming_data = BookingSerializer(upcoming, many=True).data
        
        return Response({
            "total_revenue": total_revenue,
            "total_bookings": total_bookings,
            "upcoming_bookings": upcoming_data
        })

class VendorBookingViewSet(viewsets.ModelViewSet):
    """
    API endpoint for vendors to manage bookings for their venues (e.g. manual walk-ins, blocking slots)
    """
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Booking.objects.filter(venue__in=user.owned_venues.all()).order_by('-date', '-start_time')

    def perform_create(self, serializer):
        # A vendor creates a booking (e.g. walk-in). The user is the vendor themselves.
        # Ensure they own the venue.
        venue = serializer.validated_data['venue']
        if venue.owner != self.request.user:
            raise permissions.exceptions.PermissionDenied("You don't own this venue.")
        
        start_time = serializer.validated_data['start_time']
        end_time = serializer.validated_data['end_time']
        duration_delta = datetime.combine(date.today(), end_time) - datetime.combine(date.today(), start_time)
        duration_hours = duration_delta.total_seconds() / 3600.0
        total_price = venue.price_per_hour * type(venue.price_per_hour)(duration_hours)
        
        serializer.save(user=self.request.user, total_price=total_price, status='confirmed')

