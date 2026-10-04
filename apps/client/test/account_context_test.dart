import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';

import 'app_test.dart' show openApp;
import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;

void main() {
  for (final scenario in const [
    (
      topic: 'porcentagem',
      start: '/aprender/porcentagem',
      button: 'Conversar com o Steve',
      destination: '/steve/porcentagem',
      area: LearningArea.freeStudy,
    ),
    (
      topic: 'porcentagem',
      start: '/aprender/porcentagem',
      button: 'Retomar os estudos',
      destination: '/aprender/porcentagem',
      area: LearningArea.freeStudy,
    ),
    (
      topic: 'bb2026-f07',
      start: '/concursos/bb2026/financeira/bb2026-f07/material',
      button: 'Conversar com o Steve',
      destination: '/concursos/bb2026/financeira/bb2026-f07/steve',
      area: LearningArea.contest,
    ),
    (
      topic: 'bb2026-f07',
      start: '/concursos/bb2026/financeira/bb2026-f07/material',
      button: 'Retomar os estudos',
      destination: '/concursos/bb2026/financeira/bb2026-f07/material',
      area: LearningArea.contest,
    ),
  ]) {
    testWidgets(
      'account ${scenario.button} preserves ${scenario.area.name} context after login',
      (tester) async {
        final dio = Dio()
          ..httpClientAdapter = ScriptAdapter((request) async {
            if (request.path.endsWith('/v1/me')) {
              return jsonResponse({
                'id': '11111111-1111-4111-8111-111111111111',
                'plan': 'FREE',
              });
            }
            return jsonResponse(authResponse('id-token', 3600));
          });
        await openApp(tester, dio: dio, scale: 2);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(EstudaAiApp)),
        );
        final router = container.read(routerProvider);
        router.go(scenario.start);
        await tester.pumpAndSettle();
        router.go('/conta');
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('email-field')),
          'a@example.com',
        );
        await tester.enterText(
          find.byKey(const ValueKey('password-field')),
          'password',
        );
        final submit = find.byKey(const ValueKey('account-submit'));
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.text('Você está conectado'), findsOneWidget);
        final action = find.text(scenario.button);
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          scenario.destination,
        );
        expect(container.read(learningProvider).area, scenario.area);
        expect(container.read(learningProvider).topicId, scenario.topic);
        expect(find.text('Assunto não encontrado'), findsNothing);
        expect(find.text('Conteúdo de concurso não encontrado'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
