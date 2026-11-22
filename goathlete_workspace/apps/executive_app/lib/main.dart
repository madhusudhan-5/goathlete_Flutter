import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/dashboard/executive_dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: ExecutiveApp()));
}

class ExecutiveApp extends StatelessWidget {
  const ExecutiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoAthlete Executive',
      theme: GoAthleteTheme.lightTheme,
      darkTheme: GoAthleteTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(
        nextScreen: _ExecutiveAuthGate(),
      ),
    );
  }
}

class _ExecutiveAuthGate extends ConsumerWidget {
  const _ExecutiveAuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }
    if (authState.requiresPasswordChange) {
      return const ChangePasswordScreen();
    }
    return const ExecutiveDashboardScreen();
  }
}
