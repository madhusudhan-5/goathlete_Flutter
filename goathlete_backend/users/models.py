from django.db import models
from django.contrib.auth.models import User
import random
import string

def generate_goath_id():
    chars = string.ascii_uppercase + string.digits
    hash_str = ''.join(random.choices(chars, k=14))
    return f"GOATH-{hash_str}"

class UserProfile(models.Model):
    ROLE_CHOICES = (
        ('CUSTOMER', 'Customer'),
        ('VENDOR', 'Vendor'),
        ('EXECUTIVE', 'Executive'),
        ('SUPER_ADMIN', 'Super Admin'),
    )
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    phone_number = models.CharField(max_length=15, unique=True, null=True, blank=True)
    goath_id = models.CharField(max_length=20, unique=True, default=generate_goath_id)
    is_phone_verified = models.BooleanField(default=False)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='CUSTOMER')
    date_of_birth = models.DateField(null=True, blank=True)
    profile_picture = models.ImageField(upload_to='profiles/', null=True, blank=True)
    kyc_status = models.CharField(max_length=20, default='PENDING')
    
    @property
    def is_profile_complete(self):
        return bool(self.user.first_name and self.user.email and self.date_of_birth)

    def __str__(self):
        return f"{self.user.username} - {self.phone_number}"

class OTP(models.Model):
    phone_number = models.CharField(max_length=15)
    otp_code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.phone_number} - {self.otp_code}"
