import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "goathlete_backend.settings")
django.setup()

from venues.models import PreRegisteredVenue
from venues.serializers import PreRegisteredVenueSerializer
from django.contrib.auth.models import User

user, _ = User.objects.get_or_create(username='exec_user')

data = {
    'name': 'Test Venue',
    'owner_name': 'Test Owner',
    'phone_number': '1234567890',
}

serializer = PreRegisteredVenueSerializer(data=data)
assert serializer.is_valid(), serializer.errors

# Prior worker added status='PENDING_APPROVAL' here
serializer.save(executive=user, status='PENDING_APPROVAL')

venue = PreRegisteredVenue.objects.last()
print("Saved venue status:", venue.status)
