import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/core/api_origin.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/steve/steve_controller.dart';
import 'package:estuda_ai/features/steve/steve_models.dart';

import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'steve_api_test.dart' show testCatalog, steveResponse;

Future<ProviderContainer> loggedIn(Dio dio) async {
  final c = ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(dio),
      catalogProvider.overrideWith((ref) async => testCatalog()),
      steveClockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 1, 12)),
    ],
  );
  await c.read(catalogProvider.future);
  await c.read(sessionProvider.notifier).login('a@example.com', 'password');
  return c;
}

SteveContext chatContext(ProviderContainer c) => (
  topicId: c.read(learningProvider).topicId,
  topicGeneration: c.read(learningProvider).generation,
  userId: c.read(sessionProvider).profile!.id,
  sessionGeneration: c.read(sessionProvider).generation,
);

void main() {
  test('a failed sent attempt invalidates the confirmed quota and a daily limit never leaves a positive balance', () async {
    var status = 200;
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        if (r.path.endsWith('/v1/me')) {
          return jsonResponse({'id': 'internal', 'plan': 'FREE'});
        }
        if (r.path.endsWith('/messages')) {
          return jsonResponse(
            status == 200
                ? steveResponse('porcentagem')
                : {'resetAt': status == 429 ? '2026-10-02T00:00:00Z' : null},
            status,
          );
        }
        return jsonResponse(authResponse('id-token', 3600));
      });
    final c = await loggedIn(dio);
    addTearDown(c.dispose);
    final provider = steveProvider(chatContext(c));
    c.listen(provider, (_, _) {});
    final controller = c.read(provider.notifier);
    await controller.send('Primeira');
    expect(c.read(provider).quota?.remaining, 9);
    status = 503;
    await controller.send('Falhou após enviar');
    expect(c.read(provider).quota, isNull);
    expect(c.read(provider).turns.length, 1);
    status = 429;
    await controller.send('Limite');
    expect(c.read(provider).error?.code, 'DAILY_LIMIT');
    expect(c.read(provider).quota, isNull);
  });
  for (final action in [
    'topic',
    'round-trip',
    'logout',
    'account',
    'new',
    'dispose',
  ]) {
    test('$action cancels pending Steve and drops late responses', () async {
      final pending = Completer<ResponseBody>(), started = Completer<void>();
      late CancelToken cancel;
      var calls = 0;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': 'internal', 'plan': 'FREE'});
          }
          if (r.path.endsWith('/messages')) {
            calls++;
            cancel = r.cancelToken!;
            started.complete();
            return pending.future;
          }
          return jsonResponse(authResponse('id-token', 3600));
        });
      final c = await loggedIn(dio);
      addTearDown(c.dispose);
      final provider = steveProvider(chatContext(c));
      final subscription = c.listen(provider, (_, _) {});
      final controller = c.read(provider.notifier);
      final future = controller.send('Como calcular porcentagem?');
      await started.future;
      await controller.send('Segundo pedido');
      expect(calls, 1);
      switch (action) {
        case 'topic':
          c.read(learningProvider.notifier).selectTopic('ecologia');
        case 'round-trip':
          c.read(learningProvider.notifier).selectTopic('ecologia');
          c.read(learningProvider.notifier).selectTopic('porcentagem');
        case 'logout':
          c.read(sessionProvider.notifier).signOut();
        case 'account':
          await c
              .read(sessionProvider.notifier)
              .login('b@example.com', 'password');
        case 'new':
          controller.newConversation();
        case 'dispose':
          subscription.close();
          await c.pump();
      }
      expect(cancel.isCancelled, true);
      pending.complete(jsonResponse(steveResponse('porcentagem')));
      await future;
      if (action != 'dispose') expect(c.read(provider).messages, isEmpty);
    });
  }
  test('history keeps four complete pairs within 12000 and excludes incomplete or oversized replies', () async {
    final requests = <RequestOptions>[];
    var status = 'completed', text = 'x' * 1800;
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        if (r.path.endsWith('/v1/me')) {
          return jsonResponse({'id': 'internal', 'plan': 'FREE'});
        }
        if (r.path.endsWith('/messages')) {
          requests.add(r);
          return jsonResponse(
            steveResponse('porcentagem', status: status, text: text),
          );
        }
        return jsonResponse(authResponse('id-token', 3600));
      });
    final c = await loggedIn(dio);
    addTearDown(c.dispose);
    final provider = steveProvider(chatContext(c));
    c.listen(provider, (_, _) {});
    final controller = c.read(provider.notifier);
    for (var i = 0; i < 6; i++) {
      await controller.send('$i${'q' * 1800}');
    }
    final history = (requests.last.data as Map)['history'] as List;
    expect(history.length, 6); // Three whole pairs fit the character budget.
    expect(history.first['text'], startsWith('2'));
    expect(
      history.fold<int>(0, (n, m) => n + (m['text'] as String).length),
      lessThanOrEqualTo(12000),
    );
    status = 'incomplete';
    await controller.send('Incompleta');
    status = 'completed';
    text = 'l' * 2500;
    await controller.send('Longa');
    text = 'Resposta';
    await controller.send('Atual');
    final sent = ((requests.last.data as Map)['history'] as List)
        .map((m) => m['text'])
        .toList();
    expect(sent, isNot(contains('Incompleta')));
    expect(sent, isNot(contains('Longa')));
    expect(sent, isNot(contains('Atual')));
    expect(
      boundedHistory([
        for (var i = 0; i < 6; i++) ...[
          ChatMessage('user', '$i'),
          ChatMessage('assistant', 'r$i'),
        ],
      ]).length,
      8,
    );
    controller.newConversation();
    expect(c.read(provider).messages, isEmpty);
  });
  test(
    '401 signs out and 503 preserves the question without an invented answer',
    () async {
      var status = 503;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': 'internal', 'plan': 'FREE'});
          }
          if (r.path.endsWith('/messages')) {
            return jsonResponse({'code': 'UNAVAILABLE'}, status);
          }
          return jsonResponse(authResponse('id-token', 3600));
        });
      final c = await loggedIn(dio);
      addTearDown(c.dispose);
      final provider = steveProvider(chatContext(c));
      c.listen(provider, (_, _) {});
      final controller = c.read(provider.notifier);
      await controller.send('Dúvida');
      expect(c.read(provider).messages, isEmpty);
      expect(c.read(provider).error?.code, 'UNAVAILABLE');
      status = 401;
      await controller.send('Dúvida');
      expect(c.read(sessionProvider).isAuthenticated, false);
    },
  );
}
