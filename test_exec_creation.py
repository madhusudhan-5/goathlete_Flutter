import os
import django
import sys
import uuid

sys.path.append('goathlete_backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from django.contrib.auth.models import User
from users.models import UserProfile
from django.utils.crypto import get_random_string

# Create a test executive
email = f"testexec_{uuid.uuid4().hex[:6]}@goathlete.com"
password = "Test@12345"

try:
    user = User.objects.create_user(username=email, email=email, password=password)
    profile = user.profile
    profile.role = 'EXECUTIVE'
    profile.phone_number = f"+919999{get_random_string(6, allowed_chars='0123456789')}"
    profile.requires_password_change = True
    profile.save()
    print(f"SUCCESS: Executive created.\nEmail: {email}\nPassword: {password}")
except Exception as e:
    print(f"ERROR: {e}")

