import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/contests/contest_material_screen.dart';
import 'package:estuda_ai/features/contests/contest_models.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';

import 'app_test.dart' show openApp;

void main() {
  testWidgets('selectable_material_text_and_formula_have_accessible_labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await openApp(tester);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      c
          .read(routerProvider)
          .go('/concursos/bb2026/financeira/bb2026-f07/material');
      await tester.pumpAndSettle();
      final module = c
          .read(contestCatalogProvider)
          .requireValue
          .find('bb2026-f07')!
          .module;
      for (final block in module.blocks) {
        final label = switch (block) {
          TextBlock() => block.text,
          FormulaBlock() => block.expression,
          _ => null,
        };
        if (label != null) expect(find.bySemanticsLabel(label), findsOneWidget);
      }
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('renders_all_blocks_and_six_writing_tasks', (tester) async {
    await openApp(tester);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    c.read(routerProvider).go('/concursos');
    await tester.pumpAndSettle();
    final catalog = c.read(contestCatalogProvider).requireValue;
    var tasks = 0;
    for (final m in catalog.findDiscipline('redacao')!.modules) {
      c.read(routerProvider).go('/concursos/bb2026/redacao/${m.id}/material');
      await tester.pumpAndSettle();
      expect(find.byType(ContestMaterialScreen), findsOneWidget);
      for (final objective in m.objectives) {
        expect(find.text(objective), findsOneWidget);
      }
      for (final task in m.writingTasks) {
        expect(find.text(task.prompt), findsOneWidget);
        expect(find.text(task.motivatingText), findsOneWidget);
        tasks++;
      }
      expect(find.text('Revisão rápida'), findsOneWidget);
      expect(find.text('Recupere sem consultar'), findsOneWidget);
    }
    expect(tasks, 6);
    expect(tester.takeException(), isNull);
  });
  testWidgets('large_material_reflows_formula_table_and_actions', (
    tester,
  ) async {
    await openApp(tester, scale: 2);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    for (final route in [
      '/concursos/bb2026/financeira/bb2026-f07/material',
      '/concursos/bb2026/informatica/bb2026-i05/material',
    ]) {
      c.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(find.text('Objetivos deste módulo'), findsOneWidget);
      final id = route.split('/')[4];
      final module = c
          .read(contestCatalogProvider)
          .requireValue
          .find(id)!
          .module;
      final tables = module.blocks.whereType<TableBlock>().toList();
      expect(tables, isNotEmpty, reason: '$id must exercise a real table');
      final table = tables.first;
      expect(find.byType(Table), findsOneWidget);
      await tester.ensureVisible(find.text(table.columns.first));
      await tester.pumpAndSettle();
      final horizontal = tester.state<ScrollableState>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.right,
        ),
      );
      expect(horizontal.position.maxScrollExtent, greaterThan(0));
      await tester.dragFrom(
        tester.getCenter(find.text(table.columns.first)),
        Offset(-horizontal.position.maxScrollExtent, 0),
      );
      await tester.pumpAndSettle();
      expect(horizontal.position.pixels, greaterThan(0));
      expect(find.text(table.columns.last).hitTestable(), findsOneWidget);
      for (final formula in module.blocks.whereType<FormulaBlock>()) {
        await tester.ensureVisible(find.text(formula.expression));
        expect(find.text(formula.expression).hitTestable(), findsOneWidget);
      }
      final action = find.widgetWithText(OutlinedButton, 'Aulas de apoio');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      final actionContext = tester.element(
        find.descendant(of: action, matching: find.byType(Text)).first,
      );
      final focus = Focus.of(actionContext);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        route.replaceFirst('/material', '/aulas'),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
