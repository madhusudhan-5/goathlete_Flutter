import csv
from django.contrib import admin
from django.http import HttpResponse
from .models import UserProfile, OTP, BetaTester

admin.site.register(UserProfile)
admin.site.register(OTP)


@admin.action(description="Export selected emails as CSV (Play Console / Group format)")
def export_beta_testers_csv(modeladmin, request, queryset):
    response = HttpResponse(content_type="text/csv")
    response["Content-Disposition"] = 'attachment; filename="goathlete_android_testers.csv"'
    writer = csv.writer(response)
    writer.writerow(["Email", "Full Name", "Phone", "Status", "Source", "Registered At"])
    for tester in queryset:
        writer.writerow([
            tester.email,
            tester.full_name,
            tester.phone_number,
            tester.status,
            tester.source,
            tester.created_at.isoformat(),
        ])
    return response


@admin.action(description="Mark selected testers as Added in Play Console")
def mark_added_in_play(modeladmin, request, queryset):
    queryset.update(status="ADDED_IN_PLAY")


@admin.register(BetaTester)
class BetaTesterAdmin(admin.ModelAdmin):
    list_display = (
        "email",
        "full_name",
        "phone_number",
        "status",
        "source",
        "group_joined_at",
        "play_opened_at",
        "created_at",
    )
    list_filter = ("status", "source", "created_at")
    search_fields = ("email", "full_name", "phone_number")
    readonly_fields = ("created_at", "updated_at", "group_joined_at", "play_opened_at", "user_agent")
    actions = [export_beta_testers_csv, mark_added_in_play]
