from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import SportTemplate, Tournament, Match, MatchEvent
from .serializers import (
    SportTemplateSerializer, TournamentSerializer, 
    MatchSerializer, MatchEventSerializer
)

class SportTemplateViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = SportTemplate.objects.all()
    serializer_class = SportTemplateSerializer

class TournamentViewSet(viewsets.ModelViewSet):
    queryset = Tournament.objects.all()
    serializer_class = TournamentSerializer

    def perform_create(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        if profile:
            serializer.save(organizer=profile)
        else:
            serializer.save()

    @action(detail=True, methods=['post'])
    def generate_fixtures(self, request, pk=None):
        tournament = self.get_object()
        profile = getattr(request.user, 'profile', None)
        
        if tournament.organizer != profile:
            return Response({'error': 'Only the organizer can generate fixtures.'}, status=status.HTTP_403_FORBIDDEN)
            
        teams = tournament.teams.all()
        if len(teams) < 2:
            return Response({'error': 'At least 2 teams are required to generate fixtures.'}, status=status.HTTP_400_BAD_REQUEST)
            
        # Clear existing scheduled matches
        tournament.matches.filter(status='Scheduled').delete()
        
        format_type = tournament.tournament_rules.get('format', 'Knockout')
        from .utils import generate_round_robin, generate_knockout
        
        if format_type == 'League':
            matches_created = generate_round_robin(tournament, teams)
        else:
            matches_created = generate_knockout(tournament, teams)
            
        return Response({'message': f'Successfully created {matches_created} matches!'}, status=status.HTTP_200_OK)

class MatchViewSet(viewsets.ModelViewSet):
    queryset = Match.objects.all()
    serializer_class = MatchSerializer

    @action(detail=True, methods=['post'])
    def log_event(self, request, pk=None):
        match = self.get_object()
        # Ensure the match ID is injected into the data before validating
        data = request.data.copy()
        data['match'] = match.id
        serializer = MatchEventSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

from .models import Team, TournamentPlayer
from users.models import UserProfile
from .serializers import TeamSerializer

class TeamViewSet(viewsets.ModelViewSet):
    queryset = Team.objects.all()
    serializer_class = TeamSerializer

    def perform_create(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        team = serializer.save(captain=profile)
        if profile:
            TournamentPlayer.objects.create(team=team, player=profile)

    @action(detail=True, methods=['post'])
    def add_player(self, request, pk=None):
        team = self.get_object()
        goath_id = request.data.get('goath_id')
        if not goath_id:
            return Response({'error': 'goath_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            player = UserProfile.objects.get(goath_id=goath_id)
        except UserProfile.DoesNotExist:
            return Response({'error': 'Player not found'}, status=status.HTTP_404_NOT_FOUND)
            
        if TournamentPlayer.objects.filter(team=team, player=player).exists():
            return Response({'error': 'Player already in team'}, status=status.HTTP_400_BAD_REQUEST)
            
        TournamentPlayer.objects.create(team=team, player=player)
        return Response({'message': 'Player added successfully', 'player_name': player.user.first_name}, status=status.HTTP_200_OK)
