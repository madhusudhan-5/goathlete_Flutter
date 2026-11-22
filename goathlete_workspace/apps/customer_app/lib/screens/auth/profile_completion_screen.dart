import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../network/api_client.dart';
import '../../providers/auth_provider.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dob;

  bool _isLoadingInitial = true;
  bool _emailLocked = false;
  bool _phoneLocked = false;

  @override
  void initState() {
    super.initState();
    _prefillProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _prefillProfile() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('users/profile/');
      if (!mounted) return;
      final data = response.data;
      if (data is Map) {
        final firstName = (data['first_name'] ?? '').toString().trim();
        final lastName = (data['last_name'] ?? '').toString().trim();
        final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
        final email = (data['email'] ?? '').toString().trim();
        final phone = (data['phone_number'] ?? '').toString().trim();
        final dobRaw = (data['date_of_birth'] ?? '').toString().trim();

        setState(() {
          if (fullName.isNotEmpty) _nameController.text = fullName;
          if (email.isNotEmpty) {
            _emailController.text = email;
            _emailLocked = true;
          }
          if (phone.isNotEmpty) {
            _phoneController.text = phone;
            _phoneLocked = true;
          }
          if (dobRaw.isNotEmpty) {
            _dob = DateTime.tryParse(dobRaw);
          }
          _isLoadingInitial = false;
        });
        return;
      }
    } catch (_) {
      // Fallback to empty editable fields if profile fetch fails.
    }
    if (mounted) {
      setState(() => _isLoadingInitial = false);
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _submitProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your name, email, phone number, and date of birth')),
      );
      return;
    }

    if (!RegExp(r'^(?:\+91|91)?[6789]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit Indian phone number')),
      );
      return;
    }

    final dobStr = _formatDate(_dob!);

    final goathId = await ref.read(authProvider.notifier).completeProfile(
      name,
      email,
      dobStr,
      phoneNumber: phone,
    );

    if (goathId != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Welcome to GoAthlete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your unique GoAthlete ID is:'),
              const SizedBox(height: 16),
              Text(
                goathId,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: GoAthleteColors.athleticOrange,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text('Use this ID across all sports, academies, and tournaments.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/explore');
              },
              child: const Text('Let\'s Go!'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: GoAthleteColors.athleticOrange,
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('We just need a few more details to create your universal sports identity.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    readOnly: _emailLocked,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      suffixIcon: _emailLocked
                          ? const Icon(Icons.verified, color: Colors.green, size: 20)
                          : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    readOnly: _phoneLocked,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '10-digit mobile number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      suffixIcon: _phoneLocked
                          ? const Icon(Icons.verified, color: Colors.green, size: 20)
                          : null,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.cake_outlined),
                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(
                        _dob == null ? 'Tap to select date of birth' : _formatDate(_dob!),
                        style: TextStyle(
                          color: _dob == null
                              ? Theme.of(context).hintColor
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (authState.error != null) ...[
                    Text(authState.error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _submitProfile,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Complete Registration'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
