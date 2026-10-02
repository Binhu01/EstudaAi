import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/contests/contest_catalog.dart';
import 'package:estuda_ai/features/contests/contest_route_scope.dart';
import 'package:estuda_ai/features/learning/learning_entry_view.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/app/app.dart';

import 'app_test.dart' show openApp;

ContestCatalog contestFixture() => ContestCatalog.fromJson(
  jsonDecode(File('assets/contests/bb2026/catalog.json').readAsStringSync())
      as Map<String, dynamic>,
);
void main() {
  testWidgets('rejects_wrong_discipline_and_free_alias_without_selection', (
    tester,
  ) async {
    final contests = contestFixture();
    late ProviderContainer c;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contestCatalogProvider.overrideWith((ref) async => contests),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                c = ProviderScope.containerOf(context);
                return const ContestRouteScope(
                  courseId: 'bb2026',
                  disciplineId: 'matematica',
                  topicId: 'bb2026-b01',
                  child: Text('unsafe'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('unsafe'), findsNothing);
    expect(find.text('Conteúdo de concurso não encontrado'), findsOneWidget);
    expect(c.read(learningProvider).area, LearningArea.freeStudy);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contestCatalogProvider.overrideWith((ref) async => contests),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: LearningEntryView(
              topicId: 'bb2026-b01',
              area: LearningArea.freeStudy,
              builder: (_) => const Text('unsafe'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('unsafe'), findsNothing);
    expect(find.text('Assunto não encontrado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('preferences_and_account_keep_area', (tester) async {
    await openApp(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    c.listen(contestCatalogProvider, (_, _) {});
    await tester.pumpAndSettle();
    c.read(learningProvider.notifier).selectTopic('bb2026-r02');
    for (final path in ['/preferencias', '/conta']) {
      c.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(c.read(learningProvider).area, LearningArea.contest);
      expect(c.read(learningProvider).topicId, 'bb2026-r02');
    }
    expect(tester.takeException(), isNull);
  });
}
