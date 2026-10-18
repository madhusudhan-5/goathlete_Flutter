import re

with open("venues/views.py", "r") as f:
    content = f.read()

# Fix 1: nulls_last in distance sort
content = content.replace(
    "queryset = queryset.annotate(computed_distance=distance_expr).order_by('computed_distance', '-rating')",
    "queryset = queryset.annotate(computed_distance=distance_expr).order_by(F('computed_distance').asc(nulls_last=True), '-rating')"
)

# Fix 2: VendorVenueViewSet.create to create PreRegisteredVenue instead of Venue
old_vendor_create = """    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)"""

new_vendor_create = """    def create(self, request, *args, **kwargs):
        data = request.data
        user = request.user
        from .models import PreRegisteredVenue
        prereg = PreRegisteredVenue.objects.create(
            executive=user,
            name=data.get('name', ''),
            owner_name=user.first_name or user.username,
            phone_number=getattr(user.profile, 'phone_number', '') if hasattr(user, 'profile') else '',
            email=user.email,
            address=data.get('location', ''),
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
            status='PENDING_APPROVAL'
        )
        return Response({'message': 'Venue submitted for KYC approval.', 'id': prereg.id}, status=201)"""

content = content.replace(old_vendor_create, new_vendor_create)

with open("venues/views.py", "w") as f:
    f.write(content)
print("Patched venues/views.py successfully.")
