import requests

BASE_URL = 'http://127.0.0.1:8000/api'

# 1. Fetch Sports
try:
    print("Fetching sports...")
    resp = requests.get(f"{BASE_URL}/tournaments/sports/")
    resp.raise_for_status()
    sports = resp.json()
    print("Sports found:", len(sports))
    if not sports:
        print("No sports templates exist. Creating a temporary one...")
        # (Assuming we have a way to create one, but let's just abort for now)
        exit(1)
        
    sport_id = sports[0]['id']
    print(f"Using Sport ID: {sport_id}")
    
    # 2. Create Tournament
    payload = {
      'name': 'Test League 2026',
      'sport_template': sport_id,
      'start_date': '2026-10-01',
      'end_date': '2026-10-10',
      'location': 'Test Location',
      'tournament_rules': {
        'max_teams': 16,
        'entry_fee': '500',
        'format': 'Knockout',
        'umpire': 'Test Organizer',
      }
    }
    
    print("\nCreating tournament with payload:", payload)
    resp = requests.post(f"{BASE_URL}/tournaments/tournaments/", json=payload)
    print("Status Code:", resp.status_code)
    print("Response:", resp.text)
    
    if resp.status_code == 201:
        tournament_id = resp.json()['id']
        print(f"\nTournament created successfully with ID {tournament_id}!")
        
        # 3. Create Team
        team_payload = {'name': 'Test Strikers', 'tournament': tournament_id}
        print("Creating team:", team_payload)
        resp = requests.post(f"{BASE_URL}/tournaments/teams/", json=team_payload)
        print("Status Code:", resp.status_code)
        print("Response:", resp.text)
        
except Exception as e:
    print("Error:", e)
