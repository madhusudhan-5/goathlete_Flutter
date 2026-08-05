import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:core_ui/core_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';

class GoathIdScreen extends ConsumerStatefulWidget {
  final String playerName;
  final String primarySport;

  const GoathIdScreen({
    super.key,
    required this.playerName,
    required this.primarySport,
  });

  @override
  ConsumerState<GoathIdScreen> createState() => _GoathIdScreenState();
}

class _GoathIdScreenState extends ConsumerState<GoathIdScreen> {
  void _navigateToDashboard() {
    context.go('/explore');
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final goathId = profileState.value?['goath_id'] ?? 'Loading...';
    return Scaffold(
      backgroundColor: GoAthleteColors.deepNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to the Tribe!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your player profile is ready.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Player ID Card
              GlassContainer(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Text(
                      widget.playerName.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.primarySport.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GoAthleteColors.athleticOrange),
                    ),
                    const SizedBox(height: 32),
                    
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: goathId,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'YOUR GOATH-ID',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      goathId,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        letterSpacing: 1.5,
                        color: GoAthleteColors.deepNavy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _navigateToDashboard,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: GoAthleteColors.athleticOrange,
                ),
                child: const Text('Enter Dashboard', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
