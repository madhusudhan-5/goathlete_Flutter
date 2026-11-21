import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'router.dart';
import 'providers/theme_provider.dart';
import 'widgets/mobile_tablet_gate.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GoAthleteCustomerApp(),
    ),
  );
}

class GoAthleteCustomerApp extends ConsumerWidget {
  const GoAthleteCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isAllowedWebDevice()) {
      return MaterialApp(
        title: 'GoAthlete',
        theme: GoAthleteTheme.darkTheme,
        home: const DesktopBlockedScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'GoAthlete Customer',
      theme: GoAthleteTheme.lightTheme,
      darkTheme: GoAthleteTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
