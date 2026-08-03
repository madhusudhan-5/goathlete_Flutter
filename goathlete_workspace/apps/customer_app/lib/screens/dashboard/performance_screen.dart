import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('My Performance'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
        children: [
          // Stat Overview
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Matches', '42', Icons.sports)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Win Rate', '68%', Icons.emoji_events)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'MVPs', '12', Icons.star)),
            ],
          ),
          const SizedBox(height: 24),

          // GOATH-ID Card
          Text('My GOATH-ID', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Level: Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GoAthleteColors.athleticOrange)),
                    Icon(Icons.qr_code_2, size: 40, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: GoAthleteColors.athleticOrange,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('700 XP', style: Theme.of(context).textTheme.bodySmall),
                    Text('1000 XP to Master', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent Activity
          Text('Recent Matches', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          _buildMatchHistoryItem(context, 'Won against Team Alpha', 'Football • 3-1', true),
          _buildMatchHistoryItem(context, 'Lost against Smashers', 'Badminton • 1-2', false),
          _buildMatchHistoryItem(context, 'Won against Local Kings', 'Cricket • by 5 wkts', true),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: GoAthleteColors.athleticOrange, size: 28),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryItem(BuildContext context, String title, String subtitle, bool isWin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: isWin ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            child: Icon(
              isWin ? Icons.arrow_upward : Icons.arrow_downward,
              color: isWin ? Colors.green : Colors.red,
            ),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          trailing: Text(
            isWin ? '+20 XP' : '+5 XP',
            style: TextStyle(
              color: isWin ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
