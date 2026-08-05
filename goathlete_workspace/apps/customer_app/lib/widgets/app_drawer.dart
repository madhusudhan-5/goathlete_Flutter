import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(profileProvider);
    final profileData = profileAsyncValue.value;
    final firstName = profileData?['first_name'];
    final displayName = (firstName != null && firstName.isNotEmpty) ? firstName : 'Athlete';
    
    String profilePicUrl = 'https://i.pravatar.cc/100';
    if (profileData?['profile_picture'] != null) {
      profilePicUrl = profileData!['profile_picture'].toString().startsWith('http') 
          ? profileData['profile_picture'] 
          : 'http://192.168.1.218:8000${profileData['profile_picture']}';
    }

    return Drawer(
      backgroundColor: GoAthleteColors.deepNavy,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: GoAthleteColors.navy),
            accountName: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(profileData?['primary_sport'] ?? 'Sport not set'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage(profilePicUrl),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: GoAthleteColors.athleticOrange),
            title: const Text('Manage Tournaments', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              context.push('/manage-tournaments');
            },
          ),
          ListTile(
            leading: const Icon(Icons.scoreboard, color: GoAthleteColors.athleticOrange),
            title: const Text('Live Scores', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // MVP Demo Route
              context.push('/live-scorer/1'); 
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.white70),
            title: const Text('Close Menu', style: TextStyle(color: Colors.white70)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
