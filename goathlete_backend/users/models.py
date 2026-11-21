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
    requires_password_change = models.BooleanField(default=False)
    kyc_status = models.CharField(max_length=20, default='PENDING')
    primary_sport = models.CharField(max_length=50, null=True, blank=True)
    skill_level = models.CharField(max_length=50, null=True, blank=True)
    bio = models.TextField(null=True, blank=True)
    
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


class BetaTester(models.Model):
    STATUS_CHOICES = (
        ('REGISTERED', 'Email Registered'),
        ('GROUP_JOINED', 'Opened Tester Group'),
        ('PLAY_OPENED', 'Opened Play Store Install'),
        ('ADDED_IN_PLAY', 'Added in Play Console'),
    )

    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=120, blank=True, default='')
    phone_number = models.CharField(max_length=20, blank=True, default='')
    source = models.CharField(max_length=80, blank=True, default='qr_portal')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='REGISTERED')
    group_joined_at = models.DateTimeField(null=True, blank=True)
    play_opened_at = models.DateTimeField(null=True, blank=True)
    user_agent = models.CharField(max_length=300, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if self.email:
            self.email = self.email.strip().lower()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.email} ({self.get_status_display()})"

from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.get_or_create(user=instance)

