import os
import django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "goathlete_backend.settings")
django.setup()

from django.contrib.auth.models import User
from venues.models import Venue, Court, CourtSlotPricing
from rest_framework.test import APIClient

# Create users
user1, _ = User.objects.get_or_create(username='user1', password='password')
user2, _ = User.objects.get_or_create(username='user2', password='password')

# Create venue for user1
v1, _ = Venue.objects.get_or_create(name='Venue 1', owner=user1)

# Create court for user1
c1, _ = Court.objects.get_or_create(venue=v1, name='Court 1', sport='Tennis')

# Client for user2
client = APIClient()
client.force_authenticate(user=user2)

# Try to update court
res = client.patch(f'/api/venues/courts/{c1.id}/', {'name': 'Hacked Court'})
print("PATCH court by user2:", res.status_code)

# Try to create court for user1's venue by user2
res = client.post('/api/venues/courts/', {'venue': v1.id, 'name': 'Court 2', 'sport': 'Tennis'})
print("POST court by user2:", res.status_code)

# Client for user1
client.force_authenticate(user=user1)
res = client.post('/api/venues/courts/', {'venue': v1.id, 'name': 'Court 2', 'sport': 'Tennis'})
print("POST court by user1:", res.status_code)
