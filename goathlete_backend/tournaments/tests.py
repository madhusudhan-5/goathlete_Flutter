from django.test import TestCase
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from users.models import UserProfile
from tournaments.models import SportTemplate

class TournamentTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='org', password='password')
        self.profile = self.user.profile
        self.sport = SportTemplate.objects.create(name='Cricket', min_players_per_team=11, max_players_per_team=15)
        self.client.force_authenticate(user=self.user)

    def test_negative_fees_streamlined(self):
        data = {
            'name': 'Test Tourney',
            'sport_template': self.sport.id,
            'start_date': '2025-01-01',
            'team_names': ['Team A', 'Team B'],
            'player_fee': -500
        }
        response = self.client.post('/api/tournaments/tournaments/create_streamlined/', data, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('cannot be negative', response.data['error'])
