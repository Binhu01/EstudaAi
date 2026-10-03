import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';
import 'package:estuda_ai/features/study_history/errors_controller.dart';
import 'package:estuda_ai/features/study_history/study_history_models.dart';

import 'app_test.dart' show openApp;
import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'helpers/study_history_fixtures.dart';

Map<String, Object?> errorReply(String questionId, {int version = 1}) => {
  'topicId': 'porcentagem',
  'contentVersion': version,
  'questionId': questionId,
  'wrongCount': 2,
  'firstWrongAt': '2026-10-01T12:00:00.000Z',
  'lastWrongAt': '2026-10-02T12:00:00.000Z',
  'lastAnswerAt': '2026-10-02T12:00:00.000Z',
  'lastOptionIndex': 0,
  'status': 'pending',
  'contentStatus': version == 1 ? 'current' : 'outdated',
};
void main() {
  for (final size in [
    const Size(360, 800),
    const Size(768, 1024),
    const Size(1440, 1000),
  ]) {
    testWidgets(
      'notebook separates old content and keeps readable controls ${size.width}',
      (tester) async {
        final q = historyCatalog().find('porcentagem')!.questions.first;
        final dio = Dio()
          ..httpClientAdapter = ScriptAdapter((r) async {
            if (r.path.endsWith('/v1/me')) {
              return jsonResponse({'id': historyUser, 'plan': 'FREE'});
            }
            if (r.path.endsWith('/ensure')) return jsonResponse(goalReply());
            if (r.path.endsWith('/errors')) {
              return jsonResponse({
                'items': r.queryParameters['status'] == 'reviewed'
                    ? []
                    : [
                        errorReply(q.id),
                        errorReply('old-question', version: 2),
                      ],
                'nextCursor': null,
              });
            }
            return jsonResponse(authResponse('token', 3600));
          });
        await openApp(tester, size: size, scale: 2, dio: dio);
        final c = ProviderScope.containerOf(
          tester.element(find.byType(EstudaAiApp)),
        );
        c.read(routerProvider).go('/meus-erros');
        await tester.pumpAndSettle();
        expect(find.text('Entrar para salvar meu estudo'), findsOneWidget);
        await tester.runAsync(
          () => c
              .read(sessionProvider.notifier)
              .login('a@example.com', 'password'),
        );
        await tester.runAsync(
          () => c.read(errorsProvider.notifier).load(const ErrorQuery()),
        );
        await tester.pumpAndSettle();
        expect(find.text(q.prompt), findsOneWidget);
        expect(find.text('Conteúdo de outra versão'), findsOneWidget);
        expect(find.text('Revisar questão'), findsOneWidget);
        expect(find.text('Dominado'), findsNothing);
        await tester.runAsync(
          () => c
              .read(errorsProvider.notifier)
              .load(const ErrorQuery(status: ErrorStatus.reviewed)),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Nenhuma questão revisada neste filtro.'),
          findsOneWidget,
        );
        c.read(sessionProvider.notifier).signOut();
        await tester.pumpAndSettle();
        expect(c.read(errorsProvider).items, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('pagination deduplicates and drops a page after changing scope', (
    tester,
  ) async {
    final qs = historyCatalog().find('porcentagem')!.questions;
    final delayed = Completer<ResponseBody>();
    var page = 0;
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        if (r.path.endsWith('/v1/me')) {
          return jsonResponse({'id': historyUser, 'plan': 'FREE'});
        }
        if (r.path.endsWith('/ensure')) {
          return jsonResponse(
            goalReply(r.path.contains('bb2026') ? 'bb2026' : 'freeStudy'),
          );
        }
        if (r.path.endsWith('/errors')) {
          if (r.path.contains(historyBbGoal)) {
            return jsonResponse({'items': [], 'nextCursor': null});
          }
          if (r.queryParameters['cursor'] != null) {
            page++;
            if (page == 2) return delayed.future;
            return jsonResponse({
              'items': [errorReply(qs[0].id), errorReply(qs[1].id)],
              'nextCursor': 'next2',
            });
          }
          return jsonResponse({
            'items': [errorReply(qs[0].id)],
            'nextCursor': 'next1',
          });
        }
        return jsonResponse(authResponse('token', 3600));
      });
    await openApp(tester, dio: dio);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    await tester.runAsync(
      () => c.read(sessionProvider.notifier).login('a@example.com', 'password'),
    );
    c.read(routerProvider).go('/meus-erros');
    await tester.pumpAndSettle();
    final controller = c.read(errorsProvider.notifier);
    await tester.runAsync(() => controller.load(const ErrorQuery()));
    await tester.pumpAndSettle();
    await tester.runAsync(controller.nextPage);
    await tester.pumpAndSettle();
    expect(c.read(errorsProvider).items.length, 2);
    late Future<void> old;
    await tester.runAsync(() async {
      old = controller.nextPage();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    expect(page, 2);
    c.read(learningProvider.notifier).enterArea(LearningArea.contest);
    await tester.runAsync(() => controller.load(const ErrorQuery()));
    delayed.complete(
      jsonResponse({
        'items': [errorReply(qs[2].id)],
        'nextCursor': null,
      }),
    );
    await tester.runAsync(() => old);
    await tester.pumpAndSettle();
    expect(c.read(errorsProvider).items, isEmpty);
    expect(c.read(errorsProvider).query.subjectId, isNull);
    expect(tester.takeException(), isNull);
  });
}
