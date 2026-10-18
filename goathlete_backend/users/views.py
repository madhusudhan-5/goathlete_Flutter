from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import UserSerializer, RegisterSerializer, ProfileSerializer

from .models import OTP, UserProfile
from django.conf import settings
import random
import re
import urllib.request
import json
import requests

def format_e164_indian(phone_number: str) -> str:
    digits = re.sub(r'\D', '', phone_number)
    if len(digits) == 10:
        return f'+91{digits}'
    elif len(digits) == 12 and digits.startswith('91'):
        return f'+{digits}'
    return phone_number if phone_number.startswith('+') else f'+{digits}'

class SendOTPView(APIView):
    permission_classes = (permissions.AllowAny,)
    authentication_classes = ()
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

        # Send SMS via Twilio
        sms_sent = False
        sms_error = None
        account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', '')
        auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', '')
        messaging_service_sid = getattr(settings, 'TWILIO_MESSAGING_SERVICE_SID', '')

        if account_sid and auth_token and messaging_service_sid and account_sid != 'placeholder':
            try:
                to_number = format_e164_indian(phone_number)
                twilio_url = f"https://api.twilio.com/2010-04-01/Accounts/{account_sid}/Messages.json"
                resp = requests.post(
                    twilio_url,
                    data={
                        'To': to_number,
                        'MessagingServiceSid': messaging_service_sid,
                        'Body': f'Your GoAthlete verification OTP is {otp_code}. Valid for 10 minutes. 👋'
                    },
                    auth=(account_sid, auth_token),
                    timeout=10
                )
                if resp.status_code in (200, 201):
                    sms_sent = True
                else:
                    sms_error = resp.json().get('message', resp.text)
            except Exception as e:
                sms_error = str(e)

        return Response({
            'message': 'OTP sent successfully',
            'sms_sent': sms_sent,
            'sms_error': sms_error,
            'dev_otp': otp_code
        }, status=status.HTTP_200_OK)

class VerifyOTPView(APIView):
    permission_classes = (permissions.AllowAny,)
    authentication_classes = ()
    def post(self, request):
        phone_number = request.data.get('phone_number')
        otp_code = request.data.get('otp_code')

        if not phone_number or not otp_code:
            return Response({'error': 'Phone number and OTP are required'}, status=status.HTTP_400_BAD_REQUEST)

        pattern = re.compile(r'^(?:\+91|91)?[6789]\d{9}$')
        if not pattern.match(phone_number):
            return Response({'error': 'Invalid Indian phone number.'}, status=status.HTTP_400_BAD_REQUEST)

        otp_record = OTP.objects.filter(phone_number=phone_number, otp_code=otp_code, is_used=False).last()

        if not otp_record:
            return Response({'error': 'Invalid or expired OTP'}, status=status.HTTP_400_BAD_REQUEST)

        otp_record.is_used = True
        otp_record.save()

        profile = UserProfile.objects.filter(phone_number=phone_number).first()
        if profile:
            user = profile.user
            profile.is_phone_verified = True
            profile.save()
        else:
            user = User.objects.filter(username=phone_number).first()
            if not user:
                user = User.objects.create_user(username=phone_number)
                profile, _ = UserProfile.objects.get_or_create(user=user)
                profile.phone_number = phone_number
                profile.is_phone_verified = True
                profile.save()
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
    authentication_classes = ()
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

            valid_clients = {
                c for c in [
                    getattr(settings, 'GOOGLE_OAUTH_CLIENT_ID', ''),
                    getattr(settings, 'GOOGLE_ANDROID_CLIENT_ID', ''),
                ] if c and c != 'placeholder'
            }
            if valid_clients:
                aud = google_data.get('aud')
                azp = google_data.get('azp')
                if aud not in valid_clients and azp not in valid_clients:
                    return Response({'error': 'Token audience mismatch.'}, status=status.HTTP_400_BAD_REQUEST)
                
            email = google_data.get('email')
            if not email:
                return Response({'error': 'Email not provided by Google'}, status=status.HTTP_400_BAD_REQUEST)
                
            user = User.objects.filter(email=email).first()
            if not user:
                user = User.objects.create_user(username=email, email=email)
                user.first_name = google_data.get('given_name', '')
                user.last_name = google_data.get('family_name', '')
                user.save()
                profile, _ = UserProfile.objects.get_or_create(user=user)
                profile.is_phone_verified = False
                profile.save()
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
    authentication_classes = ()
    serializer_class = RegisterSerializer

