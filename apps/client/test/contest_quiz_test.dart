import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';
import 'package:estuda_ai/features/quiz/quiz_controller.dart';
import 'package:estuda_ai/features/quiz/quiz_engine.dart';
import 'package:estuda_ai/features/contests/contest_catalog.dart';
import 'package:estuda_ai/features/quiz/best_score_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show openApp;

void main() {
  test(
    'save_failure_preserves_result_and_late_save_does_not_replace_repeat',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = _DelayedScore(await SharedPreferences.getInstance());
      final catalog = ContestCatalog.fromJson(
        jsonDecode(
          File('assets/contests/bb2026/catalog.json').readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final c = ProviderContainer(
        overrides: [
          contestCatalogProvider.overrideWith((ref) async => catalog),
          bestScoreProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(c.dispose);
      await c.read(contestCatalogProvider.future);
      final provider = quizProvider('bb2026-b01');
      c.listen(provider, (_, _) {});
      final controller = c.read(provider.notifier);
      void complete() {
        controller.start();
        for (var i = 0; i < 5; i++) {
          controller.answer(c.read(provider).round.question.correctIndex);
          controller.next();
        }
      }

      complete();
      repository.pending.completeError(StateError('save failed'));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(provider).saveFailed, isTrue);
      expect(c.read(provider).round.score, 700);
      expect(c.read(provider).round.phase, QuizPhase.completed);
      repository.pending = Completer<void>();
      complete();
      controller.start();
      repository.pending.complete();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(provider).round.score, 0);
      expect(c.read(provider).round.phase, QuizPhase.answering);
    },
  );
  testWidgets('contest_round_uses_five_of_six_and_result_returns_same_module', (
    tester,
  ) async {
    await openApp(tester);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    c.read(routerProvider).go('/concursos/bb2026/bancarios/bb2026-b01/desafio');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Começar desafio'));
    await tester.tap(find.text('Começar desafio'));
    await tester.pumpAndSettle();
    final pool = c
        .read(contestCatalogProvider)
        .requireValue
        .find('bb2026-b01')!
        .module
        .questions;
    final round = c.read(quizProvider('bb2026-b01')).round;
    expect(round.roundQuestions.length, 5);
    expect(round.roundQuestions.map((q) => q.id).toSet().length, 5);
    for (final q in round.roundQuestions) {
      final original = pool.firstWhere((source) => source.id == q.id);
      expect(q.options.toSet(), original.options.toSet());
      expect(
        q.options[q.correctIndex],
        original.options[original.correctIndex],
      );
    }
    for (var i = 0; i < 5; i++) {
      final q = c.read(quizProvider('bb2026-b01')).round.question;
      await tester.ensureVisible(find.text(q.options[q.correctIndex]));
      await tester.tap(find.text(q.options[q.correctIndex]));
      await tester.pumpAndSettle();
      expect(find.text(q.explanation), findsOneWidget);
      final next = find.text(i == 4 ? 'Ver resultado' : 'Próxima pergunta');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(c.read(quizProvider('bb2026-b01')).round.score, 700);
    expect(find.text('700 / 700 pontos'), findsOneWidget);
    expect(find.text('Perguntar ao Steve'), findsOneWidget);
    await tester.ensureVisible(find.text('Revisar material'));
    await tester.tap(find.text('Revisar material'));
    await tester.pumpAndSettle();
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/concursos/bb2026/bancarios/bb2026-b01/material',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'long_prompt_and_feedback_are_reachable_with_keyboard_at_200_percent',
    (tester) async {
      await openApp(tester, scale: 2);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      c.read(routerProvider).go('/concursos/bb2026/ingles/bb2026-e08/desafio');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Começar desafio'));
      await tester.tap(find.text('Começar desafio'));
      await tester.pumpAndSettle();
      final q = c.read(quizProvider('bb2026-e08')).round.question;
      expect(q.prompt.startsWith('Passagem:'), isTrue);
      final button = find.byKey(const ValueKey('answer-0'));
      await tester.ensureVisible(button);
      tester.widget<FilledButton>(button).focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        c.read(quizProvider('bb2026-e08')).round.phase,
        QuizPhase.feedback,
      );
      await tester.ensureVisible(find.text(q.explanation));
      await tester.ensureVisible(find.text('Próxima pergunta'));
      expect(tester.takeException(), isNull);
    },
  );
}

class _DelayedScore extends BestScoreRepository {
  _DelayedScore(super.preferences);
  Completer<void> pending = Completer<void>();
  @override
  Future<void> saveIfHigher(String topicId, int catalogVersion, int score) =>
      pending.future;
}
