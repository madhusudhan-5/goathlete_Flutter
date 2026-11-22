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

from decimal import Decimal
import json
import uuid

from django.conf import settings
from venues.models import Venue
from .razorpay_service import (
    RazorpayError,
    create_razorpay_order,
    is_razorpay_configured,
    verify_payment_signature,
    verify_webhook_signature,
)


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

            duration_delta = datetime.combine(booking_date, end_time) - datetime.combine(booking_date, start_time)
            duration_hours = Decimal(str(duration_delta.total_seconds() / 3600.0))
            if duration_hours <= 0:
                return Response({'error': 'End time must be after start time.'}, status=status.HTTP_400_BAD_REQUEST)

            base_price = (venue.price_per_hour * duration_hours).quantize(Decimal('0.01'))
            platform_fee = Decimal('20.00')
            gst = (base_price * Decimal('0.18')).quantize(Decimal('0.01'))
            total_price = (base_price + platform_fee + gst).quantize(Decimal('0.01'))
            amount_paise = int((total_price * Decimal('100')).quantize(Decimal('1')))

            profile = getattr(request.user, 'profile', None)
            prefill = {
                'name': request.user.get_full_name() or request.user.first_name or request.user.username,
                'email': request.user.email or '',
                'contact': getattr(profile, 'phone_number', '') or '',
            }

            if is_razorpay_configured():
                booking = Booking.objects.create(
                    user=request.user,
                    venue=venue,
                    date=booking_date,
                    start_time=start_time,
                    end_time=end_time,
                    total_price=total_price,
                    status='pending',
                )
                try:
                    order = create_razorpay_order(
                        amount_paise=amount_paise,
                        receipt=f'goath_booking_{booking.id}',
                        currency='INR',
                        notes={
                            'booking_id': str(booking.id),
                            'venue_id': str(venue.id),
                            'user_id': str(request.user.id),
                        },
                    )
                except RazorpayError as rzp_err:
                    booking.delete()
                    return Response({'error': str(rzp_err)}, status=status.HTTP_502_BAD_GATEWAY)

                payment = Payment.objects.create(
                    booking=booking,
                    amount=total_price,
                    currency='INR',
                    provider='RAZORPAY',
                    razorpay_order_id=order['id'],
                    status='pending',
                )

                return Response({
                    'provider': 'RAZORPAY',
                    'payment_id': payment.id,
                    'booking_id': booking.id,
                    'order_id': order['id'],
                    'key_id': settings.RAZORPAY_KEY_ID.strip(),
                    'amount': str(total_price),
                    'amount_paise': amount_paise,
                    'currency': 'INR',
                    'venue_name': venue.name,
                    'prefill': prefill,
                })

            if not settings.DEBUG:
                return Response(
                    {'error': 'Razorpay is not configured on the server.'},
                    status=status.HTTP_503_SERVICE_UNAVAILABLE,
                )

            # Local DEBUG fallback when Razorpay keys are not set yet
            booking = Booking.objects.create(
                user=request.user,
                venue=venue,
                date=booking_date,
                start_time=start_time,
                end_time=end_time,
                total_price=total_price,
                status='pending',
            )
            payment = Payment.objects.create(
                booking=booking,
                amount=total_price,
                currency='INR',
                provider='MOCK',
                status='pending',
            )
            return Response({
                'provider': 'MOCK',
                'payment_id': payment.id,
                'booking_id': booking.id,
                'clientSecret': f"mock_secret_{uuid.uuid4()}",
                'amount': str(total_price),
                'amount_paise': amount_paise,
                'currency': 'INR',
                'venue_name': venue.name,
                'prefill': prefill,
            })
        except Venue.DoesNotExist:
            return Response({'error': 'Venue not found.'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PaymentConfirmView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        payment_id = request.data.get('payment_id')
        razorpay_order_id = (request.data.get('razorpay_order_id') or '').strip()
        razorpay_payment_id = (request.data.get('razorpay_payment_id') or '').strip()
        razorpay_signature = (request.data.get('razorpay_signature') or '').strip()
        transaction_id = (request.data.get('transaction_id') or '').strip()

        try:
            payment = Payment.objects.select_related('booking').get(id=payment_id, booking__user=request.user)

            if payment.status == 'completed':
                return Response({
                    'status': 'success',
                    'message': 'Payment already confirmed.',
                    'booking_id': payment.booking_id,
                })

            if payment.provider == 'RAZORPAY':
                if not (razorpay_order_id and razorpay_payment_id and razorpay_signature):
                    return Response(
                        {'error': 'Missing Razorpay payment verification parameters.'},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                if payment.razorpay_order_id and payment.razorpay_order_id != razorpay_order_id:
                    return Response(
                        {'error': 'Razorpay order ID mismatch.'},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                if not verify_payment_signature(razorpay_order_id, razorpay_payment_id, razorpay_signature):
                    payment.status = 'failed'
                    payment.save(update_fields=['status', 'updated_at'])
                    return Response(
                        {'error': 'Invalid Razorpay payment signature.'},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                payment.transaction_id = razorpay_payment_id
                payment.razorpay_signature = razorpay_signature
                payment.status = 'completed'
                payment.save(update_fields=['transaction_id', 'razorpay_signature', 'status', 'updated_at'])
            else:
                if not settings.DEBUG:
                    return Response(
                        {'error': 'Mock payments are disabled in production.'},
                        status=status.HTTP_403_FORBIDDEN,
                    )
                payment.status = 'completed'
                payment.transaction_id = transaction_id or f"mock_txn_{uuid.uuid4().hex[:12]}"
                payment.save(update_fields=['transaction_id', 'status', 'updated_at'])

            booking = payment.booking
            booking.status = 'confirmed'
            booking.save(update_fields=['status', 'updated_at'])

            return Response({
                'status': 'success',
                'message': 'Payment confirmed and booking finalized.',
                'booking_id': booking.id,
                'transaction_id': payment.transaction_id,
            })
        except Payment.DoesNotExist:
            return Response({'error': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class RazorpayWebhookView(APIView):
    """Server-to-server webhook for payment.captured, order.paid, and payment.failed."""
    permission_classes = (permissions.AllowAny,)
    authentication_classes = ()

    def post(self, request):
        received_sig = request.META.get('HTTP_X_RAZORPAY_SIGNATURE', '')
        raw_body = request.body

        if not verify_webhook_signature(raw_body, received_sig):
            return Response({'error': 'Invalid webhook signature.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            payload = json.loads(raw_body.decode('utf-8'))
        except Exception:
            return Response({'error': 'Invalid JSON payload.'}, status=status.HTTP_400_BAD_REQUEST)

        event = payload.get('event', '')
        payment_entity = payload.get('payload', {}).get('payment', {}).get('entity', {})
        order_id = payment_entity.get('order_id') or payload.get('payload', {}).get('order', {}).get('entity', {}).get('id')
        razorpay_payment_id = payment_entity.get('id')

        if not order_id:
            return Response({'status': 'ignored'}, status=status.HTTP_200_OK)

        payment = Payment.objects.select_related('booking').filter(razorpay_order_id=order_id).first()
        if not payment:
            return Response({'status': 'ignored'}, status=status.HTTP_200_OK)

        if event in ('payment.captured', 'order.paid'):
            if payment.status != 'completed':
                payment.status = 'completed'
                if razorpay_payment_id and not payment.transaction_id:
                    payment.transaction_id = razorpay_payment_id
                payment.save(update_fields=['status', 'transaction_id', 'updated_at'])
            if payment.booking.status != 'confirmed':
                payment.booking.status = 'confirmed'
                payment.booking.save(update_fields=['status', 'updated_at'])
        elif event == 'payment.failed':
            if payment.status == 'pending':
                payment.status = 'failed'
                payment.save(update_fields=['status', 'updated_at'])

        return Response({'status': 'ok'}, status=status.HTTP_200_OK)

from .models import BookingRentalItem
from .serializers import BookingRentalItemSerializer

class BookingRentalItemViewSet(viewsets.ModelViewSet):
    serializer_class = BookingRentalItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        from django.db import models
        return BookingRentalItem.objects.filter(models.Q(booking__user=user) | models.Q(booking__venue__owner=user)).distinct()

    from rest_framework.decorators import action
    from rest_framework.response import Response

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def approve(self, request, pk=None):
        item = self.get_object()
        if request.user != item.booking.venue.owner:
            return Response({'error': 'Not authorized'}, status=403)
        item.is_approved = True
        item.save()
        return Response({'status': 'approved'})
