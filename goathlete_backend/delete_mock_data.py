import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from django.contrib.auth.models import User
from venues.models import PreRegisteredVenue, Venue
from tournaments.models import Tournament
from bookings.models import Booking

def cleanup():
    # Delete mock executives and vendors
    User.objects.filter(username__contains='_mock_').delete()
    
    # Delete mock pre-registered venues
    PreRegisteredVenue.objects.filter(name__contains='Pending Turf').delete()
    
    # Delete mock active venues
    Venue.objects.filter(name__contains='Active Premium Turf').delete()
    
    # Delete mock tournaments
    Tournament.objects.filter(name__contains='Mock Tournament').delete()

    print("Cleaned up all mock data!")

cleanup()
