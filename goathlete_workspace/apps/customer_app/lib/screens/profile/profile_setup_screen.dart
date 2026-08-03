import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'goath_id_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedSport;
  String? _selectedSkill;

  final List<String> _sports = ['Cricket', 'Football', 'Badminton', 'Basketball', 'Tennis'];
  final List<String> _skills = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];

  void _handleCompleteProfile() {
    if (_nameController.text.isNotEmpty && _selectedSport != null && _selectedSkill != null) {
      // Navigate to the ID generation screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GoathIdScreen(
            playerName: _nameController.text,
            primarySport: _selectedSport!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar Placeholder
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: GoAthleteColors.surfaceContainerHigh,
                    child: Icon(Icons.person, size: 50, color: GoAthleteColors.outlineVariant),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: GoAthleteColors.athleticOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Full Name', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'e.g. Virat Kohli'),
                  ),
                  const SizedBox(height: 24),

                  Text('Primary Sport', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _sports.map((sport) {
                      final isSelected = _selectedSport == sport;
                      return ChoiceChip(
                        label: Text(sport),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedSport = selected ? sport : null);
                        },
                        selectedColor: GoAthleteColors.athleticOrange.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? GoAthleteColors.athleticOrange : Theme.of(context).colorScheme.onSurface,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  Text('Skill Level', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSkill,
                    decoration: const InputDecoration(hintText: 'Select your level'),
                    items: _skills.map((skill) {
                      return DropdownMenuItem(value: skill, child: Text(skill));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSkill = value),
                  ),
                  const SizedBox(height: 24),

                  Text('Bio / Experience', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Tell tribes about your playing style...'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleCompleteProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: GoAthleteColors.deepNavy,
              ),
              child: const Text('Generate GOATH-ID', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
