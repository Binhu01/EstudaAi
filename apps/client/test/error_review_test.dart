import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/quiz/answer_tile.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/learning/study_routes.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';

import 'app_test.dart' show openApp;
import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'helpers/study_history_fixtures.dart';

void main() {
  for (final correct in [false, true]) {
    testWidgets(
      'review reveals feedback after choice and uses confirmed status $correct',
      (tester) async {
        final q = historyCatalog().find('porcentagem')!.questions.first;
        final requests = <RequestOptions>[];
        var fail = true;
        final dio = Dio()
          ..httpClientAdapter = ScriptAdapter((r) async {
            if (r.path.endsWith('/v1/me')) {
              return jsonResponse({'id': historyUser, 'plan': 'FREE'});
            }
            if (r.path.endsWith('/ensure')) return jsonResponse(goalReply());
            if (r.method == 'PUT') {
              requests.add(r);
              if (fail) return jsonResponse({'code': 'UNAVAILABLE'}, 503);
              return jsonResponse({
                ...r.data as Map,
                'answerId': r.path.split('/').last,
                'goalId': historyGoal,
                'correct': correct,
                'receivedAt': '2026-10-02T12:00:00.000Z',
              });
            }
            return jsonResponse(authResponse('token', 3600));
          });
        await openApp(tester, dio: dio, scale: 2);
        final c = ProviderScope.containerOf(
          tester.element(find.byType(EstudaAiApp)),
        );
        await tester.runAsync(
          () => c
              .read(sessionProvider.notifier)
              .login('a@example.com', 'password'),
        );
        c.read(routerProvider).go('/meus-erros/porcentagem/1/${q.id}');
        await tester.pumpAndSettle();
        expect(find.text(q.explanation), findsNothing);
        expect(find.text('Revisado'), findsNothing);
        final option = correct ? q.correctIndex : (q.correctIndex + 1) % 4;
        await tester.ensureVisible(find.byKey(ValueKey('answer-$option')));
        if (correct) {
          tester
              .widget<FilledButton>(find.byKey(ValueKey('answer-$option')))
              .focusNode!
              .requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        } else {
          await tester.tap(find.byKey(ValueKey('answer-$option')));
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pumpAndSettle();
        expect(find.text(q.explanation), findsOneWidget);
        expect(find.text('Revisado'), findsNothing);
        expect(requests.length, 1);
        expect((requests.first.data as Map)['source'], 'review');
        expect((requests.first.data as Map)['optionIndex'], option);
        fail = false;
        await tester.ensureVisible(find.text('Tentar novamente'));
        await tester.tap(find.text('Tentar novamente'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pumpAndSettle();
        expect(requests.length, 2);
        expect(requests[1].path, requests[0].path);
        expect(requests[1].data, requests[0].data);
        expect(
          find.text(correct ? 'Revisado' : 'Ainda pendente de revisão'),
          findsOneWidget,
        );
        expect(
          tester.widget<AnswerTile>(find.byType(AnswerTile).first).onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'outdated or removed question never submits and offers current content',
    (tester) async {
      var writes = 0;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.method == 'PUT') writes++;
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': historyUser, 'plan': 'FREE'});
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
      for (final route in [
        '/meus-erros/porcentagem/2/old-question',
        '/meus-erros/porcentagem/1/removed-question',
      ]) {
        c.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(find.byType(AnswerTile), findsNothing);
        expect(find.text('Estudar conteúdo atual'), findsOneWidget);
      }
      expect(writes, 0);
    },
  );
  testWidgets(
    'direct contest review keeps its module in material lessons and Steve links',
    (tester) async {
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
        () =>
            c.read(sessionProvider.notifier).login('a@example.com', 'password'),
      );
      final contests = await tester.runAsync(
        () => c.read(contestCatalogProvider.future),
      );
      final id = contests!.disciplines.first.modules.first.id;
      final entry = c.read(learningEntryProvider(id)).requireValue;
      expect(entry, isNotNull);
      c
          .read(routerProvider)
          .go(
            '/meus-erros/$id/${entry!.contentVersion}/${entry.topic.questions.first.id}',
          );
      await tester.pumpAndSettle();
      expect(c.read(learningProvider).topicId, id);
      for (final pair in [
        ('Ver material', StudyAction.material),
        ('Ver videoaulas', StudyAction.lessons),
        ('Perguntar ao Steve', StudyAction.steve),
      ]) {
        await tester.ensureVisible(find.text(pair.$1));
        await tester.tap(find.text(pair.$1));
        await tester.pumpAndSettle();
        expect(
          c.read(routerProvider).routeInformationProvider.value.uri.path,
          StudyRoutes.path(entry, pair.$2),
        );
        c
            .read(routerProvider)
            .go(
              '/meus-erros/$id/${entry.contentVersion}/${entry.topic.questions.first.id}',
            );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );
}
