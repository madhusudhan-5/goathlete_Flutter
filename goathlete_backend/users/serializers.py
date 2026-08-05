from django.contrib.auth.models import User
from rest_framework import serializers

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name')

class ProfileSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source='profile.phone_number', read_only=True)
    goath_id = serializers.CharField(source='profile.goath_id', read_only=True)
    role = serializers.CharField(source='profile.role', read_only=True)
    date_of_birth = serializers.DateField(source='profile.date_of_birth', read_only=True)
    profile_picture = serializers.ImageField(source='profile.profile_picture', read_only=True)
    primary_sport = serializers.CharField(source='profile.primary_sport', read_only=True)
    skill_level = serializers.CharField(source='profile.skill_level', read_only=True)
    bio = serializers.CharField(source='profile.bio', read_only=True)

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'first_name', 'last_name',
            'phone_number', 'goath_id', 'role', 'date_of_birth',
            'profile_picture', 'primary_sport', 'skill_level', 'bio'
        )

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password', 'first_name', 'last_name')

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user

class ExecutiveSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source='profile.phone_number', required=False)
    goath_id = serializers.CharField(source='profile.goath_id', read_only=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'phone_number', 'goath_id')

    def create(self, validated_data):
        profile_data = validated_data.pop('profile', {})
        user = User.objects.create(**validated_data)
        from .models import UserProfile
        profile, created = UserProfile.objects.get_or_create(user=user)
        profile.role = 'EXECUTIVE'
        if 'phone_number' in profile_data:
            profile.phone_number = profile_data['phone_number']
        profile.save()
        return user
