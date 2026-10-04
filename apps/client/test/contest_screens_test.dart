import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/contests/contest_course_screen.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';

import 'app_test.dart' show openApp;

void main() {
  testWidgets('course_has_only_real_preparation_and_nine_disciplines', (
    tester,
  ) async {
    await openApp(tester);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    c.read(routerProvider).go('/concursos');
    await tester.pumpAndSettle();
    expect(find.text('Banco do Brasil 2026'), findsOneWidget);
    await tester.tap(find.text('Banco do Brasil 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Preparação'), findsOneWidget);
    expect(
      find.textContaining('Referência histórica: edital 2022/001.'),
      findsOneWidget,
    );
    expect(find.textContaining('01/10/2026'), findsOneWidget);
    for (final d in c.read(contestCatalogProvider).requireValue.disciplines) {
      expect(find.text(d.title), findsOneWidget);
    }
    expect(c.read(learningProvider).area, LearningArea.contest);
    await tester.ensureVisible(find.text('Matemática Financeira'));
    await tester.tap(find.text('Matemática Financeira'));
    await tester.pumpAndSettle();
    expect(find.text('Juros simples'), findsOneWidget);
    await tester.ensureVisible(find.text('Juros simples'));
    await tester.tap(find.text('Juros simples'));
    await tester.pumpAndSettle();
    expect(find.text('Material autoral · Estuda Aí'), findsOneWidget);
    await tester.tap(find.text('Voltar à disciplina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar ao concurso'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ContestCourseScreen),
        matching: find.text('Banco do Brasil 2026'),
      ),
      findsOneWidget,
    );
    c.read(routerProvider).go('/');
    await tester.pumpAndSettle();
    expect(c.read(learningProvider).area, LearningArea.freeStudy);
    expect(tester.takeException(), isNull);
  });
  testWidgets('mobile_preferences_has_header_control_and_five_destinations', (
    tester,
  ) async {
    await openApp(tester);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.byTooltip('Preferências'), findsOneWidget);
    await tester.tap(find.byTooltip('Preferências'));
    await tester.pumpAndSettle();
    expect(find.text('Aparência'), findsOneWidget);
  });
}
