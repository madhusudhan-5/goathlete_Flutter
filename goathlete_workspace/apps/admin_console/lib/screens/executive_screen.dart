import 'package:admin_console/network/api_client.dart';
import 'package:admin_console/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import '../providers/admin_provider.dart';

class ExecutiveManagementScreen extends ConsumerWidget {
  final bool showAppBar;
  const ExecutiveManagementScreen({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execsAsync = ref.watch(executivesProvider);

    final content = execsAsync.when(
      data: (execs) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Field Executive Roster', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Manage on-ground field executives and onboarding credentials.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddExecutiveDialog(context, ref);
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Executive'),
                    style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (execs.isEmpty)
                const Expanded(
                  child: Center(child: Text('No field executives registered yet.')),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: execs.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final exec = execs[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: GoAthleteColors.athleticOrange.withValues(alpha: 0.15),
                            child: const Icon(Icons.person, color: GoAthleteColors.athleticOrange),
                          ),
                          title: Text('${exec['first_name'] ?? ''} ${exec['last_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ID: ${exec['goath_id'] ?? 'N/A'} • Phone: ${exec['phone_number'] ?? 'N/A'} • Email: ${exec['email'] ?? 'N/A'}'),
                          trailing: Switch(
                            value: exec['is_active'] == true,
                            activeColor: Colors.green,
                            onChanged: (val) async {
                              try {
                                final dio = ref.read(dioProvider);
                                await dio.patch('users/executives/${exec['id']}/', data: {'is_active': val});
                                ref.invalidate(executivesProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );

    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Executive Management'), backgroundColor: GoAthleteColors.athleticOrange),
        body: content,
      );
    }
    return content;
  }

  void _showAddExecutiveDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Field Executive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                final parts = nameCtrl.text.split(' ');
                final firstName = parts.isNotEmpty ? parts[0] : '';
                final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                
                await dio.post('users/executives/', data: {
                  'first_name': firstName,
                  'last_name': lastName,
                  'username': emailCtrl.text,
                  'email': emailCtrl.text,
                  'profile': {
                    'phone_number': phoneCtrl.text
                  }
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Executive registered successfully! Password is Test@12345 by default.')));
                }
                ref.invalidate(executivesProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: GoAthleteColors.athleticOrange, foregroundColor: Colors.white),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}
