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
    organizer_name = serializers.SerializerMethodField()
    default_umpire_name = serializers.SerializerMethodField()
    teams_count = serializers.SerializerMethodField()
    matches_count = serializers.SerializerMethodField()
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

    class Meta:
        model = Team
        fields = '__all__'

    def get_captain_name(self, obj):
        if obj.captain:
            return f"{obj.captain.user.first_name} {obj.captain.user.last_name}".strip() or obj.captain.user.username
        return None

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

