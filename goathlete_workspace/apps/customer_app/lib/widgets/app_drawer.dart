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
    
    String? profilePicUrl;
    if (profileData?['profile_picture'] != null && profileData!['profile_picture'].toString().isNotEmpty) {
      profilePicUrl = profileData['profile_picture'].toString().startsWith('http') 
          ? profileData['profile_picture'] 
          : 'http://72.60.193.38${profileData['profile_picture']}';


    }

    return Drawer(
      backgroundColor: GoAthleteColors.deepNavy,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: GoAthleteColors.deepNavy),
            accountName: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(profileData?['primary_sport'] ?? 'Sport not set'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: GoAthleteColors.athleticOrange,
              backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
              child: profilePicUrl == null ? const Icon(Icons.person, size: 36, color: Colors.white) : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.group_add, color: GoAthleteColors.athleticOrange),
            title: const Text('Team Creation & Squads', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Create teams & add players', style: TextStyle(color: Colors.white60, fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              context.push('/create-team');
            },
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
            leading: const Icon(Icons.person, color: GoAthleteColors.athleticOrange),
            title: const Text('My Profile & Athlete Card', style: TextStyle(color: Colors.white)),
            subtitle: const Text('View GOATH-ID & personal stats', style: TextStyle(color: Colors.white60, fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile-details');
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
