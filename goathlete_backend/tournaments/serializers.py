from rest_framework import serializers
from .models import SportTemplate, SportEvent, Tournament, Team, TournamentPlayer, Match, MatchEvent

class SportEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = SportEvent
        fields = '__all__'

class SportTemplateSerializer(serializers.ModelSerializer):
    events = SportEventSerializer(many=True, read_only=True)
    class Meta:
        model = SportTemplate
        fields = '__all__'

class TournamentSerializer(serializers.ModelSerializer):
    sport_name = serializers.CharField(source='sport_template.name', read_only=True)
    min_players_per_team = serializers.IntegerField(source='sport_template.min_players_per_team', read_only=True)
    max_players_per_team = serializers.IntegerField(source='sport_template.max_players_per_team', read_only=True)
    organizer_name = serializers.SerializerMethodField()
    default_umpire_name = serializers.SerializerMethodField()
    teams_count = serializers.SerializerMethodField()
    matches_count = serializers.SerializerMethodField()
    total_player_capacity = serializers.SerializerMethodField()
    joined_players_count = serializers.SerializerMethodField()
    available_player_slots = serializers.SerializerMethodField()
    my_joined_team = serializers.SerializerMethodField()
    entry_fee = serializers.SerializerMethodField()
    player_fee = serializers.SerializerMethodField()
    team_fee = serializers.SerializerMethodField()
    visitor_fee = serializers.SerializerMethodField()
    prize_pool = serializers.SerializerMethodField()

    class Meta:
        model = Tournament
        fields = '__all__'

    def get_organizer_name(self, obj):
        if obj.organizer:
            return f"{obj.organizer.user.first_name} {obj.organizer.user.last_name}".strip() or obj.organizer.user.username
        return "Unknown"

    def get_default_umpire_name(self, obj):
        if obj.default_umpire:
            return f"{obj.default_umpire.user.first_name} {obj.default_umpire.user.last_name}".strip() or obj.default_umpire.user.username
        return None

    def get_teams_count(self, obj):
        return obj.teams.count()

    def get_matches_count(self, obj):
        return obj.matches.count()

    def get_total_player_capacity(self, obj):
        max_per_team = obj.sport_template.max_players_per_team or 11
        return obj.teams.count() * max_per_team

    def get_joined_players_count(self, obj):
        return TournamentPlayer.objects.filter(team__tournament=obj).count()

    def get_available_player_slots(self, obj):
        total = self.get_total_player_capacity(obj)
        joined = self.get_joined_players_count(obj)
        return max(0, total - joined)

    def get_my_joined_team(self, obj):
        request = self.context.get('request')
        if request and hasattr(request, 'user') and request.user.is_authenticated:
            profile = getattr(request.user, 'profile', None)
            if profile:
                tp = TournamentPlayer.objects.filter(team__tournament=obj, player=profile).select_related('team').first()
                if tp:
                    return {
                        'team_id': tp.team.id,
                        'team_name': tp.team.name,
                        'payment_status': tp.payment_status,
                        'fee_paid': float(tp.fee_paid),
                        'joined_at': tp.joined_at.isoformat() if tp.joined_at else None,
                    }
        return None

    def get_entry_fee(self, obj):
        rules = obj.tournament_rules or {}
        team_fee = rules.get('team_fee', 0)
        player_fee = rules.get('player_fee', 0)
        if team_fee and float(team_fee) > 0:
            return f"₹{int(float(team_fee))}/Team"
        if player_fee and float(player_fee) > 0:
            return f"₹{int(float(player_fee))}/Player"
        return "Free"

    def get_player_fee(self, obj):
        return (obj.tournament_rules or {}).get('player_fee', 0)

    def get_team_fee(self, obj):
        return (obj.tournament_rules or {}).get('team_fee', 0)

    def get_visitor_fee(self, obj):
        return (obj.tournament_rules or {}).get('visitor_fee', 0)

    def get_prize_pool(self, obj):
        return (obj.tournament_rules or {}).get('prize_pool', 0)


    def validate(self, data):
        if data.get('start_date') and data.get('end_date'):
            if data['start_date'] > data['end_date']:
                raise serializers.ValidationError({"end_date": "End date must be after start date."})
        return data

class TournamentPlayerSerializer(serializers.ModelSerializer):
    player_name = serializers.SerializerMethodField()
    goath_id = serializers.CharField(source='player.goath_id', read_only=True)
    phone_number = serializers.CharField(source='player.phone_number', read_only=True)

    class Meta:
        model = TournamentPlayer
        fields = '__all__'

    def get_player_name(self, obj):
        return f"{obj.player.user.first_name} {obj.player.user.last_name}".strip() or obj.player.user.username

class TeamSerializer(serializers.ModelSerializer):
    tournament = serializers.PrimaryKeyRelatedField(queryset=Tournament.objects.all(), required=False, allow_null=True)
    captain_name = serializers.SerializerMethodField()
    players = TournamentPlayerSerializer(many=True, read_only=True)
    players_count = serializers.SerializerMethodField()
    max_players = serializers.SerializerMethodField()
    available_slots = serializers.SerializerMethodField()

    class Meta:
        model = Team
        fields = '__all__'

    def get_captain_name(self, obj):
        if obj.captain:
            return f"{obj.captain.user.first_name} {obj.captain.user.last_name}".strip() or obj.captain.user.username
        return None

    def get_players_count(self, obj):
        return obj.players.count()

    def get_max_players(self, obj):
        if obj.tournament and obj.tournament.sport_template:
            return obj.tournament.sport_template.max_players_per_team or 11
        return 11

    def get_available_slots(self, obj):
        return max(0, self.get_max_players(obj) - self.get_players_count(obj))

class MatchSerializer(serializers.ModelSerializer):
    team_a_name = serializers.CharField(source='team_a.name', read_only=True)
    team_b_name = serializers.CharField(source='team_b.name', read_only=True)
    winner_name = serializers.CharField(source='winner.name', read_only=True)
    sport_name = serializers.CharField(source='tournament.sport_template.name', read_only=True)
    umpire_name = serializers.SerializerMethodField()
    umpire_goath_id = serializers.CharField(source='umpire.goath_id', read_only=True)
    organizer_id = serializers.IntegerField(source='tournament.organizer.id', read_only=True)
    
    class Meta:
        model = Match
        fields = '__all__'

    def get_umpire_name(self, obj):
        if obj.umpire:
            return f"{obj.umpire.user.first_name} {obj.umpire.user.last_name}".strip() or obj.umpire.user.username
        if obj.tournament.default_umpire:
            return f"{obj.tournament.default_umpire.user.first_name} {obj.tournament.default_umpire.user.last_name}".strip() or obj.tournament.default_umpire.user.username
        return None

class MatchEventSerializer(serializers.ModelSerializer):
    event_name = serializers.CharField(source='sport_event.name', read_only=True)
    team_name = serializers.CharField(source='team.name', read_only=True)
    player_name = serializers.SerializerMethodField()

    class Meta:
        model = MatchEvent
        fields = '__all__'

    def get_player_name(self, obj):
        if obj.player:
            return f"{obj.player.user.first_name} {obj.player.user.last_name}".strip() or obj.player.user.username
        return None

