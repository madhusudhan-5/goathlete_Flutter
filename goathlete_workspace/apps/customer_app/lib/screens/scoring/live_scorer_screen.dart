import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/profile_provider.dart';

class LiveScorerScreen extends ConsumerStatefulWidget {
  final String matchId;
  const LiveScorerScreen({super.key, required this.matchId});

  @override
  ConsumerState<LiveScorerScreen> createState() => _LiveScorerScreenState();
}

class _LiveScorerScreenState extends ConsumerState<LiveScorerScreen> {
  Timer? _pollingTimer;
  Map<String, dynamic>? _liveScore;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      ref.refresh(singleMatchProvider(widget.matchId));
    });
  }

  void _logEventAction(Map<String, dynamic> match, int eventId, int teamId, String eventName, int points) async {
    setState(() => _isActionLoading = true);
    final result = await ref.read(tournamentProvider.notifier).logEvent(
      matchId: widget.matchId,
      sportEventId: eventId,
      teamId: teamId,
    );
    setState(() => _isActionLoading = false);

    if (result != null) {
      ref.refresh(singleMatchProvider(widget.matchId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$eventName (+${points} pts) recorded!'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    }
  }

  void _manualScoreUpdate(Map<String, dynamic> match, bool isTeamA, int delta) async {
    final currentScore = Map<String, dynamic>.from(match['current_score'] ?? {'team_a_score': 0, 'team_b_score': 0});
    final key = isTeamA ? 'team_a_score' : 'team_b_score';
    final newScore = ((currentScore[key] as num?)?.toInt() ?? 0) + delta;
    if (newScore < 0) return;
    currentScore[key] = newScore;

    setState(() => _isActionLoading = true);
    final success = await ref.read(tournamentProvider.notifier).updateScore(widget.matchId, currentScore);
    setState(() => _isActionLoading = false);

    if (success) {
      ref.refresh(singleMatchProvider(widget.matchId));
    }
  }

  void _startMatch() async {
    setState(() => _isActionLoading = true);
    final success = await ref.read(tournamentProvider.notifier).startMatch(widget.matchId);
    setState(() => _isActionLoading = false);
    if (success) {
      ref.refresh(singleMatchProvider(widget.matchId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match is now LIVE!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _completeMatch(Map<String, dynamic> match) async {
    final teamAId = match['team_a'];
    final teamBId = match['team_b'];
    final teamAName = match['team_a_name'] ?? 'Team A';
    final teamBName = match['team_b_name'] ?? 'Team B';

    final winnerId = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Match & Declare Winner'),
        content: const Text('Select the winning team to finalize the result:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, teamAId),
            child: Text(teamAName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, teamBId),
            child: Text(teamBName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (winnerId != null) {
      setState(() => _isActionLoading = true);
      final success = await ref.read(tournamentProvider.notifier).updateScore(
        widget.matchId,
        match['current_score'] ?? {},
        status: 'Completed',
        winnerId: winnerId,
      );
      setState(() => _isActionLoading = false);
      if (success) {
        ref.refresh(singleMatchProvider(widget.matchId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match Completed & Winner Declared!'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(singleMatchProvider(widget.matchId));
    final profile = ref.watch(profileProvider).value;
    final sportsAsync = ref.watch(sportsProvider);

    return matchAsync.when(
      data: (match) {
        final myGoathId = profile?['goath_id'];
        final myProfileId = profile?['id'];
        final umpireGoathId = match['umpire_goath_id'];
        final organizerId = match['organizer_id'];

        final isUmpire = (umpireGoathId != null && umpireGoathId == myGoathId) ||
            (organizerId != null && organizerId == myProfileId);

        final teamAName = match['team_a_name'] ?? 'Team A';
        final teamBName = match['team_b_name'] ?? 'Team B';
        final teamAId = match['team_a'];
        final teamBId = match['team_b'];
        final currentScore = match['current_score'] ?? {};
        final teamAScore = currentScore['team_a_score'] ?? 0;
        final teamBScore = currentScore['team_b_score'] ?? 0;
        final matchStatus = match['status'] ?? 'Scheduled';
        final sportName = match['sport_name'] ?? 'Match';
        final umpireName = match['umpire_name'] ?? 'Official';
        final events = (match['events'] as List<dynamic>?) ?? [];

        // Find sport events for quick actions
        final sportData = sportsAsync.value?.firstWhere(
          (s) => s['name'] == sportName,
          orElse: () => null,
        );
        final sportEvents = (sportData?['events'] as List<dynamic>?) ?? [];

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sportName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  isUmpire ? '⚡ Official Umpire Mode' : '👀 Live Spectator View',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: isUmpire ? Colors.red[900] : GoAthleteColors.deepNavy,
            foregroundColor: Colors.white,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: matchStatus == 'Ongoing'
                      ? Colors.green
                      : (matchStatus == 'Completed' ? Colors.grey : Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  matchStatus.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Live Broadcast Score Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [GoAthleteColors.deepNavy, Colors.blueGrey.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Team A
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(Icons.shield, color: Colors.amber, size: 36),
                                const SizedBox(height: 6),
                                Text(
                                  teamAName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$teamAScore',
                                  style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('VS', style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          // Team B
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(Icons.shield, color: Colors.lightBlueAccent, size: 36),
                                const SizedBox(height: 6),
                                Text(
                                  teamBName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$teamBScore',
                                  style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Official: $umpireName • ${currentScore['last_event'] ?? (matchStatus == 'Ongoing' ? 'Match Live' : 'Scheduled')}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Control Mode (Umpire vs Spectator)
                if (isUmpire) ...[
                  // Umpire Quick Action Controls
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (matchStatus == 'Scheduled') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isActionLoading ? null : _startMatch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('▶ Start Match & Live Scoring', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (matchStatus == 'Ongoing') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Umpire Scoring Pad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              OutlinedButton.icon(
                                onPressed: _isActionLoading ? null : () => _completeMatch(match),
                                icon: const Icon(Icons.flag, size: 16, color: Colors.red),
                                label: const Text('End Match', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Quick increment/decrement buttons for both teams
                          Row(
                            children: [
                              // Team A controls
                              Expanded(
                                child: Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        Text(teamAName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                              onPressed: () => _manualScoreUpdate(match, true, -1),
                                            ),
                                            Text('$teamAScore', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle, color: Colors.green),
                                              onPressed: () => _manualScoreUpdate(match, true, 1),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Team B controls
                              Expanded(
                                child: Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        Text(teamBName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                              onPressed: () => _manualScoreUpdate(match, false, -1),
                                            ),
                                            Text('$teamBScore', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle, color: Colors.green),
                                              onPressed: () => _manualScoreUpdate(match, false, 1),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Sport specific 1-tap event triggers
                          const Text('Log Match Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          if (sportEvents.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sportEvents.map((ev) {
                                return PopupMenuButton<int>(
                                  tooltip: 'Record ${ev['name']}',
                                  child: Chip(
                                    backgroundColor: ev['category'] == 'OUT'
                                        ? Colors.red[100]
                                        : (ev['category'] == 'SCORING' ? Colors.green[100] : Colors.blue[100]),
                                    avatar: const Icon(Icons.touch_app, size: 16),
                                    label: Text('${ev['name']} (${ev['points_value']}p)'),
                                  ),
                                  onSelected: (teamId) {
                                    _logEventAction(
                                      match,
                                      ev['id'],
                                      teamId,
                                      ev['name'],
                                      ev['points_value'] ?? 1,
                                    );
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(value: teamAId, child: Text('For $teamAName')),
                                    PopupMenuItem(value: teamBId, child: Text('For $teamBName')),
                                  ],
                                );
                              }).toList(),
                            ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  // Read-Only Spectator / Player Info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.blue.shade50,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.visibility, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Viewing live broadcast. Scores update automatically every 4 seconds. Officiated by $umpireName.',
                                style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // 3. Match Events Feed
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent Match Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      if (events.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('No events recorded yet. Match is in progress.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: events.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final ev = events[idx] as Map<String, dynamic>;
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: GoAthleteColors.athleticOrange,
                                radius: 14,
                                child: Icon(Icons.sports_score, size: 14, color: Colors.white),
                              ),
                              title: Text(ev['event_name'] ?? 'Event', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(ev['team_name'] ?? ''),
                              trailing: Text('${ev['match_minute'] ?? 0}\''),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading match: $e'))),
    );
  }
}
