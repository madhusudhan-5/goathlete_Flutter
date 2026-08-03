from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import BookingViewSet, VendorDashboardView, VendorBookingViewSet

router = DefaultRouter()
router.register(r'vendor-bookings', VendorBookingViewSet, basename='vendor-booking')
router.register(r'', BookingViewSet, basename='booking')

urlpatterns = [
    path('vendor-dashboard/', VendorDashboardView.as_view(), name='vendor-dashboard'),
    path('', include(router.urls)),
]
