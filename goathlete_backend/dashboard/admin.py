from django.contrib import admin
from .models import HighlightBanner, SportCategory, QuickAction, GlobalConfig, PromotionalOffer

admin.site.register(HighlightBanner)
admin.site.register(SportCategory)
admin.site.register(QuickAction)
admin.site.register(GlobalConfig)
admin.site.register(PromotionalOffer)
