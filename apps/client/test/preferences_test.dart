import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:estuda_ai/features/settings/settings_controller.dart';
import 'package:estuda_ai/features/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('preferences survive reopening the repository', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SettingsRepository(prefs);
    await store.save(
      const AppSettings(
        theme: ThemeMode.dark,
        animate: false,
        readingTextSize: ReadingTextSize.extraLarge,
        readingComfortableSpacing: true,
      ),
    );
    final reopened = SettingsRepository(prefs).read();
    expect(reopened.theme, ThemeMode.dark);
    expect(reopened.animate, false);
    expect(reopened.readingTextSize, ReadingTextSize.extraLarge);
    expect(reopened.readingComfortableSpacing, true);
  });
  test('corrupted preferences recover to safe defaults', () async {
    SharedPreferences.setMockInitialValues({
      'theme': 21,
      'animate': 'no',
      'readingTextSize': 'unknown',
      'readingComfortableSpacing': 'more',
    });
    final settings = SettingsRepository(await SharedPreferences.getInstance())
        .read();
    expect(settings.theme, ThemeMode.system);
    expect(settings.animate, true);
    expect(settings.readingTextSize, ReadingTextSize.standard);
    expect(settings.readingComfortableSpacing, false);
  });
  test('simultaneous preference changes preserve both choices', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final controller = container.read(settingsProvider.notifier);
    await Future.wait([
      controller.update(theme: ThemeMode.dark),
      controller.update(animate: false),
      controller.update(readingTextSize: ReadingTextSize.large),
      controller.update(readingComfortableSpacing: true),
    ]);
    expect(container.read(settingsProvider).theme, ThemeMode.dark);
    expect(container.read(settingsProvider).animate, false);
    expect(
      container.read(settingsProvider).readingTextSize,
      ReadingTextSize.large,
    );
    expect(container.read(settingsProvider).readingComfortableSpacing, true);
    final persisted = SettingsRepository(prefs).read();
    expect(persisted.theme, ThemeMode.dark);
    expect(persisted.animate, false);
    expect(persisted.readingTextSize, ReadingTextSize.large);
    expect(persisted.readingComfortableSpacing, true);
  });
}
