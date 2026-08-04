from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework.routers import DefaultRouter
from .views import RegisterView, ProfileView, SendOTPView, VerifyOTPView, ExecutiveViewSet, GoogleLoginView, ProfileUpdateView

router = DefaultRouter()
router.register(r'executives', ExecutiveViewSet, basename='executive')

urlpatterns = [
    path('', include(router.urls)),
    path('login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('login/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', RegisterView.as_view(), name='auth_register'),
    path('profile/', ProfileView.as_view(), name='user_profile'),
    path('profile/update/', ProfileUpdateView.as_view(), name='profile_update'),
    path('send-otp/', SendOTPView.as_view(), name='send_otp'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify_otp'),
    path('google-login/', GoogleLoginView.as_view(), name='google_login'),
]
