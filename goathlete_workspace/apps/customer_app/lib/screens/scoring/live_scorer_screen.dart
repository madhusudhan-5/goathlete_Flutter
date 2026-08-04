import 'dart:async';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

class LiveScorerScreen extends StatefulWidget {
  final String matchId;
  const LiveScorerScreen({super.key, required this.matchId});

  @override
  State<LiveScorerScreen> createState() => _LiveScorerScreenState();
}

class _LiveScorerScreenState extends State<LiveScorerScreen> {
  int teamAScore = 0;
  int teamBScore = 0;
  Timer? _pollingTimer;

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
    // Poll the backend every 5 seconds for MVP Live Scoring
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // TODO: Replace with actual HTTP GET /api/matches/${widget.matchId}/
      debugPrint("Polling match ${widget.matchId} for latest score...");
    });
  }
  
  void _logEvent(String eventName, bool isTeamA) {
    setState(() {
      if (isTeamA) teamAScore++;
      else teamBScore++;
    });
    
    // TODO: Send HTTP POST /api/matches/${widget.matchId}/events/
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$eventName recorded for ${isTeamA ? 'Team A' : 'Team B'}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Live Scorer'),
        backgroundColor: Colors.red[900], 
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeamScore('Team A', teamAScore),
                const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.grey)),
                _buildTeamScore('Team B', teamBScore),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: _buildEventColumn(true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildEventColumn(false)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTeamScore(String name, int score) {
    return Column(
      children: [
        Text(name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(score.toString(), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEventColumn(bool isTeamA) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          onPressed: () => _logEvent('Goal', isTeamA),
          child: const Text('GOAL'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700], foregroundColor: Colors.black, padding: const EdgeInsets.all(16)),
          onPressed: () => _logEvent('Yellow Card', isTeamA),
          child: const Text('YELLOW CARD'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          onPressed: () => _logEvent('Red Card', isTeamA),
          child: const Text('RED CARD'),
        ),
      ],
    );
  }
}
