import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: UnifiedAdminConsoleApp()));
}

class UnifiedAdminConsoleApp extends StatelessWidget {
  const UnifiedAdminConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GoAthlete Admin & Partner Portal',
      debugShowCheckedModeBanner: false,
      theme: GoAthleteTheme.lightTheme,
      darkTheme: GoAthleteTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
