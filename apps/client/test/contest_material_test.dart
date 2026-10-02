import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/contests/contest_material_screen.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';

import 'app_test.dart' show openApp;

void main() {
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
      for (final objective in m.objectives)
        expect(find.text(objective), findsOneWidget);
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
      '/concursos/bb2026/informatica/bb2026-i13/material',
    ]) {
      c.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(find.text('Objetivos deste módulo'), findsOneWidget);
      await tester.ensureVisible(find.text('Aulas de apoio'));
      expect(tester.takeException(), isNull);
      expect(find.text('Fontes de consulta'), findsOneWidget);
    }
  });
}
