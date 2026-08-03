from django.contrib import admin
from .models import SportTemplate, Tournament, Team, TournamentPlayer, Match, PlayerStat

@admin.register(SportTemplate)
class SportTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'min_players_per_team', 'max_players_per_team', 'is_active')

@admin.register(Tournament)
class TournamentAdmin(admin.ModelAdmin):
    list_display = ('name', 'sport_template', 'start_date', 'location', 'is_active')

@admin.register(Team)
class TeamAdmin(admin.ModelAdmin):
    list_display = ('name', 'tournament', 'captain')

@admin.register(TournamentPlayer)
class TournamentPlayerAdmin(admin.ModelAdmin):
    list_display = ('player', 'team', 'joined_at')
    search_fields = ('player__goath_id', 'player__user__username')

@admin.register(Match)
class MatchAdmin(admin.ModelAdmin):
    list_display = ('id', 'team_a', 'team_b', 'match_date', 'status', 'winner')

@admin.register(PlayerStat)
class PlayerStatAdmin(admin.ModelAdmin):
    list_display = ('player', 'match', 'awards')
