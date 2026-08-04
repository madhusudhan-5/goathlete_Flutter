from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SportTemplateViewSet, TournamentViewSet, MatchViewSet, TeamViewSet

router = DefaultRouter()
router.register(r'sports', SportTemplateViewSet)
router.register(r'tournaments', TournamentViewSet)
router.register(r'matches', MatchViewSet)
router.register(r'teams', TeamViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
