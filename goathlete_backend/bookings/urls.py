from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import BookingViewSet, VendorDashboardView, VendorBookingViewSet, PaymentIntentView, PaymentConfirmView

router = DefaultRouter()
router.register(r'vendor-bookings', VendorBookingViewSet, basename='vendor-booking')
router.register(r'', BookingViewSet, basename='booking')

urlpatterns = [
    path('vendor-dashboard/', VendorDashboardView.as_view(), name='vendor-dashboard'),
    path('payments/create-intent/', PaymentIntentView.as_view(), name='payment_create_intent'),
    path('payments/confirm/', PaymentConfirmView.as_view(), name='payment_confirm'),
    path('', include(router.urls)),
]
