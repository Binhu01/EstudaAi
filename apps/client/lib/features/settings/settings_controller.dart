import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_repository.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('Preferências não inicializadas.'),
);
final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  Future<void> _pending = Future.value();
  @override
  AppSettings build() =>
      SettingsRepository(ref.watch(preferencesProvider)).read();
  Future<void> update({ThemeMode? theme, bool? animate}) {
    final operation = _pending.then((_) async {
      if (!ref.mounted) return;
      final next = AppSettings(
        theme: theme ?? state.theme,
        animate: animate ?? state.animate,
      );
      await SettingsRepository(ref.read(preferencesProvider)).save(next);
      if (ref.mounted) state = next;
    });
    // A failed write is reported to its caller, without poisoning later edits.
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
