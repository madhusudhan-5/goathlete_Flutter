from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions
from .models import HighlightBanner, SportCategory, QuickAction
from .serializers import HighlightBannerSerializer, SportCategorySerializer, QuickActionSerializer

class DashboardConfigView(APIView):
    permission_classes = (permissions.AllowAny,)

    def get(self, request):
        banners = HighlightBanner.objects.filter(is_active=True)
        sports = SportCategory.objects.filter(is_active=True)
        actions = QuickAction.objects.filter(is_active=True)

        return Response({
            'banners': HighlightBannerSerializer(banners, many=True).data,
            'sports': SportCategorySerializer(sports, many=True).data,
            'quick_actions': QuickActionSerializer(actions, many=True).data,
        })

from venues.models import Venue, PreRegisteredVenue
from bookings.models import Booking
from django.contrib.auth.models import User
from django.db.models import Sum

class AdminAnalyticsView(APIView):
    # For a real app, restrict this to IsAdminUser or custom IsSuperAdmin permission
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        total_revenue = Booking.objects.filter(status='confirmed').aggregate(Sum('total_price'))['total_price__sum'] or 0
        total_venues = Venue.objects.count()
        total_executives = User.objects.filter(profile__role='EXECUTIVE').count()
        pending_kyc = PreRegisteredVenue.objects.filter(status='DRAFT').count() + PreRegisteredVenue.objects.filter(status='PENDING_APPROVAL').count()

        return Response({
            'total_revenue': total_revenue,
            'total_venues': total_venues,
            'total_executives': total_executives,
            'pending_kyc': pending_kyc,
        })

from rest_framework import viewsets
from .models import GlobalConfig, PromotionalOffer
from .serializers import GlobalConfigSerializer, PromotionalOfferSerializer

class GlobalConfigViewSet(viewsets.ModelViewSet):
    """
    API endpoint for Super Admins to manage global configs.
    """
    queryset = GlobalConfig.objects.all()
    serializer_class = GlobalConfigSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        # Always return the first/only object
        obj, created = GlobalConfig.objects.get_or_create(id=1)
        return obj

class PromotionalOfferViewSet(viewsets.ModelViewSet):
    """
    API endpoint for Super Admins to manage offers.
    """
    queryset = PromotionalOffer.objects.all()
    serializer_class = PromotionalOfferSerializer
    permission_classes = [permissions.IsAuthenticated]
