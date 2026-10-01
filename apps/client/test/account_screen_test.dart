import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';

import 'app_test.dart' show openApp;
import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;

void main() {
  testWidgets(
    'account form signs in, clears password, signs out and recovers generically at 200%',
    (tester) async {
      var logins = 0, resets = 0;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': 'internal', 'plan': 'FREE'});
          }
          if (r.path.endsWith('password-reset')) {
            resets++;
            return jsonResponse({'accepted': true});
          }
          logins++;
          return jsonResponse(authResponse('id-token', 3600));
        });
      await openApp(tester, scale: 2, dio: dio);
      ProviderScope.containerOf(tester.element(find.byType(EstudaAiApp)))
          .read(routerProvider)
          .go('/conta');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('email-field')),
        'a@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('password-field')),
        'password',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('account-submit')));
      await tester.tap(find.byKey(const ValueKey('account-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Você está conectado'), findsOneWidget);
      expect(logins, 1);
      await tester.ensureVisible(find.text('Sair da conta'));
      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('password-field')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.ensureVisible(find.text('Recuperar senha'));
      await tester.tap(find.text('Recuperar senha'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('email-field')),
        'a@example.com',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('account-submit')));
      await tester.tap(find.byKey(const ValueKey('account-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Se houver uma conta com esse e-mail, você receberá um link de recuperação.',
        ),
        findsOneWidget,
      );
      expect(resets, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'an unavailable backend shows recovery without presenting a signed-in user',
    (tester) async {
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter(
          (r) async => jsonResponse({'code': 'UNAVAILABLE'}, 503),
        );
      await openApp(tester, dio: dio);
      ProviderScope.containerOf(tester.element(find.byType(EstudaAiApp)))
          .read(routerProvider)
          .go('/conta');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('email-field')),
        'a@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('password-field')),
        'password',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('account-submit')));
      await tester.tap(find.byKey(const ValueKey('account-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'O serviço está indisponível no momento. Tente novamente mais tarde.',
        ),
        findsOneWidget,
      );
      expect(find.text('Você está conectado'), findsNothing);
    },
  );
}
