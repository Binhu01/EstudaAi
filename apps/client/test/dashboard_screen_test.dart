import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/study_history/dashboard_controller.dart';
import 'package:estuda_ai/features/study_history/study_context_controller.dart';

import 'app_test.dart' show openApp;
import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'helpers/study_history_fixtures.dart';

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(768, 1024),
    const Size(1440, 1000),
  ]) {
    testWidgets(
      'daily dashboard uses confirmed counts at ${size.width} with large text',
      (tester) async {
        var targetFails = false;
        final dio = Dio()
          ..httpClientAdapter = ScriptAdapter((r) async {
            if (r.path.endsWith('/v1/me')) {
              return jsonResponse({'id': historyUser, 'plan': 'FREE'});
            }
            if (r.path.endsWith('/ensure')) return jsonResponse(goalReply());
            if (r.path.endsWith('/dashboard')) {
              return jsonResponse(dashboardReply());
            }
            if (r.path.endsWith('/daily-target')) {
              return targetFails
                  ? jsonResponse({'code': 'UNAVAILABLE'}, 503)
                  : jsonResponse({
                      ...goalReply(),
                      'dailyTarget': (r.data as Map)['dailyTarget'],
                    });
            }
            return jsonResponse(authResponse('token', 3600));
          });
        await openApp(tester, size: size, scale: 2, dio: dio);
        final c = ProviderScope.containerOf(
          tester.element(find.byType(EstudaAiApp)),
        );
        c.read(routerProvider).go('/meu-estudo');
        await tester.pumpAndSettle();
        expect(find.text('Entrar para salvar meu estudo'), findsOneWidget);
        await tester.runAsync(
          () => c
              .read(sessionProvider.notifier)
              .login('a@example.com', 'password'),
        );
        await tester.runAsync(() => c.read(dashboardProvider.notifier).load());
        await tester.pumpAndSettle();
        expect(find.text('2 de 10 questões diferentes'), findsOneWidget);
        expect(find.text('1 acerto em 3 tentativas'), findsOneWidget);
        expect(find.text('Revisar meus erros'), findsOneWidget);
        expect(c.read(dashboardProvider).data!.activity.length, 7);
        targetFails = true;
        await tester.runAsync(
          () => c.read(dashboardProvider.notifier).setDailyTarget(5),
        );
        await tester.pumpAndSettle();
        expect(c.read(dashboardProvider).data!.goal.dailyTarget, 10);
        c.read(sessionProvider.notifier).signOut();
        await tester.pumpAndSettle();
        expect(find.text('2 de 10 questões diferentes'), findsNothing);
        expect(c.read(studyContextProvider).snapshot, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'empty history offers first challenge without fabricated progress',
    (tester) async {
      final empty = dashboardReply();
      empty['today'] = {
        'date': '2026-10-02',
        'differentQuestions': 0,
        'attempts': 0,
        'correct': 0,
      };
      empty['activity'] = [
        for (final day in dashboardReply()['activity'] as List)
          {...day as Map, 'differentQuestions': 0, 'attempts': 0, 'correct': 0},
      ];
      empty['pendingErrors'] = 0;
      empty['subjects'] = [];
      empty['resume'] = null;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter(
          (r) async => jsonResponse(
            r.path.endsWith('/v1/me')
                ? {'id': historyUser, 'plan': 'FREE'}
                : r.path.endsWith('/ensure')
                ? goalReply()
                : r.path.endsWith('/dashboard')
                ? empty
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
      c.read(routerProvider).go('/meu-estudo');
      await tester.pumpAndSettle();
      expect(find.text('Começar meu primeiro desafio'), findsOneWidget);
      expect(find.text('0 de 10 questões diferentes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
