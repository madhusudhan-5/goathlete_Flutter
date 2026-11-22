from django.contrib import admin, messages
from .models import Venue, PreRegisteredVenue, Sport, VenueSport, Amenity, VenueImage
from .services import approve_preregistered_venue


class PreRegisteredVenueImageInline(admin.TabularInline):
    model = VenueImage
    fk_name = 'preregistered_venue'
    extra = 1
    fields = ('image', 'uploaded_at')
    readonly_fields = ('uploaded_at',)


class VenueImageInline(admin.TabularInline):
    model = VenueImage
    fk_name = 'venue'
    extra = 1
    fields = ('image', 'uploaded_at')
    readonly_fields = ('uploaded_at',)


@admin.action(description="Approve & Publish selected venues to Customer App")
def approve_and_publish_venues(modeladmin, request, queryset):
    count = 0
    for prereg in queryset:
        approve_preregistered_venue(prereg)
        count += 1
    modeladmin.message_user(
        request,
        f"Approved and published {count} venue(s) to the live Customer App.",
        messages.SUCCESS,
    )


@admin.action(description="Reject selected venues")
def reject_venues(modeladmin, request, queryset):
    updated = queryset.update(status='REJECTED')
    modeladmin.message_user(request, f"Rejected {updated} venue(s).", messages.WARNING)


@admin.register(PreRegisteredVenue)
class PreRegisteredVenueAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'name',
        'owner_name',
        'phone_number',
        'ground_type',
        'license_number',
        'status',
        'real_venue',
        'executive',
        'created_at',
    )
    list_filter = ('status', 'ground_type', 'created_at')
    search_fields = ('name', 'owner_name', 'phone_number', 'license_number', 'address')
    readonly_fields = ('real_venue', 'created_at', 'updated_at')
    actions = [approve_and_publish_venues, reject_venues]
    inlines = [PreRegisteredVenueImageInline]

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        if obj.status == 'APPROVED' and not obj.real_venue:
            approve_preregistered_venue(obj)


@admin.register(Venue)
class VenueAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'location', 'ground_type', 'price_per_hour', 'license_number', 'owner', 'created_at')
    list_filter = ('ground_type', 'created_at')
    search_fields = ('name', 'location', 'license_number')
    inlines = [VenueImageInline]


admin.site.register(VenueImage)
admin.site.register(Sport)
admin.site.register(VenueSport)
admin.site.register(Amenity)
