from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'venues', views.VenueViewSet)
router.register(r'vendor-venues', views.VendorVenueViewSet, basename='vendor-venue')
router.register(r'pre-register-venues', views.PreRegisteredVenueViewSet, basename='pre-register-venue')

urlpatterns = [
    path('', include(router.urls)),
]
