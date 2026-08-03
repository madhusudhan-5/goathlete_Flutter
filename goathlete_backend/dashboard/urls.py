from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DashboardConfigView, AdminAnalyticsView, GlobalConfigViewSet, PromotionalOfferViewSet

router = DefaultRouter()
router.register(r'global-config', GlobalConfigViewSet, basename='global-config')
router.register(r'promotional-offers', PromotionalOfferViewSet, basename='promotional-offer')

urlpatterns = [
    path('config/', DashboardConfigView.as_view(), name='dashboard-config'),
    path('admin-analytics/', AdminAnalyticsView.as_view(), name='admin-analytics'),
    path('', include(router.urls)),
]
