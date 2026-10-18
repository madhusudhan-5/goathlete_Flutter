import os
import django
import random
from datetime import timedelta
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from django.contrib.auth.models import User
from users.models import UserProfile
from venues.models import Venue, PreRegisteredVenue, Sport, VenueSport, Amenity
from tournaments.models import Tournament, SportTemplate, Team, Match
from bookings.models import Booking

def run_seed():
    print("Starting data seed...")

    # 1. Create Executives
    for i in range(1, 4):
        username = f'exec_mock_{i}@goathlete.com'
        if not User.objects.filter(username=username).exists():
            u = User.objects.create_user(username=username, email=username, password='Test@12345')
            u.first_name = f'Field Exec {i}'
            u.save()
            p, _ = UserProfile.objects.get_or_create(user=u)
            p.role = 'EXECUTIVE'
            p.goath_id = f'GOATH-EX-M00{i}'
            p.phone_number = f'+91 90000 0000{i}'
            p.save()

    # 2. Ensure Sports exist
    football, _ = Sport.objects.get_or_create(name='Football', defaults={'icon_name': 'sports_soccer'})
    cricket, _ = Sport.objects.get_or_create(name='Cricket', defaults={'icon_name': 'sports_cricket'})
    badminton, _ = Sport.objects.get_or_create(name='Badminton', defaults={'icon_name': 'sports_tennis'})

    # Ensure SportTemplates exist
    fb_template, _ = SportTemplate.objects.get_or_create(name='Football', defaults={'min_players_per_team': 5, 'max_players_per_team': 11})
    cr_template, _ = SportTemplate.objects.get_or_create(name='Cricket', defaults={'min_players_per_team': 11, 'max_players_per_team': 15})

    # 3. Create PreRegistered Venues (KYC Pending)
    exec_user = User.objects.filter(profile__role='EXECUTIVE').first()
    if exec_user:
        for i in range(1, 4):
            phone = f'+91 80000 1111{i}'
            if not PreRegisteredVenue.objects.filter(phone_number=phone).exists():
                PreRegisteredVenue.objects.create(
                    name=f'Pending Turf {i}',
                    owner_name=f'Owner {i}',
                    phone_number=phone,
                    address=f'Mock Address {i}, Bangalore',
                    executive=exec_user,
                    status='PENDING_APPROVAL'
                )

    # 4. Create Approved Venues and Vendors
    for i in range(1, 4):
        username = f'vendor_mock_{i}@goathlete.com'
        if not User.objects.filter(username=username).exists():
            v_user = User.objects.create_user(username=username, email=username, password='Test@12345')
            v_user.first_name = f'Vendor {i}'
            v_user.save()
            p, _ = UserProfile.objects.get_or_create(user=v_user)
            p.role = 'VENDOR'
            p.phone_number = f'+91 70000 2222{i}'
            p.save()

            venue = Venue.objects.create(
                name=f'Active Premium Turf {i}',
                owner=v_user,
                description=f'This is a premium active turf {i}',
                latitude=12.9716 + (i * 0.01),
                longitude=77.5946 + (i * 0.01),
                location=f'Sector {i}, Bangalore',
                price_per_hour=1000.0 + (i * 100),
                rating=4.5 + (i * 0.1)
            )
            VenueSport.objects.create(venue=venue, sport=football)
            VenueSport.objects.create(venue=venue, sport=cricket)

            # 5. Create Bookings for this venue
            customer = User.objects.filter(profile__role='CUSTOMER').first()
            if customer:
                for b_i in range(3):
                    Booking.objects.create(
                        venue=venue,
                        user=customer,
                        date=timezone.now().date() + timedelta(days=b_i),
                        start_time=(timezone.now() + timedelta(hours=b_i)).time(),
                        end_time=(timezone.now() + timedelta(hours=b_i+1)).time(),
                        total_price=venue.price_per_hour,
                        status='confirmed'
                    )

    # 6. Create Tournaments
    customer_profile = UserProfile.objects.filter(role='CUSTOMER').first()
    venue = Venue.objects.first()
    if venue and customer_profile:
        for i in range(1, 4):
            if not Tournament.objects.filter(name=f'Mock Tournament {i}').exists():
                Tournament.objects.create(
                    name=f'Mock Tournament {i}',
                    sport_template=fb_template,
                    organizer=customer_profile,
                    location=venue.name,
                    start_date=timezone.now().date() + timedelta(days=i),
                    end_date=timezone.now().date() + timedelta(days=i+5),
                    status='Scheduled'
                )

    print("Seed complete!")

run_seed()
