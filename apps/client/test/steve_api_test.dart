import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/core/api_failure.dart';
import 'package:estuda_ai/features/learning/study_catalog.dart';
import 'package:estuda_ai/features/steve/steve_api.dart';
import 'package:estuda_ai/features/steve/steve_models.dart';

import 'auth_api_test.dart' show ScriptAdapter, jsonResponse;

LearningCatalog testCatalog() => LearningCatalog.fromJson(
  jsonDecode(File('assets/study/catalog.json').readAsStringSync())
      as Map<String, dynamic>,
);
Map<String, dynamic> steveResponse(
  String topicId, {
  String status = 'completed',
  String text = 'Vamos aprender juntos.',
}) => {
  'topicId': topicId,
  'status': status,
  'text': text,
  'sources': [
    for (final s in testCatalog().find(topicId)!.sources)
      {'title': s.title, 'url': s.url},
  ],
  'quota': {'remaining': 9, 'resetAt': '2026-10-02T00:00:00.000Z'},
  'requestId': '6f4b7b38-7f9a-4e45-8997-747c9dbf8aa4',
};

void main() {
  test('Steve sends only topic, current message and bounded history with bearer and 45s timeout', () async {
    late RequestOptions request;
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        request = r;
        return jsonResponse(steveResponse('porcentagem'));
      });
    final api = SteveApi(
      baseUrl: Uri.parse('https://study.example'),
      token: () async => 'id-token',
      catalog: testCatalog(),
      dio: dio,
    );
    final reply = await api.send(
      topicId: 'porcentagem',
      message: 'Como calcular 20%?',
      history: const [
        ChatMessage('user', 'Antes'),
        ChatMessage('assistant', 'Explicação'),
      ],
      cancelToken: CancelToken(),
    );
    expect(request.path, 'https://study.example/v1/steve/messages');
    expect(request.headers['Authorization'], 'Bearer id-token');
    expect(request.receiveTimeout, const Duration(seconds: 45));
    expect(request.followRedirects, false);
    expect((request.data as Map).keys.toSet(), {
      'topicId',
      'message',
      'history',
    });
    expect((request.data as Map)['history'], [
      {'role': 'user', 'text': 'Antes'},
      {'role': 'assistant', 'text': 'Explicação'},
    ]);
    expect(reply.status, 'completed');
    expect(reply.quota.remaining, 9);
    expect(reply.quota.resetAt, DateTime.utc(2026, 10, 2));
    expect(reply.requestId, isNotEmpty);
    expect(
      reply.sources.single.url,
      testCatalog().find('porcentagem')!.sources.single.url,
    );
  });
  test('invalid response fields, foreign sources and mismatched topic never become answers', () {
    final topic = testCatalog().find('porcentagem')!;
    for (final change in <Map<String, dynamic>>[
      {'topicId': 'ecologia'},
      {'status': 'invented'},
      {'text': ''},
      {'text': 7},
      {'requestId': 'no-id'},
      {
        'quota': {'remaining': -1, 'resetAt': '2026-10-02T00:00:00Z'},
      },
      {
        'quota': {'remaining': 9, 'resetAt': 'tomorrow'},
      },
      {
        'sources': [
          {'title': 'Unsafe', 'url': 'https://other.example'},
        ],
      },
      {
        'sources': [
          {
            'title': topic.sources.single.title,
            'url': topic.sources.single.url.replaceFirst('https:', 'http:'),
          },
        ],
      },
    ]) {
      expect(
        () => SteveReply.fromJson({
          ...steveResponse(topic.id),
          ...change,
        }, topic: topic),
        throwsA(isA<ApiFailure>()),
      );
    }
    expect(
      SteveReply.fromJson(
        steveResponse(
          topic.id,
          status: 'refused',
          text: 'Não posso responder isso.',
        ),
        topic: topic,
      ).status,
      'refused',
    );
    expect(
      SteveReply.fromJson(
        steveResponse(topic.id, status: 'incomplete', text: ''),
        topic: topic,
      ).status,
      'incomplete',
    );
  });
  test(
    'HTTP failures are safe and anonymous requests never go to the server',
    () async {
      var status = 401, calls = 0;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          calls++;
          return jsonResponse({
            'message': 'secret upstream error',
            'resetAt': status == 429 ? '2026-10-02T00:00:00Z' : null,
          }, status);
        });
      SteveApi api(Future<String?> Function() token) => SteveApi(
        baseUrl: Uri.parse('https://study.example'),
        token: token,
        catalog: testCatalog(),
        dio: dio,
      );
      await expectLater(
        api(() async => null).send(
          topicId: 'porcentagem',
          message: 'Olá',
          history: [],
          cancelToken: CancelToken(),
        ),
        throwsA(isA<ApiFailure>()),
      );
      expect(calls, 0);
      for (final item in [
        (401, 'UNAUTHENTICATED'),
        (429, 'DAILY_LIMIT'),
        (503, 'UNAVAILABLE'),
      ]) {
        status = item.$1;
        await expectLater(
          api(() async => 'token').send(
            topicId: 'porcentagem',
            message: 'Olá',
            history: [],
            cancelToken: CancelToken(),
          ),
          throwsA(isA<ApiFailure>().having((e) => e.code, 'code', item.$2)),
        );
      }
    },
  );
}
