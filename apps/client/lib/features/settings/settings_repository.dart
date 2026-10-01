import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({this.theme = ThemeMode.system, this.animate = true});
  final ThemeMode theme;
  final bool animate;
}

class SettingsRepository {
  const SettingsRepository(this.preferences);
  final SharedPreferences preferences;
  AppSettings read() {
    final storedTheme = preferences.get('theme');
    final storedMotion = preferences.get('animate');
    return AppSettings(
      theme:
          ThemeMode.values
              .where((theme) => theme.name == storedTheme)
              .firstOrNull ??
          ThemeMode.system,
      animate: storedMotion is bool ? storedMotion : true,
    );
  }

  Future<void> save(AppSettings value) async {
    final themeSaved = await preferences.setString('theme', value.theme.name);
    final motionSaved = await preferences.setBool('animate', value.animate);
    if (!themeSaved || !motionSaved) {
      throw StateError('Não foi possível salvar as preferências.');
    }
  }
}
