import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from venues.models import Venue, Sport, VenueSport, Amenity

def seed():
    # Clear existing
    Venue.objects.all().delete()
    Sport.objects.all().delete()

    # Create Sports
    football = Sport.objects.create(name='Football', icon_name='sports_soccer')
    cricket = Sport.objects.create(name='Cricket', icon_name='sports_cricket')
    badminton = Sport.objects.create(name='Badminton', icon_name='sports_tennis')
    basketball = Sport.objects.create(name='Basketball', icon_name='sports_basketball')

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

    print("Successfully seeded the database!")

if __name__ == '__main__':
    seed()
