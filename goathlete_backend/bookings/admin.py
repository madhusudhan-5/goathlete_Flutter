from django.contrib import admin
from .models import Booking, Payment, BookingRentalItem


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ('user', 'venue', 'date', 'start_time', 'end_time', 'status', 'total_price')
    list_filter = ('status', 'date', 'venue')
    search_fields = ('user__username', 'user__email', 'venue__name')
    date_hierarchy = 'date'


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'booking',
        'provider',
        'amount',
        'currency',
        'status',
        'razorpay_order_id',
        'transaction_id',
        'created_at',
    )
    list_filter = ('provider', 'status', 'currency', 'created_at')
    search_fields = ('razorpay_order_id', 'transaction_id', 'booking__user__username', 'booking__venue__name')
    readonly_fields = ('created_at', 'updated_at')


admin.site.register(BookingRentalItem)
