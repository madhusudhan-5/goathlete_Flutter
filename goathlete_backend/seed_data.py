import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from venues.models import Venue, Sport, VenueSport, Amenity
from tournaments.models import SportTemplate
from django.contrib.auth.models import User
from users.models import UserProfile
import random

def seed():
    # Clear existing
    User.objects.all().delete() # This cascades and deletes UserProfiles, Tournaments, Teams, Bookings etc.
    Venue.objects.all().delete()
    Sport.objects.all().delete()
    SportTemplate.objects.all().delete()

    football = Sport.objects.create(name='Football', icon_name='sports_soccer')
    cricket = Sport.objects.create(name='Cricket', icon_name='sports_cricket')
    badminton = Sport.objects.create(name='Badminton', icon_name='sports_tennis')
    basketball = Sport.objects.create(name='Basketball', icon_name='sports_basketball')

    # Seed Sport Templates for tournaments
    SportTemplate.objects.all().delete()
    SportTemplate.objects.create(name='Cricket', min_players_per_team=11, max_players_per_team=15)
    SportTemplate.objects.create(name='Football', min_players_per_team=5, max_players_per_team=11)
    SportTemplate.objects.create(name='Badminton', min_players_per_team=1, max_players_per_team=2)
    SportTemplate.objects.create(name='Basketball', min_players_per_team=5, max_players_per_team=10)

    # Create Venue 1
    venue1 = Venue.objects.create(
        name='Smash It Turf',
        description='Smash It Turf offers premium artificial grass for 5v5 and 7v7 football and box cricket. Equipped with high-quality LED floodlights and excellent facilities.',
        location='1.2 km away • HSR Layout, Bangalore',
        distance='1.2 km away',
        rating=4.8,
        reviews_count=120,
        image_url='https://images.unsplash.com/photo-1574629810360-7efbb2639446?auto=format&fit=crop&w=1000&q=80',
        price_per_hour=800.00
    )
    
    VenueSport.objects.create(venue=venue1, sport=football)
    VenueSport.objects.create(venue=venue1, sport=cricket)

    Amenity.objects.create(venue=venue1, name='Parking', icon_name='local_parking')
    Amenity.objects.create(venue=venue1, name='Washrooms', icon_name='wc')
    Amenity.objects.create(venue=venue1, name='Drinking Water', icon_name='local_drink')
    Amenity.objects.create(venue=venue1, name='First Aid', icon_name='medical_services')

    # Seed Users
    # 1. Super Admin
    super_admin_user = User.objects.create_superuser('superadmin', 'superadmin@goathlete.com', 'admin123')
    super_admin_profile, _ = UserProfile.objects.get_or_create(user=super_admin_user)
    super_admin_profile.role = 'SUPER_ADMIN'
    super_admin_profile.phone_number = '9999999999'
    super_admin_profile.save()

    # 2. Executive Admins (3)
    for i in range(1, 4):
        exec_user = User.objects.create_user(f'executive{i}', f'exec{i}@goathlete.com', 'admin123')
        exec_profile, _ = UserProfile.objects.get_or_create(user=exec_user)
        exec_profile.role = 'EXECUTIVE'
        exec_profile.phone_number = f'888888888{i}'
        exec_profile.save()

    # 3. Customers (10)
    for i in range(1, 11):
        cust_user = User.objects.create_user(f'player{i}', f'player{i}@goathlete.com', 'password123')
        cust_user.first_name = f'Player'
        cust_user.last_name = f'{i}'
        cust_user.save()
        cust_profile, _ = UserProfile.objects.get_or_create(user=cust_user)
        cust_profile.role = 'CUSTOMER'
        cust_profile.phone_number = f'77777777{i:02d}'
        
        # Give them random sports and skills
        sports = ['Cricket', 'Football', 'Badminton', 'Basketball']
        skills = ['Beginner', 'Intermediate', 'Advanced', 'Professional']
        cust_profile.primary_sport = random.choice(sports)
        cust_profile.skill_level = random.choice(skills)
        cust_profile.bio = f"I am a passionate {cust_profile.primary_sport} player. Ready to join a tribe!"
        cust_profile.save()

    print("Successfully seeded the database with Super Admin, Executives, and 10 Customers!")

if __name__ == '__main__':
    seed()
