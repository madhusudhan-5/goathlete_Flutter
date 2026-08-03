from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import UserSerializer, RegisterSerializer
from .models import OTP, UserProfile
import random

class SendOTPView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        phone_number = request.data.get('phone_number')
        if not phone_number:
            return Response({'error': 'Phone number is required'}, status=status.HTTP_400_BAD_REQUEST)

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
        }, status=status.HTTP_200_OK)


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

class ProfileView(generics.RetrieveAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

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
