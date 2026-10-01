import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/core/api_client.dart';
import 'package:estuda_ai/core/models/user_profile.dart';

class ResponseAdapter implements HttpClientAdapter {
  ResponseAdapter(this.status, this.body);
  final int status;
  final String body;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FailureAdapter implements HttpClientAdapter {
  FailureAdapter(this.type);
  final DioExceptionType type;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: type,
      error: StateError('private network detail'),
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'timeouts, network failures and cancellation have safe typed codes',
    () async {
      for (final entry in {
        DioExceptionType.connectionTimeout: 'TIMEOUT',
        DioExceptionType.connectionError: 'UNAVAILABLE',
        DioExceptionType.cancel: 'CANCELLED',
      }.entries) {
        final dio = Dio()..httpClientAdapter = FailureAdapter(entry.key);
        final client = ApiClient(
          baseUrl: Uri.parse('https://study.example'),
          token: () async => 'token',
          dio: dio,
        );
        await expectLater(
          client.readMe(),
          throwsA(
            isA<ApiFailure>().having(
              (error) => error.code,
              'code',
              entry.value,
            ),
          ),
        );
      }
    },
  );
  test('client sends session token to configured API and parses the server profile', () async {
    final adapter = ResponseAdapter(
      200,
      '{"id":"server-owned-id","plan":"FREE"}',
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: Uri.parse('https://study.example'),
      token: () async => 'id-token',
      dio: dio,
    );
    final profile = await client.readMe();
    expect(profile.id, 'server-owned-id');
    expect(profile.plan, SubscriptionPlan.free);
    expect(adapter.request?.uri.toString(), 'https://study.example/v1/me');
    expect(adapter.request?.headers['Authorization'], 'Bearer id-token');
    expect(adapter.request?.connectTimeout, const Duration(seconds: 10));
    expect(adapter.request?.followRedirects, false);
  });
  test(
    'missing session and unauthorized response become safe typed failures',
    () async {
      final dio = Dio()
        ..httpClientAdapter = ResponseAdapter(
          401,
          '{"message":"private SECRET"}',
        );
      final client = ApiClient(
        baseUrl: Uri.parse('https://study.example'),
        token: () async => null,
        dio: dio,
      );
      await expectLater(
        client.readMe(),
        throwsA(
          isA<ApiFailure>().having((e) => e.code, 'code', 'UNAUTHENTICATED'),
        ),
      );
      final signedIn = ApiClient(
        baseUrl: Uri.parse('https://study.example'),
        token: () async => 'token',
        dio: dio,
      );
      await expectLater(
        signedIn.readMe(),
        throwsA(
          isA<ApiFailure>().having((e) => e.code, 'code', 'UNAUTHENTICATED'),
        ),
      );
    },
  );
  test('malformed response and unsafe API origin are rejected', () async {
    final dio = Dio()
      ..httpClientAdapter = ResponseAdapter(200, '{"id":42,"plan":"ADMIN"}');
    final client = ApiClient(
      baseUrl: Uri.parse('https://study.example'),
      token: () async => 'token',
      dio: dio,
    );
    await expectLater(
      client.readMe(),
      throwsA(
        isA<ApiFailure>().having((e) => e.code, 'code', 'INVALID_RESPONSE'),
      ),
    );
    expect(
      () => ApiClient(
        baseUrl: Uri.parse('http://study.example'),
        token: () async => null,
      ),
      throwsArgumentError,
    );
  });
}
