from django.db import models

class HighlightBanner(models.Model):
    title = models.CharField(max_length=255)
    image_url = models.URLField(max_length=500)
    discount_text = models.CharField(max_length=100, blank=True)
    redirect_url = models.URLField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    order = models.IntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return self.title


class SportCategory(models.Model):
    name = models.CharField(max_length=100)
    icon_name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)
    order = models.IntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return self.name


class QuickAction(models.Model):
    title = models.CharField(max_length=100)
    icon_name = models.CharField(max_length=100)
    route = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True)
    order = models.IntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return self.title

class GlobalConfig(models.Model):
    commission_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=10.00)
    payout_cycle_days = models.IntegerField(default=7)
    minimum_payout_threshold = models.DecimalField(max_digits=10, decimal_places=2, default=100.00)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Global Config - {self.commission_percentage}% Commission"

class PromotionalOffer(models.Model):
    code = models.CharField(max_length=50, unique=True)
    discount_percent = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    flat_discount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    valid_until = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return self.code
