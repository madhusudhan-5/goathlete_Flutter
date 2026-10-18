import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from django.test import Client
from users.models import User, UserProfile
from rest_framework_simplejwt.tokens import RefreshToken
import json

c = Client()

# 1. Test UserLookupView PII masking
print("Testing UserLookupView PII masking...")
user1, _ = User.objects.get_or_create(username='testpii')
user1.set_password('password123')
user1.save()
profile1 = user1.profile
profile1.phone_number = '9876543210'
profile1.goath_id = 'GOATH-999'
profile1.save()
token = str(RefreshToken.for_user(user1).access_token)
res = c.get('/api/users/lookup/?q=98765', HTTP_AUTHORIZATION=f'Bearer {token}')
data = json.loads(res.content)
assert data[0]['phone_number'] == '987****210', f"PII not masked correctly: {data[0]['phone_number']}"
print("UserLookupView PII masking: OK")

# 2. Test ExecutiveViewSet RBAC
print("Testing ExecutiveViewSet RBAC...")
# user1 is not admin
res = c.get('/api/users/executives/', HTTP_AUTHORIZATION=f'Bearer {token}')
assert res.status_code == 403, f"Expected 403, got {res.status_code}"
print("ExecutiveViewSet RBAC: OK")

# 3. Test ProfileUpdateView Email uniqueness
print("Testing ProfileUpdateView Email Uniqueness...")
user2, _ = User.objects.get_or_create(username='testemail2')
user2.email = 'used@example.com'
user2.set_password('password123')
user2.save()
res = c.put('/api/users/profile/update/', {'email': 'used@example.com'}, HTTP_AUTHORIZATION=f'Bearer {token}', content_type='application/json')
assert res.status_code == 400, f"Expected 400, got {res.status_code}"
print("ProfileUpdateView Email Uniqueness: OK")

# 4. Test DOB validation
print("Testing DOB validation...")
res = c.put('/api/users/profile/update/', {'date_of_birth': '2050-01-01'}, HTTP_AUTHORIZATION=f'Bearer {token}', content_type='application/json')
assert res.status_code == 400, f"Expected 400, got {res.status_code}"
print("DOB validation: OK")

# 5. Test VerifyOTPView phone format
print("Testing VerifyOTPView phone format...")
res = c.post('/api/users/verify-otp/', {'phone_number': '12345', 'otp_code': '123456'})
assert res.status_code == 400, f"Expected 400, got {res.status_code}"
print("VerifyOTPView phone format: OK")

print("All tests passed!")
