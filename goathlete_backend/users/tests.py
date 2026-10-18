from django.test import TestCase
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from users.models import UserProfile, OTP
from tournaments.models import SportTemplate, Tournament, Team, Match
from venues.models import Venue, PreRegisteredVenue
from dashboard.models import HighlightBanner, SportCategory, QuickAction

class FreshRegistrationAndPlatformTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        # Seed master templates for the test DB
        self.cricket_template = SportTemplate.objects.create(
            name="Cricket",
            min_players_per_team=2,
            max_players_per_team=11,
            default_rules={"format": "T20"}
        )
        HighlightBanner.objects.create(title="Welcome Offer", image_url="https://test.com/banner.jpg", redirect_url="/explore")
        SportCategory.objects.create(name="Badminton", icon_name="sports_tennis", order=1)

    def test_customer_otp_registration_and_profile_setup(self):
        # 1. Send OTP
        phone = "9876543210"
        send_res = self.client.post('/api/users/send-otp/', {'phone_number': phone})
        self.assertEqual(send_res.status_code, 200)
        dev_otp = send_res.data.get('dev_otp')
        self.assertTrue(dev_otp)

        # 2. Verify OTP
        verify_res = self.client.post('/api/users/verify-otp/', {
            'phone_number': phone,
            'otp_code': dev_otp
        })
        self.assertEqual(verify_res.status_code, 200)
        self.assertIn('access', verify_res.data)
        self.assertEqual(verify_res.data['is_profile_complete'], False)

        token = verify_res.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        # 3. Complete Profile
        update_res = self.client.put('/api/users/profile/update/', {
            'first_name': 'Rahul',
            'email': 'rahul@example.com',
            'date_of_birth': '1998-05-15',
            'primary_sport': 'Cricket',
            'skill_level': 'Intermediate'
        })
        self.assertEqual(update_res.status_code, 200)
        self.assertTrue(update_res.data['is_profile_complete'])
        self.assertTrue(update_res.data['goath_id'].startswith('GOATH-'))

        # 4. Fetch Profile
        profile_res = self.client.get('/api/users/profile/')
        self.assertEqual(profile_res.status_code, 200)
        self.assertEqual(profile_res.data['first_name'], 'Rahul')
        self.assertEqual(profile_res.data['email'], 'rahul@example.com')

    def test_vendor_venue_creation_and_ownership(self):
        vendor_user = User.objects.create_user(username='9999999999', password='password123')
        vendor_profile = vendor_user.profile
        vendor_profile.role = 'VENDOR'
        vendor_profile.phone_number = '9999999999'
        vendor_profile.save()

        # Login vendor
        from rest_framework_simplejwt.tokens import RefreshToken
        token = str(RefreshToken.for_user(vendor_user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        # Create venue
        create_res = self.client.post('/api/venues/vendor-venues/', {
            'name': 'Green Arena Turf',
            'description': 'Premium 5v5 turf',
            'location': 'Koramangala, Bangalore',
            'price_per_hour': '1200.00'
        })
        self.assertEqual(create_res.status_code, 201)
        prereg_id = create_res.data['id']

        # Approve the venue as an admin
        admin_user = User.objects.create_superuser(username='admin_kyc', password='password123')
        admin_user.profile.role = 'SUPER_ADMIN'
        admin_user.profile.save()
        token_admin = str(RefreshToken.for_user(admin_user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token_admin}')
        approve_res = self.client.post(f'/api/venues/pre-register-venues/{prereg_id}/approve/')
        self.assertEqual(approve_res.status_code, 200)

        # Switch back to vendor
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        # Check vendor venues list
        list_res = self.client.get('/api/venues/vendor-venues/')
        self.assertEqual(list_res.status_code, 200)
        self.assertEqual(len(list_res.data), 1)
        self.assertEqual(list_res.data[0]['name'], 'Green Arena Turf')

        # Check vendor dashboard stats on empty bookings
        dash_res = self.client.get('/api/bookings/vendor-dashboard/')
        self.assertEqual(dash_res.status_code, 200)
        self.assertEqual(dash_res.data['total_revenue'], 0)
        self.assertEqual(dash_res.data['total_bookings'], 0)

    def test_executive_venue_pre_registration(self):
        exec_user = User.objects.create_user(username='exec_user', password='password123')
        exec_profile = exec_user.profile
        exec_profile.role = 'EXECUTIVE'
        exec_profile.save()

        from rest_framework_simplejwt.tokens import RefreshToken
        token = str(RefreshToken.for_user(exec_user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        # Pre-register a venue lead
        lead_res = self.client.post('/api/venues/pre-register-venues/', {
            'name': 'Power Play Sports Complex',
            'owner_name': 'Amit Kumar',
            'phone_number': '9123456780',
            'email': 'amit@powerplay.com',
            'address': 'Indiranagar, Bangalore',
            'latitude': '12.971600',
            'longitude': '77.594600',
            'status': 'PENDING_APPROVAL'
        })
        self.assertEqual(lead_res.status_code, 201)

        self.assertEqual(PreRegisteredVenue.objects.count(), 1)

    def test_tournament_streamlined_creation_on_fresh_db(self):
        organizer = User.objects.create_user(username='organizer_user', password='password123')
        from rest_framework_simplejwt.tokens import RefreshToken
        token = str(RefreshToken.for_user(organizer).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        res = self.client.post('/api/tournaments/tournaments/create_streamlined/', {
            'name': 'GoAthlete Premier Cricket Cup',
            'sport_template': self.cricket_template.id,
            'start_date': '2026-10-01',
            'end_date': '2026-10-05',
            'location': 'Bangalore Stadium',
            'team_names': ['Spartans XI', 'Titans XI', 'Warriors XI', 'Strikers XI'],
            'format': 'Knockout'
        }, format='json')

        self.assertEqual(res.status_code, 201)
        self.assertEqual(Tournament.objects.count(), 1)
        self.assertEqual(Team.objects.count(), 4)
        self.assertGreater(Match.objects.count(), 0)
