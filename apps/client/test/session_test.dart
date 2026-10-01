import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/core/api_client.dart';
import 'package:estuda_ai/core/api_origin.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';

import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;

void main() {
  test('simultaneous refresh shares one request and logout discards its completion', () async {
    var now = DateTime.utc(2026, 10, 1), refreshes = 0;
    final pending = Completer<ResponseBody>();
    final refreshStarted = Completer<void>();
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        if (r.path.endsWith('/v1/me')) {
          return jsonResponse({'id': 'internal', 'plan': 'FREE'});
        }
        if (r.path.endsWith('/refresh')) {
          refreshes++;
          refreshStarted.complete();
          return pending.future;
        }
        return jsonResponse(authResponse('original-token'));
      });
    final c = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        sessionClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    final controller = c.read(sessionProvider.notifier);
    await controller.login('a@example.com', 'password');
    expect(c.read(sessionProvider).profile?.id, 'internal');
    now = now.add(const Duration(seconds: 45));
    final first = controller.accessToken(), second = controller.accessToken();
    await refreshStarted.future;
    expect(refreshes, 1);
    pending.complete(jsonResponse(authResponse('renewed-token', 3600)));
    expect(await first, 'renewed-token');
    expect(await second, 'renewed-token');
    controller.signOut();
    expect(await controller.accessToken(), isNull);
    expect(c.read(sessionProvider).status, SessionStatus.signedOut);
  });
  test('logout while refresh is pending never restores a session', () async {
    var now = DateTime.utc(2026, 10, 1);
    final pending = Completer<ResponseBody>();
    final refreshStarted = Completer<void>();
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        if (r.path.endsWith('/v1/me')) {
          return jsonResponse({'id': 'internal', 'plan': 'FREE'});
        }
        if (r.path.endsWith('/refresh')) {
          refreshStarted.complete();
          return pending.future;
        }
        return jsonResponse(authResponse('original-token'));
      });
    final c = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        sessionClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    final controller = c.read(sessionProvider.notifier);
    await controller.login('a@example.com', 'password');
    now = now.add(const Duration(seconds: 45));
    final future = controller.accessToken();
    await refreshStarted.future;
    controller.signOut();
    pending.complete(jsonResponse(authResponse('late-token', 3600)));
    expect(await future, isNull);
    expect(c.read(sessionProvider).status, SessionStatus.signedOut);
    expect(await controller.accessToken(), isNull);
  });
  test('temporary refresh failure preserves valid credentials but never sends an expired token', () async {
    var now = DateTime.utc(2026, 10, 1), status = 503;
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        if (r.path.endsWith('/v1/me')) {
          return jsonResponse({'id': 'internal', 'plan': 'FREE'});
        }
        if (r.path.endsWith('/refresh')) {
          return jsonResponse({'code': 'UNAVAILABLE'}, status);
        }
        return jsonResponse(authResponse('original-token'));
      });
    final c = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        sessionClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    final controller = c.read(sessionProvider.notifier);
    await controller.login('a@example.com', 'password');
    now = now.add(const Duration(seconds: 45));
    expect(await controller.accessToken(), 'original-token');
    expect(c.read(sessionProvider).status, SessionStatus.refreshUnavailable);
    now = now.add(const Duration(seconds: 20));
    await expectLater(controller.accessToken(), throwsA(isA<ApiFailure>()));
    expect(c.read(sessionProvider).profile?.id, 'internal');
    status = 401;
    expect(await controller.accessToken(), isNull);
    expect(c.read(sessionProvider).status, SessionStatus.signedOut);
  });
  test('temporary profile failure can be resumed without claiming a verified student', () async {
    var meStatus = 503, logins = 0;
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        if (r.path.endsWith('/v1/me')) {
          return jsonResponse(
            meStatus == 200
                ? {'id': 'internal', 'plan': 'FREE'}
                : {'code': 'UNAVAILABLE'},
            meStatus,
          );
        }
        logins++;
        return jsonResponse(authResponse('id-token', 3600));
      });
    final c = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dio)],
    );
    addTearDown(c.dispose);
    final controller = c.read(sessionProvider.notifier);
    await controller.login('a@example.com', 'password');
    expect(c.read(sessionProvider).profile, isNull);
    expect(c.read(sessionProvider).status, SessionStatus.refreshUnavailable);
    meStatus = 200;
    await controller.retryProfile();
    expect(c.read(sessionProvider).profile?.id, 'internal');
    expect(logins, 1);
  });
}
