import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';

import 'app_test.dart' show openApp;

void main() {
  Future<ProviderContainer> open(
    WidgetTester tester, {
    Size size = const Size(1440, 1000),
    double scale = 1,
  }) async {
    await openApp(tester, size: size, scale: scale);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return ProviderScope.containerOf(tester.element(find.byType(EstudaAiApp)));
  }

  testWidgets('sidebar can collapse, navigate, and reopen', (tester) async {
    final c = await open(tester);
    expect(find.byKey(const ValueKey('study-sidebar')), findsOneWidget);
    await tester.tap(find.byTooltip('Recolher menu lateral'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('study-sidebar')), findsNothing);
    c.read(routerProvider).go('/preferencias');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('study-sidebar')), findsNothing);
    await tester.tap(find.byTooltip('Expandir menu lateral'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('study-sidebar')), findsOneWidget);
    expect(find.text('Aparência'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile drawer navigates to the notebook and closes', (
    tester,
  ) async {
    final c = await open(tester, size: const Size(360, 800), scale: 2);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('nav-errors')),
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('study-sidebar')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('nav-errors')));
    await tester.pumpAndSettle();
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/meus-erros',
    );
    expect(find.byKey(const ValueKey('study-sidebar')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'area switcher preserves both topics and contextual lesson routes',
    (tester) async {
      final c = await open(tester);
      c.listen(contestCatalogProvider, (_, _) {});
      await tester.pumpAndSettle();
      c.read(learningProvider.notifier).selectTopic('bb2026-r02');
      c.read(routerProvider).go('/conta');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Trocar área de estudo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('area-free')));
      await tester.pumpAndSettle();
      expect(c.read(learningProvider).area, LearningArea.freeStudy);
      expect(c.read(learningProvider).contestTopicId, 'bb2026-r02');
      await tester.tap(find.byTooltip('Trocar área de estudo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('area-contest')));
      await tester.pumpAndSettle();
      expect(c.read(learningProvider).topicId, 'bb2026-r02');
      await tester.tap(find.byKey(const ValueKey('nav-lessons')));
      await tester.pumpAndSettle();
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/concursos/bb2026/redacao/bb2026-r02/aulas',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'quick search filters actual destinations and navigates by keyboard',
    (tester) async {
      final c = await open(tester);
      await tester.tap(find.byTooltip('Buscar atalhos'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('navigation-search')),
        'erros',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('search-errors')), findsOneWidget);
      expect(find.byKey(const ValueKey('search-home')), findsNothing);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/meus-erros',
      );
      expect(find.byKey(const ValueKey('navigation-search')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quick search handles no results and Escape', (tester) async {
    await open(tester, size: const Size(768, 1024));
    await tester.tap(find.byTooltip('Buscar atalhos'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('navigation-search')),
      'xyzxyz',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhum atalho encontrado.'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigation-search')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('global Ctrl K opens navigation search without a prior click', (
    tester,
  ) async {
    await open(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigation-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile course highlights Concursos and utility pages have no false home selection',
    (tester) async {
      final c = await open(tester, size: const Size(360, 800));
      c.read(routerProvider).go('/concursos/bb2026');
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      c.read(routerProvider).go('/conta');
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'short desktop window with large text keeps footer destinations reachable',
    (tester) async {
      final c = await open(tester, size: const Size(1440, 400), scale: 2);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('nav-settings')),
        180,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('study-sidebar')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('nav-settings')));
      await tester.pumpAndSettle();
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/preferencias',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('search resolves study routes from the context at submission', (
    tester,
  ) async {
    final c = await open(tester);
    c.listen(contestCatalogProvider, (_, _) {});
    c.read(routerProvider).go('/conta');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buscar atalhos'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('navigation-search')),
      'aprender',
    );
    c.read(learningProvider.notifier).selectTopic('bb2026-r02');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-lessons')));
    await tester.pumpAndSettle();
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/concursos/bb2026/redacao/bb2026-r02/aulas',
    );
    expect(tester.takeException(), isNull);
  });
}
