import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from django.contrib.auth.models import User
from users.models import UserProfile, OTP
from venues.models import Venue, Sport, VenueSport, Amenity, PreRegisteredVenue
from bookings.models import Booking, Payment
from tournaments.models import (
    SportTemplate, SportEvent, Tournament, Team,
    TournamentPlayer, Match, MatchEvent, PlayerStat
)
from dashboard.models import HighlightBanner, SportCategory, QuickAction, GlobalConfig, PromotionalOffer
from seed_sport_configs import seed_database as seed_sport_configs
from seed_dashboard import seed_dashboard


def clean_database():
    print("==================================================")
    print("  GoAthlete Backend - Cleaning Dummy Data")
    print("==================================================")
    
    # 1. Delete all tournament and match transactional records
    print("[1/5] Removing all match events, player stats, matches, teams, tournaments...")
    PlayerStat.objects.all().delete()
    MatchEvent.objects.all().delete()
    Match.objects.all().delete()
    TournamentPlayer.objects.all().delete()
    Team.objects.all().delete()
    Tournament.objects.all().delete()

    # 2. Delete all bookings and payments
    print("[2/5] Removing bookings, payments, and venue registrations...")
    Payment.objects.all().delete()
    Booking.objects.all().delete()
    PreRegisteredVenue.objects.all().delete()
    VenueSport.objects.all().delete()
    Amenity.objects.all().delete()
    Venue.objects.all().delete()

    # 3. Delete all users, profiles, and OTPs
    print("[3/5] Removing all dummy users, profiles, and OTP tokens...")
    OTP.objects.all().delete()
    UserProfile.objects.all().delete()
    User.objects.all().delete()

    # 4. Verify/Re-seed Master Sport Templates & Scoring Matrix
    print("[4/5] Initializing Master Sport Rules & Events Matrix...")
    seed_sport_configs()

    # 5. Verify/Re-seed Master Dashboard Configurations & Venue Sports
    print("[5/5] Initializing Master Dashboard & Sport Categories...")
    seed_dashboard()
    
    # Ensure venue sports catalog is populated
    venue_sports = [
        ('Football', 'sports_soccer'),
        ('Cricket', 'sports_cricket'),
        ('Badminton', 'sports_tennis'),
        ('Basketball', 'sports_basketball'),
        ('Tennis', 'sports_baseball'),
    ]
    for name, icon in venue_sports:
        Sport.objects.get_or_create(name=name, defaults={'icon_name': icon})

    # Ensure GlobalConfig exists
    GlobalConfig.objects.get_or_create(id=1)

    print("\n---------------- Database Status ----------------")
    print(f"Users:               {User.objects.count()} (Clean slate for fresh registration)")
    print(f"UserProfiles:        {UserProfile.objects.count()}")
    print(f"OTPs:                {OTP.objects.count()}")
    print(f"Venues:              {Venue.objects.count()}")
    print(f"PreRegisteredVenues: {PreRegisteredVenue.objects.count()}")
    print(f"Bookings:            {Booking.objects.count()}")
    print(f"Tournaments:         {Tournament.objects.count()}")
    print(f"Teams:               {Team.objects.count()}")
    print(f"Matches:             {Match.objects.count()}")
    print(f"SportTemplates:      {SportTemplate.objects.count()} (Master configurations active)")
    print(f"SportEvents:         {SportEvent.objects.count()} (Scoring events matrix active)")
    print(f"SportCategories:     {SportCategory.objects.count()}")
    print(f"QuickActions:        {QuickAction.objects.count()}")
    print(f"HighlightBanners:    {HighlightBanner.objects.count()}")
    print("==================================================")
    print("All dummy data successfully purged! Ready for fresh registrations.")
    print("==================================================")

if __name__ == '__main__':
    clean_database()
