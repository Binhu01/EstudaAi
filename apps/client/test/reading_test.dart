import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/contests/contest_models.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';
import 'package:estuda_ai/features/settings/settings_controller.dart';

import 'app_test.dart' show openApp;

void main() {
  testWidgets(
    'reading controls enlarge prose and persist without replacing system scaling',
    (tester) async {
      await openApp(tester, scale: 2);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      container
          .read(routerProvider)
          .go('/concursos/bb2026/financeira/bb2026-f07/material');
      await tester.pumpAndSettle();
      final text = container
          .read(contestCatalogProvider)
          .requireValue
          .find('bb2026-f07')!
          .module
          .blocks
          .whereType<TextBlock>()
          .first
          .text;
      final prose = find.widgetWithText(SelectableText, text);
      final before = tester.widget<SelectableText>(prose).style!;
      expect(find.text('Tamanho do texto'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Maior'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Maior'));
      await tester.pumpAndSettle();
      final after = tester.widget<SelectableText>(prose).style!;
      expect(after.fontSize, greaterThan(before.fontSize!));
      expect(after.fontFamily, 'Poppins');
      expect(MediaQuery.textScalerOf(tester.element(prose)).scale(10), 20);
      await tester.ensureVisible(find.text('Mais espaço entre linhas'));
      await tester.tap(find.text('Mais espaço entre linhas'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectableText>(prose).style!.height,
        greaterThan(after.height!),
      );
      final saved = container.read(preferencesProvider);
      expect(saved.getString('readingTextSize'), 'large');
      expect(saved.getBool('readingComfortableSpacing'), true);
      container.read(routerProvider).go('/preferencias');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Maior'))
            .selected,
        true,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Mais espaço entre linhas'),
            )
            .value,
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'module footer stays within discipline and preserves material action',
    (tester) async {
      await openApp(tester, scale: 2);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      container
          .read(routerProvider)
          .go('/concursos/bb2026/financeira/bb2026-f01/material');
      await tester.pumpAndSettle();
      final previous = find.widgetWithText(OutlinedButton, 'Módulo anterior');
      final next = find.widgetWithText(OutlinedButton, 'Próximo módulo');
      expect(previous, findsOneWidget);
      expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/concursos/bb2026/financeira/bb2026-f02/material',
      );
      container
          .read(routerProvider)
          .go('/concursos/bb2026/financeira/bb2026-f07/material');
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/concursos/bb2026/financeira/bb2026-f06/material',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('lesson module footer preserves lessons action on mobile', (
    tester,
  ) async {
    await openApp(tester, scale: 2);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    container
        .read(routerProvider)
        .go('/concursos/bb2026/financeira/bb2026-f01/aulas');
    await tester.pumpAndSettle();
    final next = find.widgetWithText(OutlinedButton, 'Próximo módulo');
    expect(next, findsOneWidget);
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/concursos/bb2026/financeira/bb2026-f02/aulas',
    );
    expect(tester.takeException(), isNull);
  });
}
