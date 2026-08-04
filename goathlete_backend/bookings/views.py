from rest_framework import viewsets, permissions, status
from .models import Booking, Payment
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

from venues.models import Venue
import uuid

class PaymentIntentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        venue_id = request.data.get('venue_id')
        date_str = request.data.get('date')
        start_time_str = request.data.get('start_time')
        end_time_str = request.data.get('end_time')

        try:
            venue = Venue.objects.get(id=venue_id)
            booking_date = datetime.strptime(date_str, '%Y-%m-%d').date()
            start_time = datetime.strptime(start_time_str, '%H:%M:%S').time()
            end_time = datetime.strptime(end_time_str, '%H:%M:%S').time()

            # Calculate duration in hours
            duration_delta = datetime.combine(booking_date, end_time) - datetime.combine(booking_date, start_time)
            duration_hours = duration_delta.total_seconds() / 3600.0
            total_price = venue.price_per_hour * type(venue.price_per_hour)(duration_hours)

            # Create pending booking
            booking = Booking.objects.create(
                user=request.user,
                venue=venue,
                date=booking_date,
                start_time=start_time,
                end_time=end_time,
                total_price=total_price,
                status='pending'
            )

            # Create pending payment
            payment = Payment.objects.create(
                booking=booking,
                amount=total_price,
                currency='INR',
                provider='MOCK',
                status='pending'
            )

            # Mock client secret for MVP
            client_secret = f"mock_secret_{uuid.uuid4()}"

            return Response({
                'payment_id': payment.id,
                'clientSecret': client_secret,
                'amount': total_price,
            })
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

class PaymentConfirmView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        payment_id = request.data.get('payment_id')
        transaction_id = request.data.get('transaction_id')

        try:
            payment = Payment.objects.get(id=payment_id, booking__user=request.user)
            
            # Mock success behavior
            payment.status = 'completed'
            payment.transaction_id = transaction_id
            payment.save()

            booking = payment.booking
            booking.status = 'confirmed'
            booking.save()

            return Response({'status': 'success', 'message': 'Payment confirmed and booking finalized.'})
        except Payment.DoesNotExist:
            return Response({'error': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
