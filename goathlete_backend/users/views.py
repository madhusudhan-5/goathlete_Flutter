from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import UserSerializer, RegisterSerializer
from .serializers import UserSerializer, RegisterSerializer
from .models import OTP, UserProfile
import random
import re
import urllib.request
import json

class SendOTPView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        phone_number = request.data.get('phone_number')
        if not phone_number:
            return Response({'error': 'Phone number is required'}, status=status.HTTP_400_BAD_REQUEST)

        # Validate Indian Phone Number
        pattern = re.compile(r'^(?:\+91|91)?[6789]\d{9}$')
        if not pattern.match(phone_number):
            return Response({'error': 'Invalid Indian phone number.'}, status=status.HTTP_400_BAD_REQUEST)

        otp_code = str(random.randint(100000, 999999))
        OTP.objects.create(phone_number=phone_number, otp_code=otp_code)

        return Response({
            'message': 'OTP sent successfully',
            'dev_otp': otp_code
        }, status=status.HTTP_200_OK)

class VerifyOTPView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        phone_number = request.data.get('phone_number')
        otp_code = request.data.get('otp_code')

        if not phone_number or not otp_code:
            return Response({'error': 'Phone number and OTP are required'}, status=status.HTTP_400_BAD_REQUEST)

        otp_record = OTP.objects.filter(phone_number=phone_number, otp_code=otp_code, is_used=False).last()

        if not otp_record:
            return Response({'error': 'Invalid or expired OTP'}, status=status.HTTP_400_BAD_REQUEST)

        otp_record.is_used = True
        otp_record.save()

        user = User.objects.filter(username=phone_number).first()
        if not user:
            user = User.objects.create_user(username=phone_number)
            UserProfile.objects.create(user=user, phone_number=phone_number, is_phone_verified=True)
        else:
            profile, _ = UserProfile.objects.get_or_create(user=user)
            if not profile.phone_number:
                profile.phone_number = phone_number
                profile.is_phone_verified = True
                profile.save()

        refresh = RefreshToken.for_user(user)

        return Response({
            'message': 'OTP verified successfully',
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'role': profile.role,
            'is_profile_complete': profile.is_profile_complete,
        }, status=status.HTTP_200_OK)

class GoogleLoginView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        id_token = request.data.get('id_token')
        if not id_token:
            return Response({'error': 'Google ID token is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Verify the token with Google
            url = f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req) as response:
                google_data = json.loads(response.read().decode())
                
            email = google_data.get('email')
            if not email:
                return Response({'error': 'Email not provided by Google'}, status=status.HTTP_400_BAD_REQUEST)
                
            user = User.objects.filter(email=email).first()
            if not user:
                user = User.objects.create_user(username=email, email=email)
                user.first_name = google_data.get('given_name', '')
                user.last_name = google_data.get('family_name', '')
                user.save()
                profile = UserProfile.objects.create(user=user, is_phone_verified=False)
            else:
                profile, _ = UserProfile.objects.get_or_create(user=user)
                
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'message': 'Google login successful',
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'role': profile.role,
                'is_profile_complete': profile.is_profile_complete,
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({'error': f'Invalid Google token: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

class ProfileView(generics.RetrieveAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

class ProfileUpdateView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def put(self, request):
        user = request.user
        profile = user.profile
        
        first_name = request.data.get('first_name')
        email = request.data.get('email')
        date_of_birth = request.data.get('date_of_birth')
        profile_picture = request.FILES.get('profile_picture')
        
        if first_name:
            user.first_name = first_name
        if email:
            user.email = email
        user.save()
        
        if date_of_birth:
            profile.date_of_birth = date_of_birth
        if profile_picture:
            profile.profile_picture = profile_picture
            
        profile.save()
            
        return Response({
            'message': 'Profile updated successfully',
            'is_profile_complete': profile.is_profile_complete,
            'goath_id': profile.goath_id,
            'profile_picture': request.build_absolute_uri(profile.profile_picture.url) if profile.profile_picture else None
        }, status=status.HTTP_200_OK)

from rest_framework import viewsets
from .serializers import ExecutiveSerializer

class ExecutiveViewSet(viewsets.ModelViewSet):
    """
    API endpoint for Super Admins to manage executives.
    """
    serializer_class = ExecutiveSerializer
    # In a real app, restrict to Super Admins
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return User.objects.filter(profile__role='EXECUTIVE')
