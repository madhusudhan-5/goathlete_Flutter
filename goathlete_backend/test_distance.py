import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "goathlete_backend.settings")
django.setup()

from venues.models import Venue
from django.contrib.auth.models import User

user, _ = User.objects.get_or_create(username='testuser')

Venue.objects.all().delete()
Venue.objects.create(name='Venue Null', owner=user, rating=4.0)
Venue.objects.create(name='Venue Far', owner=user, latitude=40.0, longitude=-74.0, rating=4.5)
Venue.objects.create(name='Venue Near', owner=user, latitude=40.7, longitude=-74.1, rating=4.8)

from django.db.models import F, FloatField, ExpressionWrapper
from django.db.models.functions import Power

lat_f = 40.7128
lng_f = -74.0060

distance_expr = ExpressionWrapper(
    Power(F('latitude') - lat_f, 2) + Power(F('longitude') - lng_f, 2),
    output_field=FloatField()
)

qs = Venue.objects.annotate(computed_distance=distance_expr).order_by(F('computed_distance').asc(nulls_last=True), '-rating')
for v in qs:
    print(v.name, getattr(v, 'computed_distance', 'None'))
