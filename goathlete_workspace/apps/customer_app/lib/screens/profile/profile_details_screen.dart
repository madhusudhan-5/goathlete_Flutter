import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileDetailsScreen extends ConsumerWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
                  ),
                  const SizedBox(height: 16),
                  Text('Virat Kohli', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('+91 9876543210', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSettingsGroup(context, 'Account', [
              _buildSettingsTile(context, Icons.person_outline, 'Personal Information'),
              _buildSettingsTile(context, Icons.payment, 'Payment Methods'),
              _buildSettingsTile(context, Icons.qr_code, 'My GOATH-ID', onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Your GOATH-ID'),
                    content: const Text('GOATH-ABCD1234567890\n\nShare this ID with friends so they can add you to teams and tournaments!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: const Text('Close')
                      )
                    ],
                  )
                );
              }),
            ]),
            const SizedBox(height: 24),
            _buildSettingsGroup(context, 'Preferences', [
              _buildSettingsTile(context, Icons.notifications_none, 'Notifications'),
              _buildSettingsTile(context, Icons.language, 'Language'),
              _buildSettingsTile(
                context, 
                Icons.dark_mode_outlined, 
                'Dark Mode', 
                isSwitch: true, 
                switchValue: isDark,
                onSwitchChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme(val);
                }
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsGroup(context, 'Support', [
              _buildSettingsTile(context, Icons.help_outline, 'Help Center'),
              _buildSettingsTile(context, Icons.description_outlined, 'Terms of Service'),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Log Out'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: GoAthleteColors.athleticOrange)),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, {bool isSwitch = false, bool switchValue = false, Function(bool)? onSwitchChanged, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: isSwitch
          ? Switch(
              value: switchValue,
              onChanged: onSwitchChanged,
              activeColor: GoAthleteColors.athleticOrange,
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: isSwitch ? null : (onTap ?? () {}),
    );
  }
}
