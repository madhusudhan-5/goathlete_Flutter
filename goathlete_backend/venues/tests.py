from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from .models import PreRegisteredVenue, Venue

class VenueApprovalTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin_user = User.objects.create_superuser('admin', 'admin@example.com', 'pass')
        profile = self.admin_user.profile
        profile.role = 'SUPER_ADMIN'
        profile.save()
        self.executive = User.objects.create_user('exec', 'exec@example.com', 'pass')
        
        self.pre_reg_venue = PreRegisteredVenue.objects.create(
            executive=self.executive,
            name='Test Venue',
            owner_name='Test Owner',
            phone_number='1234567890',
            email='owner@example.com',
            address='123 Test St'
        )
        
    def test_approve_creates_vendor_and_venue(self):
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.post(f'/api/venues/pre-register-venues/{self.pre_reg_venue.id}/approve/')
        print("Response:", response.status_code, getattr(response, 'data', response.content))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.status_code, 200)
        
        self.pre_reg_venue.refresh_from_db()
        self.assertEqual(self.pre_reg_venue.status, 'APPROVED')
        self.assertIsNotNone(self.pre_reg_venue.real_venue)
        
        real_venue = self.pre_reg_venue.real_venue
        self.assertEqual(real_venue.name, 'Test Venue')
        
        owner = real_venue.owner
        self.assertIsNotNone(owner)
        self.assertEqual(owner.first_name, 'Test Owner')
        self.assertEqual(owner.email, 'owner@example.com')
        self.assertEqual(owner.profile.role, 'VENDOR')
        self.assertEqual(owner.profile.phone_number, '1234567890')

    def test_approve_existing_user(self):
        # Create an existing user with CUSTOMER role and NO required password change
        existing_user = User.objects.create(username='0987654321')
        existing_user.set_password('old_password')
        existing_user.save()
        profile = existing_user.profile
        profile.role = 'CUSTOMER'
        profile.requires_password_change = False
        profile.phone_number = '0987654321'
        profile.save()

        pre_reg = PreRegisteredVenue.objects.create(
            executive=self.executive,
            name='Test Venue 2',
            owner_name='Existing Owner',
            phone_number='0987654321', # Should match the username/phone logic in views
            email='existing@example.com',
            address='456 Test St'
        )

        self.client.force_authenticate(user=self.admin_user)
        response = self.client.post(f'/api/venues/pre-register-venues/{pre_reg.id}/approve/')
        self.assertEqual(response.status_code, 200)

        existing_user.refresh_from_db()
        existing_user.profile.refresh_from_db()
        
        # User should now be a VENDOR
        self.assertEqual(existing_user.profile.role, 'VENDOR')
        
        # User should NOT require password change
        self.assertFalse(existing_user.profile.requires_password_change)
        
        # User should still own the new real venue
        pre_reg.refresh_from_db()
        self.assertEqual(pre_reg.real_venue.owner, existing_user)
