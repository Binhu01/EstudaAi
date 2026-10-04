import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReadingTextSize { standard, large, extraLarge }

class AppSettings {
  const AppSettings({
    this.theme = ThemeMode.system,
    this.animate = true,
    this.readingTextSize = ReadingTextSize.standard,
    this.readingComfortableSpacing = false,
  });
  final ThemeMode theme;
  final bool animate;
  final ReadingTextSize readingTextSize;
  final bool readingComfortableSpacing;
}

class SettingsRepository {
  const SettingsRepository(this.preferences);
  final SharedPreferences preferences;
  AppSettings read() {
    final storedTheme = preferences.get('theme');
    final storedMotion = preferences.get('animate');
    final storedReadingSize = preferences.get('readingTextSize');
    final storedReadingSpacing = preferences.get('readingComfortableSpacing');
    return AppSettings(
      theme:
          ThemeMode.values
              .where((theme) => theme.name == storedTheme)
              .firstOrNull ??
          ThemeMode.system,
      animate: storedMotion is bool ? storedMotion : true,
      readingTextSize:
          ReadingTextSize.values
              .where((size) => size.name == storedReadingSize)
              .firstOrNull ??
          ReadingTextSize.standard,
      readingComfortableSpacing: storedReadingSpacing is bool
          ? storedReadingSpacing
          : false,
    );
  }

  Future<void> save(AppSettings value) async {
    final themeSaved = await preferences.setString('theme', value.theme.name);
    final motionSaved = await preferences.setBool('animate', value.animate);
    final readingSizeSaved = await preferences.setString(
      'readingTextSize',
      value.readingTextSize.name,
    );
    final readingSpacingSaved = await preferences.setBool(
      'readingComfortableSpacing',
      value.readingComfortableSpacing,
    );
    if (!themeSaved ||
        !motionSaved ||
        !readingSizeSaved ||
        !readingSpacingSaved) {
      throw StateError('Não foi possível salvar as preferências.');
    }
  }
}
