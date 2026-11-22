from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    BookingViewSet,
    VendorDashboardView,
    VendorBookingViewSet,
    PaymentIntentView,
    PaymentConfirmView,
    RazorpayWebhookView,
)

router = DefaultRouter()
from .views import BookingRentalItemViewSet

router.register(r'rental-items', BookingRentalItemViewSet, basename='booking-rental-item')
router.register(r'vendor-bookings', VendorBookingViewSet, basename='vendor-booking')
router.register(r'', BookingViewSet, basename='booking')

urlpatterns = [
    path('vendor-dashboard/', VendorDashboardView.as_view(), name='vendor-dashboard'),
    path('payments/create-intent/', PaymentIntentView.as_view(), name='payment_create_intent'),
    path('payments/create-order/', PaymentIntentView.as_view(), name='payment_create_order'),
    path('payments/confirm/', PaymentConfirmView.as_view(), name='payment_confirm'),
    path('payments/razorpay-webhook/', RazorpayWebhookView.as_view(), name='razorpay_webhook'),
    path('', include(router.urls)),
]
