import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/venue_onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard/executive_dashboard_screen.dart';
import 'providers/venue_provider.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: ExecutiveApp()));
}

class ExecutiveApp extends ConsumerWidget {
  const ExecutiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'GoAthlete Executive',
      theme: GoAthleteTheme.lightTheme,
      darkTheme: GoAthleteTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: authState.isAuthenticated ? const ExecutiveDashboardScreen() : const LoginScreen(),
    );
  }
}

