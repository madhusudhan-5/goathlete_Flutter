from django.db import models

class Venue(models.Model):
    owner = models.ForeignKey('auth.User', on_delete=models.CASCADE, related_name='owned_venues', null=True, blank=True)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    location = models.CharField(max_length=255)
    distance = models.CharField(max_length=50, blank=True)
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=0.0)
    reviews_count = models.IntegerField(default=0)
    image_url = models.URLField(max_length=500, blank=True)
    price_per_hour = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    license_number = models.CharField(max_length=255, blank=True)
    sports_prices = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Sport(models.Model):
    name = models.CharField(max_length=100)
    icon_name = models.CharField(max_length=100, help_text="Flutter Icon name equivalent")
    
    def __str__(self):
        return self.name

class VenueSport(models.Model):
    venue = models.ForeignKey(Venue, related_name='sports', on_delete=models.CASCADE)
    sport = models.ForeignKey(Sport, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"{self.venue.name} - {self.sport.name}"

class Amenity(models.Model):
    venue = models.ForeignKey(Venue, related_name='amenities', on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    icon_name = models.CharField(max_length=100)
    
    def __str__(self):
        return f"{self.venue.name} - {self.name}"
class PreRegisteredVenue(models.Model):
    STATUS_CHOICES = (
        ('DRAFT', 'Draft'),
        ('PENDING_APPROVAL', 'Pending Approval'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
    )
    
    executive = models.ForeignKey('auth.User', on_delete=models.CASCADE, related_name='onboarded_venues')
    real_venue = models.ForeignKey('Venue', on_delete=models.SET_NULL, null=True, blank=True, related_name='preregistered_by')
    
    # Step 1: Basic Details
    name = models.CharField(max_length=255)
    owner_name = models.CharField(max_length=255)
    phone_number = models.CharField(max_length=15)
    email = models.EmailField(blank=True, null=True)
    
    # Step 2: GPS Location
    address = models.TextField(blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    
    # Step 3: Media
    document_url = models.URLField(max_length=500, blank=True)
    
    # Step 4: Meeting Schedule
    meeting_date = models.DateTimeField(null=True, blank=True)
    meeting_notes = models.TextField(blank=True)
    
    # Step 5: License & Pricing
    license_number = models.CharField(max_length=255, blank=True)
    sports_prices = models.TextField(blank=True)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DRAFT')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.name} - {self.status}"

class VendorPartner(models.Model):
    venue = models.ForeignKey(Venue, related_name='vendor_partners', on_delete=models.CASCADE)
    user = models.ForeignKey('auth.User', related_name='partnered_venues', on_delete=models.CASCADE)
    can_manage_bookings = models.BooleanField(default=True)
    can_manage_items = models.BooleanField(default=True)
    
    class Meta:
        unique_together = ('venue', 'user')

    def __str__(self):
        return f"{self.user.username} - {self.venue.name}"

class RentalItem(models.Model):
    venue = models.ForeignKey(Venue, related_name='rental_items', on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    price_per_hour = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    quantity_available = models.PositiveIntegerField(default=1)

    def __str__(self):
        return f"{self.name} at {self.venue.name}"

class Court(models.Model):
    venue = models.ForeignKey(Venue, related_name='courts', on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    sport = models.CharField(max_length=100, blank=True)

    def __str__(self):
        return f"{self.venue.name} - {self.name}"

class CourtSlotPricing(models.Model):
    PERIOD_CHOICES = (
        ('Morning', 'Morning'),
        ('Daytime', 'Daytime'),
        ('Evening', 'Evening'),
        ('Night', 'Night'),
    )
    court = models.ForeignKey(Court, related_name='slot_pricings', on_delete=models.CASCADE)
    time_period = models.CharField(max_length=20, choices=PERIOD_CHOICES)
    start_time = models.TimeField()
    end_time = models.TimeField()
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    class Meta:
        unique_together = ('court', 'time_period')

    def __str__(self):
        return f"{self.court.name} - {self.time_period} ({self.price})"
