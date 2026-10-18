import os
import django
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from django.apps import apps
if not apps.ready:
    django.setup()

from django.contrib.auth.models import User
from venues.models import PreRegisteredVenue, Venue
from users.models import UserProfile
from rest_framework.test import APIClient

def test_venue_approval():
    client = APIClient()
    
    # Create an executive to make requests
    executive, _ = User.objects.get_or_create(username="exec1", email="exec1@example.com")
    # Make sure we don't accidentally get an auth error if not logged in
    client.force_authenticate(user=executive)

    # 1. Existing user without requires_password_change
    user1, _ = User.objects.get_or_create(username="8888888888")
    user1.set_password("myownpassword")
    user1.save()
    profile1 = user1.profile
    profile1.requires_password_change = False
    profile1.role = 'CUSTOMER'
    profile1.save()

    prereg1 = PreRegisteredVenue.objects.create(
        executive=executive,
        name="Test Venue 1",
        owner_name="Test Owner 1",
        phone_number="8888888888",
        address="123 Test St",
        latitude=1.0,
        longitude=1.0,
        status='PENDING_APPROVAL'
    )

    response = client.post(f'/api/venues/pre-register-venues/{prereg1.id}/approve/')
    print(f"Approve 1 response: {response.status_code}")
    
    user1.refresh_from_db()
    profile1.refresh_from_db()
    print(f"User 1 role: {profile1.role}")
    print(f"User 1 requires_password_change: {profile1.requires_password_change}")
    
    # 2. New user
    prereg2 = PreRegisteredVenue.objects.create(
        executive=executive,
        name="Test Venue 2",
        owner_name="Test Owner 2",
        phone_number="9999999999",
        address="456 Test St",
        latitude=2.0,
        longitude=2.0,
        status='PENDING_APPROVAL'
    )
    
    response = client.post(f'/api/venues/pre-register-venues/{prereg2.id}/approve/')
    print(f"Approve 2 response: {response.status_code}")
    
    user2 = User.objects.get(username="9999999999")
    profile2 = user2.profile
    print(f"User 2 role: {profile2.role}")
    print(f"User 2 requires_password_change: {profile2.requires_password_change}")
    
if __name__ == '__main__':
    test_venue_approval()
