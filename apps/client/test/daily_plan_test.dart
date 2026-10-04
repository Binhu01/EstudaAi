import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/study_history/dashboard_controller.dart';

import 'app_test.dart' show openApp;
import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'helpers/study_history_fixtures.dart';

void main() {
  testWidgets(
    'daily plan resumes learning and shows confirmed coverage and review milestones',
    (tester) async {
      final reply = dashboardReply();
      reply['progress'] = {
        'practicedQuestions': 4,
        'catalogQuestions': 15,
        'reviewedErrors': 1,
        'correctReviewQuestions': 1,
        'activeDays': 1,
        'currentStreak': 1,
        'bestStreak': 1,
      };
      reply['subjects'] = [
        {
          'id': 'porcentagem',
          'title': 'Porcentagem',
          'attempts': 6,
          'correct': 3,
          'progress': {
            'practicedQuestions': 4,
            'latestCorrectQuestions': 2,
            'catalogQuestions': 5,
          },
        },
      ];
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': historyUser, 'plan': 'FREE'});
          }
          if (r.path.endsWith('/ensure')) return jsonResponse(goalReply());
          if (r.path.endsWith('/dashboard')) return jsonResponse(reply);
          if (r.path.endsWith('/daily-target')) {
            final goal = {
              ...goalReply(),
              'dailyTarget': (r.data as Map)['dailyTarget'],
            };
            reply['goal'] = goal;
            return jsonResponse(goal);
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
      c.read(routerProvider).go('/meu-estudo');
      await tester.pumpAndSettle();
      expect(find.text('4 de 15 questões praticadas'), findsOneWidget);
      expect(find.text('1 dia de sequência'), findsOneWidget);
      expect(find.text('Primeira revisão'), findsOneWidget);
      expect(find.text('4 de 5 questões praticadas'), findsOneWidget);
      expect(
        find.text('2 acertos na última resposta de cada questão'),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        await c.read(dashboardProvider.notifier).setDailyTarget(5);
        expect(c.read(dashboardProvider).data!.progress!.practicedQuestions, 4);
      });
      await tester.pumpAndSettle();
      expect(c.read(dashboardProvider).data!.goal.dailyTarget, 5);
      expect(find.text('4 de 15 questões praticadas'), findsOneWidget);
      await tester.ensureVisible(find.text('Continuar estudando'));
      await tester.tap(find.text('Continuar estudando'));
      await tester.pumpAndSettle();
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/aprender/porcentagem',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
