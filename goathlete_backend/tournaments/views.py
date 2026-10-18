from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction
from .models import SportTemplate, Tournament, Match, MatchEvent, Team, TournamentPlayer
from users.models import UserProfile
from .serializers import (
    SportTemplateSerializer, TournamentSerializer, 
    MatchSerializer, MatchEventSerializer, TeamSerializer
)

class SportTemplateViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = SportTemplate.objects.all().prefetch_related('events')
    serializer_class = SportTemplateSerializer

class TournamentViewSet(viewsets.ModelViewSet):
    queryset = Tournament.objects.all().order_by("-id").select_related('sport_template', 'organizer', 'default_umpire').prefetch_related('teams', 'matches')
    serializer_class = TournamentSerializer

    def perform_create(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        umpire_goath_id = self.request.data.get('umpire_goath_id')
        default_umpire = None
        if umpire_goath_id:
            default_umpire = UserProfile.objects.filter(goath_id=umpire_goath_id).first()
        
        serializer.save(
            organizer=profile,
            default_umpire=default_umpire or profile
        )

    @action(detail=False, methods=['post'])
    def create_streamlined(self, request):
        """
        Creates a Tournament, registers teams, assigns default umpire, and auto-generates fixtures in 1 atomic step.
        """
        profile = getattr(request.user, 'profile', None)
        data = request.data
        name = data.get('name')
        sport_template_id = data.get('sport_template')
        start_date = data.get('start_date')
        end_date = data.get('end_date') or start_date
        location = data.get('location', 'Sports Arena')
        venue_id = data.get('venue_id')
        team_names = data.get('team_names', [])
        umpire_goath_id = data.get('umpire_goath_id')
        format_type = data.get('format', 'Knockout')
        try:
            player_fee = float(data.get('player_fee', 0))
            team_fee = float(data.get('team_fee', 0))
            visitor_fee = float(data.get('visitor_fee', 0))
            prize_pool = float(data.get('prize_pool', 0))
        except ValueError:
            return Response({'error': 'Fees and prize pool must be numeric.'}, status=status.HTTP_400_BAD_REQUEST)

        if player_fee < 0 or team_fee < 0 or visitor_fee < 0 or prize_pool < 0:
            return Response({'error': 'Fees and prize pool cannot be negative.'}, status=status.HTTP_400_BAD_REQUEST)

        if not name or not sport_template_id or not start_date:
            return Response({'error': 'Name, sport_template, and start_date are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if len(team_names) < 2:
            return Response({'error': 'At least 2 teams are required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            sport = SportTemplate.objects.get(id=sport_template_id)
        except SportTemplate.DoesNotExist:
            return Response({'error': 'Invalid sport template'}, status=status.HTTP_404_NOT_FOUND)

        default_umpire = None
        if umpire_goath_id:
            default_umpire = UserProfile.objects.filter(goath_id=umpire_goath_id).first()
        if not default_umpire:
            default_umpire = profile

        with transaction.atomic():
            tournament = Tournament.objects.create(
                name=name,
                organizer=profile,
                default_umpire=default_umpire,
                sport_template=sport,
                start_date=start_date,
                end_date=end_date,
                location=location,
                venue_id=venue_id,
                tournament_rules={
                    'format': format_type,
                    'player_fee': float(player_fee or 0),
                    'team_fee': float(team_fee or 0),
                    'visitor_fee': float(visitor_fee or 0),
                    'prize_pool': float(prize_pool or 0),
                }
            )


            created_teams = []
            for t_name in team_names:
                t = Team.objects.create(
                    name=t_name.strip(),
                    tournament=tournament,
                    captain=profile
                )
                created_teams.append(t)

            from .utils import generate_round_robin, generate_knockout
            if str(format_type).lower() in ['league', 'round-robin', 'round robin', 'roundrobin']:
                matches_created = generate_round_robin(tournament, created_teams)
            else:
                matches_created = generate_knockout(tournament, created_teams)

            # Assign default umpire to all generated matches
            if default_umpire:
                tournament.matches.update(umpire=default_umpire)

        serializer = TournamentSerializer(tournament)
        return Response({
            'message': f'Tournament created with {len(created_teams)} teams and {matches_created} matches scheduled!',
            'tournament': serializer.data
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def complete_tournament(self, request, pk=None):
        tournament = self.get_object()
        profile = getattr(request.user, 'profile', None)
        
        if tournament.organizer != profile and not request.user.is_superuser:
            return Response({'error': 'Only the tournament organizer can complete the tournament.'}, status=status.HTTP_403_FORBIDDEN)
            
        tournament.status = 'Completed'
        tournament.save()
        return Response({'message': 'Tournament marked as completed.'}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def generate_fixtures(self, request, pk=None):
        tournament = self.get_object()
        profile = getattr(request.user, 'profile', None)
        
        if tournament.organizer and tournament.organizer != profile and not request.user.is_superuser:
            return Response({'error': 'Only the tournament organizer can generate fixtures.'}, status=status.HTTP_403_FORBIDDEN)
            
        teams = tournament.teams.all()
        if len(teams) < 2:
            return Response({'error': 'At least 2 teams are required to generate fixtures.'}, status=status.HTTP_400_BAD_REQUEST)
            
        # Delete only scheduled matches (preserve completed or ongoing matches if any)
        tournament.matches.filter(status='Scheduled').delete()
        
        format_type = (tournament.tournament_rules or {}).get('format', 'Knockout')
        from .utils import generate_round_robin, generate_knockout
        
        if str(format_type).lower() in ['league', 'round-robin', 'round robin', 'roundrobin']:
            matches_created = generate_round_robin(tournament, teams)
        else:
            matches_created = generate_knockout(tournament, teams)

        if tournament.default_umpire:
            tournament.matches.filter(umpire__isnull=True).update(umpire=tournament.default_umpire)
            
        return Response({'message': f'Successfully generated {matches_created} match fixtures!'}, status=status.HTTP_200_OK)


    @action(detail=True, methods=['post'])
    def set_umpire(self, request, pk=None):
        tournament = self.get_object()
        goath_id = request.data.get('goath_id')
        phone_number = request.data.get('phone_number')
        
        umpire = None
        if goath_id:
            umpire = UserProfile.objects.filter(goath_id=goath_id).first()
        elif phone_number:
            umpire = UserProfile.objects.filter(phone_number=phone_number).first()
            
        if not umpire:
            return Response({'error': 'Official/Umpire user not found with provided ID or phone.'}, status=status.HTTP_404_NOT_FOUND)
            
        tournament.default_umpire = umpire
        tournament.save()
        tournament.matches.filter(status='Scheduled', umpire__isnull=True).update(umpire=umpire)
        
        return Response({
            'message': f'Official Umpire / Scoreboard Manager updated to {umpire.user.first_name or umpire.user.username}',
            'default_umpire_name': f"{umpire.user.first_name} {umpire.user.last_name}".strip() or umpire.user.username,
            'default_umpire_goath_id': umpire.goath_id
        }, status=status.HTTP_200_OK)


class MatchViewSet(viewsets.ModelViewSet):
    queryset = Match.objects.all().select_related('tournament', 'team_a', 'team_b', 'umpire', 'winner').prefetch_related('events')
    serializer_class = MatchSerializer

    def _is_authorized_scorer(self, match, user):
        profile = getattr(user, 'profile', None)
        if not profile:
            return False
        # Match umpire, tournament default umpire, or tournament organizer can edit
        return (
            match.umpire == profile or
            match.tournament.default_umpire == profile or
            match.tournament.organizer == profile or
            user.is_superuser
        )

    @action(detail=True, methods=['post'])
    def start_match(self, request, pk=None):
        match = self.get_object()
        if not self._is_authorized_scorer(match, request.user):
            return Response({'error': 'Permission denied. Only assigned umpire or tournament organizer can start the match.'}, status=status.HTTP_403_FORBIDDEN)

        sport_template = match.tournament.sport_template
        min_players = sport_template.min_players_per_team
        max_players = sport_template.max_players_per_team

        team_a_size = match.team_a.players.count()
        if team_a_size < min_players or (max_players and team_a_size > max_players):
            pass
            # return Response({'error': f'Team {match.team_a.name} roster size {team_a_size} does not meet requirements ({min_players}-{max_players}).'}, status=status.HTTP_400_BAD_REQUEST)
            
        team_b_size = match.team_b.players.count()
        if team_b_size < min_players or (max_players and team_b_size > max_players):
            pass
            # return Response({'error': f'Team {match.team_b.name} roster size {team_b_size} does not meet requirements ({min_players}-{max_players}).'}, status=status.HTTP_400_BAD_REQUEST)

        match.status = 'Ongoing'
        if not match.current_score:
            match.current_score = {
                'team_a_score': 0,
                'team_b_score': 0,
                'status_text': 'Match Started',
                'team_a_stats': {},
                'team_b_stats': {},
            }
        match.save()
        return Response(MatchSerializer(match).data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def update_score(self, request, pk=None):
        match = self.get_object()
        if not self._is_authorized_scorer(match, request.user):
            return Response({'error': 'Permission denied. Only assigned umpire or tournament organizer can edit score.'}, status=status.HTTP_403_FORBIDDEN)

        data = request.data
        if 'current_score' in data:
            match.current_score = data['current_score']
        if 'status' in data:
            match.status = data['status']
        if 'winner_id' in data:
            match.winner_id = data['winner_id']

        match.save()
        return Response(MatchSerializer(match).data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def log_event(self, request, pk=None):
        match = self.get_object()
        if not self._is_authorized_scorer(match, request.user):
            return Response({'error': 'Permission denied. Only assigned umpire can log events.'}, status=status.HTTP_403_FORBIDDEN)

        if match.status != 'Ongoing':
            return Response({'error': 'Events can only be logged for ongoing matches.'}, status=status.HTTP_400_BAD_REQUEST)

        data = request.data.copy()
        data['match'] = match.id
        
        try:
            team_id = int(data.get('team', 0))
        except ValueError:
            return Response({'error': 'Team ID must be an integer.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if team_id not in [match.team_a_id, match.team_b_id]:
            return Response({'error': 'Team must be part of the match.'}, status=status.HTTP_400_BAD_REQUEST)

        serializer = MatchEventSerializer(data=data)
        if serializer.is_valid():
            event = serializer.save()

            # Auto-aggregate current_score based on event point value
            score = match.current_score or {'team_a_score': 0, 'team_b_score': 0}
            points = event.sport_event.points_value or 1

            if team_id == match.team_a_id:
                score['team_a_score'] = score.get('team_a_score', 0) + points
            elif team_id == match.team_b_id:
                score['team_b_score'] = score.get('team_b_score', 0) + points

            score['last_event'] = f"{event.sport_event.name} by {event.team.name}"
            match.current_score = score
            match.save()

            return Response({
                'event': serializer.data,
                'current_score': match.current_score
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def assign_umpire(self, request, pk=None):
        match = self.get_object()
        profile = getattr(request.user, 'profile', None)
        if match.tournament.organizer != profile and not request.user.is_superuser:
            return Response({'error': 'Only tournament organizer can assign umpires.'}, status=status.HTTP_403_FORBIDDEN)

        goath_id = request.data.get('goath_id')
        if not goath_id:
            return Response({'error': 'goath_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        umpire_profile = UserProfile.objects.filter(goath_id=goath_id).first()
        if not umpire_profile:
            return Response({'error': 'User with given GOATH-ID not found'}, status=status.HTTP_404_NOT_FOUND)

        match.umpire = umpire_profile
        match.save()
        return Response({'message': f'Umpire {umpire_profile.user.first_name} assigned successfully.'}, status=status.HTTP_200_OK)


class TeamViewSet(viewsets.ModelViewSet):
    queryset = Team.objects.all().select_related('tournament', 'captain').prefetch_related('players__player__user')
    serializer_class = TeamSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        tournament_id = self.request.query_params.get('tournament')
        if tournament_id:
            qs = qs.filter(tournament_id=tournament_id)
        return qs

    def perform_create(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        team = serializer.save(captain=profile)
        if profile:
            TournamentPlayer.objects.create(team=team, player=profile)

    @action(detail=True, methods=['post'])
    def add_player(self, request, pk=None):
        team = self.get_object()
        profile = getattr(request.user, 'profile', None)
        
        if team.captain != profile and (not team.tournament or team.tournament.organizer != profile) and not request.user.is_superuser:
            return Response({'error': 'Only team captain or tournament organizer can modify the roster.'}, status=status.HTTP_403_FORBIDDEN)
        
        # Disallow player modifications if tournament match fixtures have already been scheduled
        if team.tournament and Match.objects.filter(tournament=team.tournament).exists():
            return Response({
                'error': 'Roster is locked. Cannot add players after match fixtures are scheduled.'
            }, status=status.HTTP_400_BAD_REQUEST)

        goath_id = request.data.get('goath_id')
        phone_number = request.data.get('phone_number')
        
        player = None
        if goath_id:
            player = UserProfile.objects.filter(goath_id=goath_id).first()
        elif phone_number:
            player = UserProfile.objects.filter(phone_number=phone_number).first()
            
        if not player:
            return Response({'error': 'Player not found with provided ID or phone'}, status=status.HTTP_404_NOT_FOUND)
            
        if TournamentPlayer.objects.filter(team=team, player=player).exists():
            return Response({'error': 'Player already in team'}, status=status.HTTP_400_BAD_REQUEST)
            
        TournamentPlayer.objects.create(team=team, player=player)
        return Response({
            'message': 'Player added successfully',
            'player_name': f"{player.user.first_name} {player.user.last_name}".strip() or player.user.username,
            'goath_id': player.goath_id,
            'phone_number': player.phone_number
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def set_captain(self, request, pk=None):
        team = self.get_object()
        profile = getattr(request.user, 'profile', None)
        
        if team.captain != profile and (not team.tournament or team.tournament.organizer != profile) and not request.user.is_superuser:
            return Response({'error': 'Only team captain or tournament organizer can modify the roster.'}, status=status.HTTP_403_FORBIDDEN)
            
        goath_id = request.data.get('goath_id')
        player_id = request.data.get('player_id')
        
        player = None
        if goath_id:
            player = UserProfile.objects.filter(goath_id=goath_id).first()
        elif player_id:
            player = UserProfile.objects.filter(id=player_id).first()
            
        if not player:
            return Response({'error': 'Player not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Ensure player is in the team
        if not TournamentPlayer.objects.filter(team=team, player=player).exists():
            TournamentPlayer.objects.create(team=team, player=player)
            
        team.captain = player
        team.save()
        return Response({
            'message': f'Captain updated to {player.user.first_name or player.user.username}',
            'captain_name': f"{player.user.first_name} {player.user.last_name}".strip() or player.user.username,
            'captain_goath_id': player.goath_id
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def remove_player(self, request, pk=None):
        team = self.get_object()
        profile = getattr(request.user, 'profile', None)
        
        if team.captain != profile and (not team.tournament or team.tournament.organizer != profile) and not request.user.is_superuser:
            return Response({'error': 'Only team captain or tournament organizer can modify the roster.'}, status=status.HTTP_403_FORBIDDEN)

        # Disallow player modifications if tournament match fixtures have already been scheduled
        if team.tournament and Match.objects.filter(tournament=team.tournament).exists():
            return Response({
                'error': 'Roster is locked. Cannot remove players after match fixtures are scheduled.'
            }, status=status.HTTP_400_BAD_REQUEST)

        goath_id = request.data.get('goath_id')
        player_id = request.data.get('player_id')
        if goath_id:
            TournamentPlayer.objects.filter(team=team, player__goath_id=goath_id).delete()
        elif player_id:
            TournamentPlayer.objects.filter(team=team, player_id=player_id).delete()
        return Response({'message': 'Player removed from team'}, status=status.HTTP_200_OK)



