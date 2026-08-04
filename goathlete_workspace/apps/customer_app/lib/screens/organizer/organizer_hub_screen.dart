import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

import 'package:go_router/go_router.dart';

class OrganizerHubScreen extends StatelessWidget {
  const OrganizerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Organizer Hub'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildActionCard(
            context,
            'Create Tournament',
            'Start a new tournament, define sports rules, and invite teams.',
            Icons.add_chart,
            () {
              context.push('/create-tournament');
            }
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            'Manage Tournaments',
            'View active tournaments, approve teams, and generate fixtures.',
            Icons.settings,
            () {
              context.push('/manage-tournaments');
            }
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            'Live Scorer Mode',
            'Select an ongoing match to start live scoring.',
            Icons.sports_score,
            () {
              // Navigate to match selector
            }
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GoAthleteColors.athleticOrange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: GoAthleteColors.athleticOrange),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
