from django.contrib import admin
from .models import Venue, PreRegisteredVenue, Sport, VenueSport, Amenity

admin.site.register(Venue)
admin.site.register(PreRegisteredVenue)
admin.site.register(Sport)
admin.site.register(VenueSport)
admin.site.register(Amenity)