class ProfileView(generics.RetrieveAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = ProfileSerializer

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
        
        primary_sport = request.data.get('primary_sport')
        skill_level = request.data.get('skill_level')
        bio = request.data.get('bio')
        
        if first_name:
            user.first_name = first_name
        if email:
            if User.objects.exclude(id=user.id).filter(email=email).exists():
                return Response({'error': 'Email is already in use.'}, status=status.HTTP_400_BAD_REQUEST)
            user.email = email
        user.save()
        
        if date_of_birth:
            from datetime import datetime
            try:
                dob_obj = datetime.strptime(date_of_birth, '%Y-%m-%d').date()
                if dob_obj >= datetime.today().date():
                    return Response({'error': 'Date of birth must be in the past.'}, status=status.HTTP_400_BAD_REQUEST)
                profile.date_of_birth = date_of_birth
            except ValueError:
                return Response({'error': 'Invalid date format. Use YYYY-MM-DD.'}, status=status.HTTP_400_BAD_REQUEST)
        if profile_picture:
            profile.profile_picture = profile_picture
        if primary_sport:
            profile.primary_sport = primary_sport
        if skill_level:
            profile.skill_level = skill_level
        if bio:
            profile.bio = bio
            
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
    permission_classes = [permissions.IsAdminUser]

    def get_queryset(self):
        return User.objects.filter(profile__role='EXECUTIVE')
        
    def dispatch(self, request, *args, **kwargs):
        print("DEBUG HEADER:", request.META.get('HTTP_AUTHORIZATION'))
        return super().dispatch(request, *args, **kwargs)
        
    def create(self, request, *args, **kwargs):
        print("DEBUG HEADER:", request.headers.get('Authorization'))
        print("DEBUG AUTH:", request.user, request.auth)
        return super().create(request, *args, **kwargs)

class UserLookupView(APIView):
    """
    Lookup users/athletes by GOATH-ID, phone number, or name for tournament/team/umpire assignment.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        query = request.query_params.get('q', '').strip()
        sport = request.query_params.get('sport', '').strip()
        from django.db.models import Q
        filters = (
            Q(goath_id__iexact=query) |
            Q(goath_id__icontains=query) |
            Q(phone_number__icontains=query) |
            Q(user__first_name__icontains=query) |
            Q(user__last_name__icontains=query) |
            Q(user__username__icontains=query)
        )

        profiles = UserProfile.objects.filter(filters).select_related('user')
        if sport:
            # Put athletes with matching primary_sport at the top
            profiles = sorted(
                profiles[:20], 
                key=lambda p: 0 if (p.primary_sport and sport.lower() in p.primary_sport.lower()) else 1
            )
        else:
            profiles = list(profiles[:20])

        results = []
        for p in profiles:
            name = f"{p.user.first_name} {p.user.last_name}".strip() or p.user.username
            masked_phone = f"{p.phone_number[:3]}****{p.phone_number[-3:]}" if p.phone_number and len(p.phone_number) >= 6 else p.phone_number
            results.append({
                'id': p.id,
                'user_id': p.user.id,
                'name': name,
                'goath_id': p.goath_id,
                'phone_number': masked_phone,
                'role': p.role,
                'primary_sport': p.primary_sport or 'Multi-Sport',
                'skill_level': p.skill_level or 5,
                'profile_picture': request.build_absolute_uri(p.profile_picture.url) if p.profile_picture else None,
            })
        return Response(results, status=status.HTTP_200_OK)

class ChangePasswordView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        user = request.user
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')

        if not old_password or not new_password:
            return Response({'error': 'Old password and new password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if not user.check_password(old_password):
            return Response({'error': 'Wrong old password.'}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()
        
        profile = getattr(user, 'profile', None)
        if profile:
            profile.requires_password_change = False
            profile.save()

        return Response({'message': 'Password changed successfully.'}, status=status.HTTP_200_OK)

