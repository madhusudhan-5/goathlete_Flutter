from rest_framework import viewsets, permissions
from .models import Venue, PreRegisteredVenue
from .serializers import VenueSerializer, PreRegisteredVenueSerializer

class VenueViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows venues to be viewed.
    """
    queryset = Venue.objects.all().order_by('-rating')
    serializer_class = VenueSerializer

class PreRegisteredVenueViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows executives to pre-register venues.
    """
    serializer_class = PreRegisteredVenueSerializer

    def get_queryset(self):
        # Executives only see their own venues. Admin sees all.
        user = self.request.user
        if not user.is_authenticated:
            return PreRegisteredVenue.objects.none()
        if getattr(user, 'profile', None) and user.profile.role == 'SUPER_ADMIN':
            return PreRegisteredVenue.objects.all()
        return PreRegisteredVenue.objects.filter(executive=user)

    def perform_create(self, serializer):
        serializer.save(executive=self.request.user)

    from rest_framework.decorators import action
    from rest_framework.response import Response

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        venue = self.get_object()
        venue.status = 'APPROVED'
        venue.save()
        # Optionally, create a real Venue here
        return Response({'status': 'venue approved'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def reject(self, request, pk=None):
        venue = self.get_object()
        venue.status = 'REJECTED'
        venue.save()
        return Response({'status': 'venue rejected'})

from rest_framework import permissions

class VendorVenueViewSet(viewsets.ModelViewSet):
    """
    API endpoint for vendors to edit their owned venues.
    """
    serializer_class = VenueSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return Venue.objects.none()
        return Venue.objects.filter(owner=user)

