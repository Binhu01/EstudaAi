import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/auth/auth_api.dart';
import 'package:estuda_ai/features/auth/auth_models.dart';
import 'package:estuda_ai/core/api_client.dart';

class ScriptAdapter implements HttpClientAdapter {
  ScriptAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions) handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
Map<String, Object> authResponse(String token, [int expiry = 60]) => {
  'idToken': token,
  'refreshToken': 'refresh-token',
  'expiresInSeconds': expiry,
};
void main() {
  test('AuthApi validates sessions, preserves passwords and confirms reset generically', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        requests.add(r);
        return jsonResponse(
          r.path.endsWith('password-reset')
              ? {'accepted': true}
              : authResponse('id-token'),
        );
      });
    final api = AuthApi(baseUrl: Uri.parse('https://study.example'), dio: dio);
    expect(
      (await api.login('a@example.com', ' pass word ')).idToken,
      'id-token',
    );
    expect((requests.first.data as Map)['password'], ' pass word ');
    expect(requests.first.followRedirects, isFalse);
    await api.resetPassword('a@example.com');
    expect(requests.last.path, 'https://study.example/v1/auth/password-reset');
  });
  test(
    'malformed session fields and expiry are rejected before entering memory',
    () {
      for (final mutation in [
        <String, Object>{'expiresInSeconds': 0},
        {'expiresInSeconds': 86401},
        {'idToken': 'with space'},
        {'refreshToken': ''},
        {'expiresInSeconds': '60'},
      ]) {
        expect(
          () => AuthSession.fromJson({...authResponse('token'), ...mutation}),
          throwsA(isA<ApiFailure>()),
        );
      }
    },
  );
}
