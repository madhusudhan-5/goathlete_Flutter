from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'venues', views.VenueViewSet)
router.register(r'vendor-venues', views.VendorVenueViewSet, basename='vendor-venue')
router.register(r'pre-register-venues', views.PreRegisteredVenueViewSet, basename='pre-register-venue')
router.register(r'vendor-partners', views.VendorPartnerViewSet, basename='vendor-partner')
router.register(r'rental-items', views.RentalItemViewSet, basename='rental-item')

router.register(r'courts', views.CourtViewSet, basename='court')
router.register(r'court-slot-pricings', views.CourtSlotPricingViewSet, basename='court-slot-pricing')

urlpatterns = [
    path('', include(router.urls)),
]
