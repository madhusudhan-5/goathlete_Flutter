import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from django.test.utils import setup_test_environment
setup_test_environment()

from django.test import Client
from django.contrib.auth.models import User
import json

c = Client()

# Create a Super Admin to create an executive
admin, created = User.objects.get_or_create(username='admin')
admin.email = 'admin@example.com'
admin.set_password('adminpass')
admin.is_superuser = True
admin.is_staff = True
admin.save()
from users.models import UserProfile
profile, _ = UserProfile.objects.get_or_create(user=admin)
profile.role = 'SUPER_ADMIN'
profile.save()

# Delete exec_test if exists
User.objects.filter(username='exec_test').delete()

# Login as admin to get token
response = c.post('/api/users/login/', {'username': 'admin', 'password': 'adminpass'})
assert response.status_code == 200
access_token = response.json()['access']

# Create Executive
response = c.post('/api/users/executives/', 
    {'username': 'exec_test', 'email': 'exec@test.com', 'first_name': 'Exec', 'last_name': 'Test'},
    HTTP_AUTHORIZATION=f'Bearer {access_token}',
    content_type='application/json'
)
print("Create Executive:", response.status_code, response.content)
assert response.status_code == 201

# Login as Executive
response = c.post('/api/users/login/', {'username': 'exec_test', 'password': 'Test@12345'})
print("Login Executive:", response.status_code)
assert response.status_code == 200
exec_token = response.json()['access']

# Check Profile
response = c.get('/api/users/profile/', HTTP_AUTHORIZATION=f'Bearer {exec_token}')
print("Profile Executive:", response.status_code, response.content)
assert response.status_code == 200
assert response.json()['requires_password_change'] == True

# Change Password
response = c.post('/api/users/change-password/', 
    {'old_password': 'Test@12345', 'new_password': 'NewPassword!123'},
    HTTP_AUTHORIZATION=f'Bearer {exec_token}',
    content_type='application/json'
)
print("Change Password:", response.status_code, response.content)
assert response.status_code == 200

# Check Profile Again
response = c.get('/api/users/profile/', HTTP_AUTHORIZATION=f'Bearer {exec_token}')
print("Profile Executive After:", response.status_code, response.content)
assert response.status_code == 200
assert response.json()['requires_password_change'] == False

# Login with new password
response = c.post('/api/users/login/', {'username': 'exec_test', 'password': 'NewPassword!123'})
print("Login Executive New Password:", response.status_code)
assert response.status_code == 200

print("ALL TESTS PASSED")
