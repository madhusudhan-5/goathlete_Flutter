from django.db import models
from users.models import UserProfile

class SportTemplate(models.Model):
    name = models.CharField(max_length=100, unique=True) # e.g., Cricket, Badminton
    min_players_per_team = models.PositiveIntegerField()
    max_players_per_team = models.PositiveIntegerField()
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name

class Tournament(models.Model):
    name = models.CharField(max_length=200)
    sport_template = models.ForeignKey(SportTemplate, on_delete=models.CASCADE)
    start_date = models.DateField()
    end_date = models.DateField()
    location = models.CharField(max_length=200)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name

class Team(models.Model):
    name = models.CharField(max_length=100)
    tournament = models.ForeignKey(Tournament, on_delete=models.CASCADE, related_name='teams')
    captain = models.ForeignKey(UserProfile, on_delete=models.SET_NULL, null=True, related_name='captained_teams')
    
    def __str__(self):
        return f"{self.name} - {self.tournament.name}"

class TournamentPlayer(models.Model):
    team = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='players')
    player = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='tournament_participations')
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('team', 'player')

    def __str__(self):
        return f"{self.player.goath_id} in {self.team.name}"

class Match(models.Model):
    tournament = models.ForeignKey(Tournament, on_delete=models.CASCADE, related_name='matches')
    team_a = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='matches_as_a')
    team_b = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='matches_as_b')
    match_date = models.DateTimeField()
    status = models.CharField(max_length=50, choices=[('Scheduled', 'Scheduled'), ('Ongoing', 'Ongoing'), ('Completed', 'Completed')], default='Scheduled')
    winner = models.ForeignKey(Team, on_delete=models.SET_NULL, null=True, blank=True, related_name='matches_won')

    def __str__(self):
        return f"{self.team_a.name} vs {self.team_b.name}"

class PlayerStat(models.Model):
    match = models.ForeignKey(Match, on_delete=models.CASCADE, related_name='player_stats')
    player = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    stats = models.JSONField(default=dict, help_text="Sport specific stats, e.g. {'runs': 50, 'wickets': 2}")
    awards = models.CharField(max_length=200, blank=True, help_text="e.g. Man of the Match, Orange Cap")

    def __str__(self):
        return f"Stats for {self.player.goath_id} in Match {self.match.id}"
