from rest_framework import serializers
from .models import HighlightBanner, SportCategory, QuickAction

class HighlightBannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = HighlightBanner
        fields = '__all__'

class SportCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SportCategory
        fields = '__all__'

class QuickActionSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuickAction
        fields = '__all__'

from .models import GlobalConfig, PromotionalOffer

class GlobalConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = GlobalConfig
        fields = '__all__'

class PromotionalOfferSerializer(serializers.ModelSerializer):
    class Meta:
        model = PromotionalOffer
        fields = '__all__'
