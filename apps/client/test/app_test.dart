import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/settings/settings_controller.dart';

Future<void> openApp(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({'animate': false});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
      child: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: const EstudaAiApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(360, 800), const Size(1440, 1000)]) {
    testWidgets('home and theme navigation remain usable at ${size.width}', (
      tester,
    ) async {
      await openApp(tester, size: size);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      expect(find.text('Minha jornada'), findsOneWidget);
      expect(
        Localizations.localeOf(tester.element(find.text('Minha jornada'))),
        const Locale('pt', 'BR'),
      );
      expect(find.text('Nenhuma meta por aqui, ainda'), findsOneWidget);
      await tester.tap(find.text('Preferências').first);
      await tester.pumpAndSettle();
      expect(find.text('Aparência'), findsOneWidget);
      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Aparência'))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('large text does not overflow and shader has a motion toggle', (
    tester,
  ) async {
    await openApp(tester, scale: 2);
    expect(
      MediaQuery.textScalerOf(tester.element(find.text('Minha jornada')))
          .scale(10),
      20,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Preferências').first);
    await tester.pumpAndSettle();
    expect(find.text('Animação de fundo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
