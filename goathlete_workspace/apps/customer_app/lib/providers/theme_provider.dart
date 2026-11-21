import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_storage.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    const storage = AppStorage();
    final theme = await storage.read(key: 'theme_mode');
    if (theme == 'dark') {
      state = ThemeMode.dark;
    } else if (theme == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    const storage = AppStorage();
    await storage.write(key: 'theme_mode', value: isDark ? 'dark' : 'light');
  }
}
