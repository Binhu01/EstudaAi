import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/steve/steve_message.dart';
import 'package:estuda_ai/features/steve/steve_models.dart';

import 'app_test.dart' show openApp;
import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'steve_api_test.dart' show steveResponse, testCatalog;

void main() {
  testWidgets('Steve requires login and lessons stay usable at 200%', (
    tester,
  ) async {
    await openApp(tester, scale: 2);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    c.read(routerProvider).go('/steve/ecologia');
    await tester.pumpAndSettle();
    expect(
      find.text('Entre na sua conta para conversar com o Steve.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Entrar para conversar'));
    await tester.tap(find.text('Entrar para conversar'));
    await tester.pumpAndSettle();
    expect(find.text('Sua conta'), findsOneWidget);
    c.read(routerProvider).go('/aprender/ecologia');
    await tester.pumpAndSettle();
    expect(
      find.text(testCatalog().find('ecologia')!.lessons.first.title),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Perguntar ao Steve'));
    await tester.tap(find.text('Perguntar ao Steve'));
    await tester.pumpAndSettle();
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/steve/ecologia',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'keyboard sends, service error keeps input, safe reply shows actual quota and trusted source',
    (tester) async {
      var status = 503;
      final opened = <Uri>[];
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': 'internal', 'plan': 'FREE'});
          }
          if (r.path.endsWith('/messages')) {
            return jsonResponse(
              status == 200
                  ? steveResponse(
                      'porcentagem',
                      text: '<script>alert(1)</script>',
                    )
                  : {'message': 'secret error'},
              status,
            );
          }
          return jsonResponse(authResponse('id-token', 3600));
        });
      await openApp(
        tester,
        scale: 2,
        dio: dio,
        openLink: (url) async {
          opened.add(url);
          return true;
        },
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      await tester.runAsync(
        () =>
            c.read(sessionProvider.notifier).login('a@example.com', 'password'),
      );
      c.read(routerProvider).go('/steve/porcentagem');
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('steve-message-field'));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Minha pergunta');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field).controller!.text,
        'Minha pergunta',
      );
      expect(
        find.text(
          'O serviço está indisponível no momento. Tente novamente mais tarde.',
        ),
        findsOneWidget,
      );
      expect(find.text('secret error'), findsNothing);
      status = 200;
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(find.text('<script>alert(1)</script>'), findsOneWidget);
      expect(find.text('9 mensagens disponíveis hoje'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      final source = find.text(
        testCatalog().find('porcentagem')!.sources.single.title,
      );
      await tester.ensureVisible(source);
      await tester.tap(source);
      await tester.pumpAndSettle();
      expect(
        opened.single.toString(),
        testCatalog().find('porcentagem')!.sources.single.url,
      );
      c.read(sessionProvider.notifier).signOut();
      await tester.pumpAndSettle();
      expect(find.text('<script>alert(1)</script>'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('refusal and empty incomplete have distinct visible states', (
    tester,
  ) async {
    final topic = testCatalog().find('ecologia')!;
    for (final status in ['refused', 'incomplete']) {
      final reply = SteveReply.fromJson(
        steveResponse(
          topic.id,
          status: status,
          text: status == 'incomplete' ? '' : 'Não posso responder isso.',
        ),
        topic: topic,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SteveMessage(turn: ChatTurn('Pergunta', reply))),
        ),
      );
      expect(
        find.text(
          status == 'incomplete'
              ? 'Resposta incompleta'
              : 'Pedido não atendido',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
