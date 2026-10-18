import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_ui/core_ui.dart';
import '../../providers/tournament_provider.dart';

class ManageTournamentsScreen extends ConsumerWidget {
  const ManageTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(activeTournamentsProvider); 
    
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tournaments'), backgroundColor: GoAthleteColors.athleticOrange),
      body: tournamentsAsync.when(
        data: (tournaments) {
          if (tournaments.isEmpty) return const Center(child: Text('No tournaments found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final t = tournaments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name'] ?? 'Tournament', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        'Sport: ${t['sport_name'] ?? 'Sport'} • Format: ${t['tournament_rules']?['format'] ?? 'Knockout'} • ${t['teams_count'] ?? 0} Teams',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.groups, size: 16),
                              label: const Text('Teams & Squads'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: GoAthleteColors.athleticOrange,
                                side: const BorderSide(color: GoAthleteColors.athleticOrange),
                              ),
                              onPressed: () {
                                final tName = Uri.encodeComponent(t['name'] ?? 'Tournament');
                                context.push('/tournament-teams/${t['id']}?name=$tName');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.shuffle, size: 16),
                            label: const Text('Fixtures'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GoAthleteColors.deepNavy,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final message = await ref.read(tournamentProvider.notifier).generateFixtures(t['id']);
                              if (context.mounted) {
                                if (message != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
                                } else {
                                  final err = ref.read(tournamentProvider).error ?? 'Error';
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
