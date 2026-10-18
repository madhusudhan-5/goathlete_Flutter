import re

with open('goathlete_workspace/apps/customer_app/lib/screens/scoring/live_scorer_screen.dart', 'r') as f:
    content = f.read()

# We want to replace ref.invalidate(singleMatchProvider(widget.matchId)); 
# with the invalidations, but ONLY inside functions that have `match` defined.

replacement = """ref.invalidate(singleMatchProvider(widget.matchId));
      ref.invalidate(activeTournamentsProvider);
      final tid = match['tournament'];
      if (tid != null) ref.invalidate(tournamentMatchesProvider(tid is int ? tid : int.tryParse(tid.toString()) ?? 0));"""

content = content.replace("ref.invalidate(singleMatchProvider(widget.matchId));", replacement)

# Except in _startPolling
content = content.replace(replacement + "\n      }", "ref.invalidate(singleMatchProvider(widget.matchId));\n      }")

with open('goathlete_workspace/apps/customer_app/lib/screens/scoring/live_scorer_screen.dart', 'w') as f:
    f.write(content)

