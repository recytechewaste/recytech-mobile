import 'package:flutter/material.dart';

import '../storage/secure_storage.dart';
import 'recytechtheme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({SecureStorage? storage})
      : _storage = storage ?? SecureStorage();

  final SecureStorage _storage;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    try {
      final isDark = await _storage.readDarkMode();
      _apply(isDark ?? false, notify: false);
    } catch (_) {
      _apply(false, notify: false);
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    if (enabled == isDarkMode) return;
    _apply(enabled);
    await _storage.saveDarkMode(enabled);
  }

  void _apply(bool enabled, {bool notify = true}) {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    RecyTechTheme.setDarkMode(enabled);
    if (notify) notifyListeners();
  }
}
