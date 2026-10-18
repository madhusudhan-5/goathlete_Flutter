import os
import django
import sys

sys.path.append('goathlete_backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'goathlete_backend.settings')
django.setup()

from django.contrib.auth.models import User

execs = User.objects.filter(profile__role='EXECUTIVE')
count = execs.count()
execs.delete()
print(f"Deleted {count} executives.")
