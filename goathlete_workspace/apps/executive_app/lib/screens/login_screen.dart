import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _otpSent = false;
  String? _devOtp;

  Future<void> _handleSendOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter phone number')));
      return;
    }

    if (!RegExp(r'^(?:\+91|91)?[6789]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit Indian phone number')));
      return;
    }

    final devOtp = await ref.read(authProvider.notifier).sendOTP(phone);
    if (devOtp != null) {
      setState(() {
        _otpSent = true;
        _devOtp = devOtp;
      });
      _otpController.text = devOtp;
    }
  }

  Future<void> _handleVerifyOTP() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (phone.isNotEmpty && otp.isNotEmpty) {
      final success = await ref.read(authProvider.notifier).verifyOTP(phone, otp);
      if (success && mounted) {
        // App's main router/listener will pick up isAuthenticated = true
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter OTP')),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: GoAthleteColors.athleticOrange),
              const SizedBox(height: 16),
              Text(
                'Executive Portal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Authorized Personnel Only',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Phone Number',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_otpSent,
                      decoration: const InputDecoration(
                        hintText: 'Enter phone number',
                      ),
                    ),
                    
                    if (_otpSent) ...[
                      const SizedBox(height: 16),
                      Text(
                        'OTP Code',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter OTP',
                        ),
                      ),
                      if (_devOtp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Dev Mode OTP: $_devOtp',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: GoAthleteColors.athleticOrange),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],

                    const SizedBox(height: 24),
                    
                    Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authProvider);
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (authState.error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ElevatedButton(
                              onPressed: authState.isLoading 
                                  ? null 
                                  : (_otpSent ? _handleVerifyOTP : _handleSendOTP),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
