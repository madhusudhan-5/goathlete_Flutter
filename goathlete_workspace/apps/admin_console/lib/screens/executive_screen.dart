import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../providers/admin_provider.dart';

class ExecutiveManagementScreen extends ConsumerWidget {
  const ExecutiveManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execsAsync = ref.watch(executivesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Management'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: execsAsync.when(
        data: (execs) {
          if (execs.isEmpty) {
            return const Center(child: Text('No executives found.'));
          }
          return ListView.builder(
            itemCount: execs.length,
            itemBuilder: (context, index) {
              final exec = execs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('${exec['first_name']} ${exec['last_name']}'),
                  subtitle: Text('ID: ${exec['goath_id']} | Phone: ${exec['phone_number']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () {
                      // Edit executive flow
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add new executive flow
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Executive'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
    );
  }
}
