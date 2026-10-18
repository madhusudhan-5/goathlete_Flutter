import datetime
from django.utils import timezone
from .models import Match

def distribute_dates(start_date, end_date, total_matches):
    if total_matches <= 0:
        return []
    
    if isinstance(start_date, str):
        start_date = datetime.date.fromisoformat(start_date)
    if isinstance(end_date, str):
        end_date = datetime.date.fromisoformat(end_date)

    if not start_date:
        start_date = timezone.now().date()
    if not end_date:
        end_date = start_date

    # Convert dates to datetime to do arithmetic, default to 10:00 AM
    start_dt = timezone.make_aware(datetime.datetime.combine(start_date, datetime.time(10, 0)))
    end_dt = timezone.make_aware(datetime.datetime.combine(end_date, datetime.time(18, 0)))

    delta = end_dt - start_dt
    if total_matches <= 1 or delta.total_seconds() <= 0:
        return [start_dt] * total_matches
        
    step = delta / (total_matches - 1)
    return [start_dt + step * i for i in range(total_matches)]

def generate_round_robin(tournament, teams):
    matches = []
    team_list = list(teams)
    n = len(team_list)
    if n < 2:
        return 0

    total_matches = n * (n - 1) // 2
    dates = distribute_dates(tournament.start_date, tournament.end_date, total_matches)
    
    date_index = 0
    for i in range(n):
        for j in range(i + 1, n):
            if Match.objects.filter(tournament=tournament, team_a=team_list[i], team_b=team_list[j]).exists() or \
               Match.objects.filter(tournament=tournament, team_a=team_list[j], team_b=team_list[i]).exists():
                continue
            match_dt = dates[date_index] if dates and date_index < len(dates) else timezone.now()
            match = Match(
                tournament=tournament,
                team_a=team_list[i],
                team_b=team_list[j],
                match_date=match_dt,
                umpire=tournament.default_umpire
            )
            matches.append(match)
            date_index += 1
            
    Match.objects.bulk_create(matches)
    return len(matches)

def generate_knockout(tournament, teams):
    import math
    import random
    
    team_list = list(teams)
    n = len(team_list)
    if n < 2:
        return 0
        
    next_power_of_2 = 2 ** math.ceil(math.log2(n))
    byes = next_power_of_2 - n
    first_round_matches = (n - byes) // 2
    
    teams_playing_r1 = team_list[byes:]
    
    dates = distribute_dates(tournament.start_date, tournament.end_date, max(first_round_matches, 1))
    
    matches = []
    date_index = 0
    for i in range(0, len(teams_playing_r1), 2):
        if i + 1 < len(teams_playing_r1):
            team_a = teams_playing_r1[i]
            team_b = teams_playing_r1[i+1]
            if Match.objects.filter(tournament=tournament, team_a=team_a, team_b=team_b).exists() or \
               Match.objects.filter(tournament=tournament, team_a=team_b, team_b=team_a).exists():
                continue
            match_dt = dates[date_index] if dates and date_index < len(dates) else timezone.now()
            match = Match(
                tournament=tournament,
                team_a=team_a,
                team_b=team_b,
                match_date=match_dt,
                umpire=tournament.default_umpire
            )
            matches.append(match)
            if dates and date_index < len(dates) - 1:
                date_index += 1
            
    Match.objects.bulk_create(matches)
    return len(matches)

