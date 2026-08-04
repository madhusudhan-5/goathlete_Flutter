import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                child: ListTile(
                  title: Text(t['name']),
                  subtitle: Text('Format: ${t['tournament_rules']?['format'] ?? 'Knockout'}'),
                  trailing: ElevatedButton(
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
                    child: const Text('Generate Fixtures'),
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
