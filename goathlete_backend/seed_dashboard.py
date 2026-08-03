import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from dashboard.models import HighlightBanner, SportCategory, QuickAction

def seed_dashboard():
    # Clear existing
    HighlightBanner.objects.all().delete()
    SportCategory.objects.all().delete()
    QuickAction.objects.all().delete()

    # Create Banners
    HighlightBanner.objects.create(
        title="Unlock 20% off on your first turf booking!",
        image_url="https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?auto=format&fit=crop&w=600&q=80",
        discount_text="20% OFF",
        redirect_url="/explore",
        order=1
    )
    HighlightBanner.objects.create(
        title="Join the Weekend Badminton League",
        image_url="https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=600&q=80",
        discount_text="Win Prizes",
        redirect_url="/tournaments",
        order=2
    )

    # Create Sports
    sports = [
        {"name": "Badminton", "icon_name": "sports_tennis", "order": 1},
        {"name": "Football", "icon_name": "sports_soccer", "order": 2},
        {"name": "Cricket", "icon_name": "sports_cricket", "order": 3},
        {"name": "Tennis", "icon_name": "sports_baseball", "order": 4},
        {"name": "Basketball", "icon_name": "sports_basketball", "order": 5},
    ]
    for sport in sports:
        SportCategory.objects.create(**sport)

    # Create Quick Actions
    actions = [
        {"title": "Games", "icon_name": "sports_esports", "route": "/explore", "order": 1},
        {"title": "Tournaments", "icon_name": "emoji_events", "route": "/tournaments", "order": 2},
        {"title": "Coaching", "icon_name": "model_training", "route": "/explore", "order": 3},
        {"title": "Venues", "icon_name": "stadium", "route": "/explore", "order": 4},
        {"title": "Squads", "icon_name": "groups", "route": "/explore", "order": 5},
    ]
    for action in actions:
        QuickAction.objects.create(**action)

    print("Dashboard seeded successfully!")

if __name__ == '__main__':
    seed_dashboard()
