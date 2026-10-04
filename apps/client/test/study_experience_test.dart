import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/quiz/quiz_controller.dart';
import 'package:estuda_ai/features/study_history/errors_controller.dart';
import 'package:estuda_ai/features/study_history/error_review_batch.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';
import 'package:estuda_ai/features/study_history/study_history_models.dart';

import 'app_test.dart' show openApp;
import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'errors_screen_test.dart' show errorReply;
import 'helpers/study_history_fixtures.dart';

void main() {
  testWidgets('round result retains missed answers with explanations', (
    tester,
  ) async {
    await openApp(tester);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    c.read(routerProvider).go('/desafios/porcentagem');
    await tester.pumpAndSettle();
    final quiz = c.read(quizProvider('porcentagem').notifier)..start();
    final missed = <String>[];
    for (var i = 0; i < 5; i++) {
      final q = c.read(quizProvider('porcentagem')).round.question;
      if (i < 2) missed.add(q.explanation);
      quiz.answer(i < 2 ? (q.correctIndex + 1) % 4 : q.correctIndex);
      quiz.next();
    }
    await tester.pumpAndSettle();
    expect(find.text('O que revisar'), findsOneWidget);
    for (final explanation in missed) {
      expect(find.text(explanation), findsOneWidget);
    }
    expect(find.text('Abrir meu caderno de erros'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'review round waits for confirmation, retries same answer and advances',
    (tester) async {
      final questions = historyCatalog()
          .find('porcentagem')!
          .questions
          .take(2)
          .toList();
      final sent = <String>[];
      final delayed = Completer<ResponseBody>();
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': historyUser, 'plan': 'FREE'});
          }
          if (r.path.endsWith('/ensure')) return jsonResponse(goalReply());
          if (r.path.endsWith('/errors')) {
            return jsonResponse({
              'items': [for (final q in questions) errorReply(q.id)],
              'nextCursor': null,
            });
          }
          if (r.path.contains('/answers/')) {
            sent.add(r.path);
            if (sent.length == 1) return delayed.future;
            final input = Map<String, dynamic>.from(r.data as Map);
            final q = questions.firstWhere((q) => q.id == input['questionId']);
            return jsonResponse({
              ...input,
              'answerId': r.path.split('/').last,
              'goalId': historyGoal,
              'correct': input['optionIndex'] == q.correctIndex,
              'receivedAt': '2026-10-03T12:00:00.000Z',
            });
          }
          return jsonResponse(authResponse('token', 3600));
        });
      await openApp(tester, size: const Size(360, 800), scale: 2, dio: dio);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      await tester.runAsync(
        () =>
            c.read(sessionProvider.notifier).login('a@example.com', 'password'),
      );
      c.read(routerProvider).go('/meus-erros');
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => c.read(errorsProvider.notifier).load(const ErrorQuery()),
      );
      await tester.pumpAndSettle();
      final start = find.text('Revisar até 5 erros');
      expect(start, findsOneWidget);
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.text('Questão 1 de 2'), findsOneWidget);
      final first = questions.first;
      await tester.ensureVisible(find.text(first.options[first.correctIndex]));
      await tester.tap(find.text(first.options[first.correctIndex]));
      await tester.pump();
      final next = find.widgetWithText(FilledButton, 'Próxima revisão');
      expect(tester.widget<FilledButton>(next).onPressed, isNull);
      delayed.complete(jsonResponse({'code': 'UNAVAILABLE'}, 503));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tentar novamente'));
      await tester.tap(find.text('Tentar novamente'));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(sent.length, 2);
      expect(sent[1], sent[0]);
      await tester.ensureVisible(find.text('Próxima revisão'));
      await tester.tap(find.text('Próxima revisão'));
      await tester.pumpAndSettle();
      expect(find.text('Questão 2 de 2'), findsOneWidget);
      final second = questions[1];
      await tester.ensureVisible(
        find.text(second.options[(second.correctIndex + 1) % 4]),
      );
      await tester.tap(
        find.text(second.options[(second.correctIndex + 1) % 4]),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Concluir revisão'));
      await tester.tap(find.text('Concluir revisão'));
      await tester.pumpAndSettle();
      expect(find.text('1 questão revisada'), findsOneWidget);
      expect(find.text('1 questão continua pendente'), findsOneWidget);
      c.read(sessionProvider.notifier).signOut();
      await tester.pumpAndSettle();
      expect(find.text('1 questão revisada'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'notebook explains the last recorded answer without another submission',
    (tester) async {
      final q = historyCatalog().find('porcentagem')!.questions.first;
      var writes = 0;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': historyUser, 'plan': 'FREE'});
          }
          if (r.path.endsWith('/ensure')) return jsonResponse(goalReply());
          if (r.path.contains('/answers/')) writes++;
          if (r.path.endsWith('/errors')) {
            return jsonResponse({
              'items': [errorReply(q.id)],
              'nextCursor': null,
            });
          }
          return jsonResponse(authResponse('token', 3600));
        });
      await openApp(tester, dio: dio);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      await tester.runAsync(
        () =>
            c.read(sessionProvider.notifier).login('a@example.com', 'password'),
      );
      c.read(routerProvider).go('/meus-erros');
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => c.read(errorsProvider.notifier).load(const ErrorQuery()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Entender esta questão'), findsOneWidget);
      await tester.ensureVisible(find.text('Entender esta questão'));
      await tester.tap(find.text('Entender esta questão'));
      await tester.pumpAndSettle();
      expect(
        find.text('Última resposta registrada: ${q.options[0]}'),
        findsOneWidget,
      );
      expect(find.text(q.explanation), findsOneWidget);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a stale question can be skipped without marking it reviewed', (
    tester,
  ) async {
    final qs = historyCatalog().find('porcentagem')!.questions;
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter(
        (r) async => jsonResponse(
          r.path.endsWith('/v1/me')
              ? {'id': historyUser, 'plan': 'FREE'}
              : authResponse('token', 3600),
        ),
      );
    await openApp(tester, dio: dio);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    await tester.runAsync(
      () => c.read(sessionProvider.notifier).login('a@example.com', 'password'),
    );
    final session = c.read(sessionProvider);
    c
        .read(routerProvider)
        .go(
          '/meus-erros/revisao',
          extra: ErrorReviewBatch(
            userId: session.profile!.id,
            sessionGeneration: session.generation,
            area: LearningArea.freeStudy,
            items: [
              StudyErrorItem.fromJson(errorReply(qs[0].id, version: 2)),
              StudyErrorItem.fromJson(errorReply(qs[1].id)),
            ],
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Pular questão indisponível'), findsOneWidget);
    await tester.ensureVisible(find.text('Pular questão indisponível'));
    await tester.tap(find.text('Pular questão indisponível'));
    await tester.pumpAndSettle();
    expect(find.text('Questão 2 de 2'), findsOneWidget);
    expect(find.text(qs[1].prompt), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
