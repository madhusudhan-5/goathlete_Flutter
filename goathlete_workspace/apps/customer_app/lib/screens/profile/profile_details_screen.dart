import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  void _showEditProfileModal(BuildContext context, Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileModal(profileData: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    final profileAsyncValue = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        elevation: 0,
      ),
      body: profileAsyncValue.when(
        data: (profile) {
          final firstName = profile['first_name'] ?? '';
          final lastName = profile['last_name'] ?? '';
          final fullName = '$firstName $lastName'.trim();
          final phone = profile['phone_number'] ?? '';
          final goathId = profile['goath_id'] ?? '';
          final profilePicUrl = profile['profile_picture'] != null 
              ? (profile['profile_picture'].toString().startsWith('http')
                  ? profile['profile_picture']
                  : 'http://192.168.1.218:8000${profile['profile_picture']}') 
              : 'https://i.pravatar.cc/150';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(profilePicUrl),
                      ),
                      const SizedBox(height: 16),
                      Text(fullName.isNotEmpty ? fullName : 'GoAthlete User', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(phone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showEditProfileModal(context, profile),
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
              _buildSettingsTile(context, Icons.person_outline, 'Personal Information', onTap: () => _showEditProfileModal(context, profile)),
              _buildSettingsTile(context, Icons.payment, 'Payment Methods'),
              _buildSettingsTile(context, Icons.qr_code, 'My GOATH-ID', onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Your GOATH-ID', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SizedBox(
                              width: 200,
                              height: 200,
                              child: QrImageView(
                                data: goathId.isNotEmpty ? goathId : 'UNKNOWN',
                                version: QrVersions.auto,
                                size: 200.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            goathId.isNotEmpty ? goathId : 'Not assigned',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('Have your captain scan this code to add you to their team roster!', textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context), 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GoAthleteColors.athleticOrange,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Close', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                );
              }),
            ]),
            const SizedBox(height: 24),
            _buildSettingsGroup(context, 'Sports Profile', [
              _buildSettingsTile(context, Icons.sports_baseball_outlined, 'Primary Sport: ${profile['primary_sport'] ?? 'Not set'}'),
              _buildSettingsTile(context, Icons.star_border, 'Skill Level: ${profile['skill_level'] ?? 'Not set'}'),
              _buildSettingsTile(context, Icons.article_outlined, 'Bio: ${profile['bio'] != null && profile['bio'].toString().isNotEmpty ? profile['bio'] : 'Not set'}'),
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
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, stack) => Center(child: Text('Error: $e')),
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

class EditProfileModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> profileData;
  const EditProfileModal({super.key, required this.profileData});

  @override
  ConsumerState<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<EditProfileModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _goathIdController;
  late final TextEditingController _sportController;
  late final TextEditingController _skillController;
  late final TextEditingController _bioController;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.profileData;
    _nameController = TextEditingController(text: p['first_name'] ?? '');
    _dobController = TextEditingController(text: p['date_of_birth'] ?? '');
    _phoneController = TextEditingController(text: p['phone_number'] ?? '');
    _emailController = TextEditingController(text: p['email'] ?? '');
    _goathIdController = TextEditingController(text: p['goath_id'] ?? '');
    _sportController = TextEditingController(text: p['primary_sport'] ?? '');
    _skillController = TextEditingController(text: p['skill_level'] ?? '');
    _bioController = TextEditingController(text: p['bio'] ?? '');
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _saveProfile() async {
    final success = await ref.read(authProvider.notifier).updateProfileWithImage(
      firstName: _nameController.text,
      dob: _dobController.text,
      imagePath: _imageFile?.path,
      primarySport: _sportController.text,
      skillLevel: _skillController.text,
      bio: _bioController.text,
    );
    
    if (success && mounted) {
      ref.invalidate(profileProvider);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Profile', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null 
                        ? FileImage(_imageFile!) as ImageProvider
                        : (widget.profileData['profile_picture'] != null 
                            ? NetworkImage(widget.profileData['profile_picture'].toString().startsWith('http') ? widget.profileData['profile_picture'] : 'http://192.168.1.218:8000${widget.profileData['profile_picture']}')
                            : const NetworkImage('https://i.pravatar.cc/150')),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: GoAthleteColors.athleticOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dobController,
              decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sportController,
              decoration: const InputDecoration(labelText: 'Primary Sport'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _skillController,
              decoration: const InputDecoration(labelText: 'Skill Level'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              enabled: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
              enabled: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _goathIdController,
              decoration: const InputDecoration(labelText: 'GOATH-ID'),
              enabled: false,
            ),
            const SizedBox(height: 24),
            if (authState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(authState.error!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GoAthleteColors.athleticOrange,
                  foregroundColor: Colors.white,
                ),
                child: authState.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
