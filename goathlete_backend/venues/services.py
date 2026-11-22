import json
import uuid
from django.contrib.auth.models import User
from .models import Venue, Sport, VenueSport


def approve_preregistered_venue(prereg, reverse_geocode_fn=None):
    """
    Approves a PreRegisteredVenue and publishes a live Venue + Vendor user +
    linked VenueSport records so it immediately appears in the Customer App.
    Idempotent if `prereg.real_venue` already exists.
    """
    prereg.status = 'APPROVED'

    if not prereg.real_venue:
        username = prereg.phone_number if prereg.phone_number else prereg.email
        if not username:
            username = f"vendor_{uuid.uuid4().hex[:8]}"

        user, created = User.objects.get_or_create(username=username)
        if created:
            user.first_name = prereg.owner_name
            user.email = prereg.email or ''
            password = 'Test@12345'
            user.set_password(password)
            user.save()
            print(f"EMAIL SENT: Vendor login details for {prereg.name}: Username: {username}, Password: {password}")

            if hasattr(user, 'profile'):
                profile = user.profile
                profile.requires_password_change = True
                profile.save()

        if hasattr(user, 'profile'):
            profile = user.profile
            if profile.role != 'VENDOR':
                profile.role = 'VENDOR'
            if not profile.phone_number and prereg.phone_number:
                profile.phone_number = prereg.phone_number
            profile.save()

        resolved_loc = (prereg.address or '').strip()
        if (
            reverse_geocode_fn is not None
            and prereg.latitude is not None
            and prereg.longitude is not None
            and (not resolved_loc or resolved_loc.startswith('Lat:'))
        ):
            geocoded_name = reverse_geocode_fn(prereg.latitude, prereg.longitude)
            if geocoded_name:
                resolved_loc = geocoded_name
                prereg.address = geocoded_name

        parsed_sports = {}
        base_price = 0.0
        if prereg.sports_prices:
            try:
                raw_parsed = json.loads(prereg.sports_prices)
                if isinstance(raw_parsed, dict):
                    parsed_sports = raw_parsed
                    numeric_prices = []
                    for val in raw_parsed.values():
                        try:
                            p = float(val)
                            if p > 0:
                                numeric_prices.append(p)
                        except (TypeError, ValueError):
                            pass
                    if numeric_prices:
                        base_price = min(numeric_prices)
            except Exception:
                pass

        first_image = prereg.images.first()
        primary_image_url = ''
        if first_image and first_image.image:
            primary_image_url = first_image.image.url
        elif prereg.document_url and not prereg.document_url.startswith('https://dummy-storage'):
            primary_image_url = prereg.document_url

        real_venue = Venue.objects.create(
            name=prereg.name,
            location=resolved_loc,
            owner=user,
            latitude=prereg.latitude,
            longitude=prereg.longitude,
            image_url=primary_image_url,
            ground_type=prereg.ground_type,
            license_number=prereg.license_number,
            sports_prices=prereg.sports_prices,
            price_per_hour=base_price,
        )

        # Link all uploaded onboarding photos to the live Venue
        prereg.images.update(venue=real_venue)

        for sport_name in parsed_sports.keys():
            clean_name = str(sport_name).strip()
            if not clean_name:
                continue
            sport_obj, _ = Sport.objects.get_or_create(
                name__iexact=clean_name,
                defaults={'name': clean_name, 'icon_name': 'sports'},
            )
            VenueSport.objects.get_or_create(venue=real_venue, sport=sport_obj)

        prereg.real_venue = real_venue

    prereg.save()
    return prereg.real_venue
