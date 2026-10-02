import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';
import 'package:estuda_ai/features/steve/steve_api.dart';
import 'package:estuda_ai/features/steve/steve_controller.dart';
import 'package:estuda_ai/core/api_failure.dart';
import 'package:estuda_ai/features/quiz/quiz_controller.dart';

import 'contest_navigation_test.dart' show contestFixture;
import 'steve_api_test.dart' show steveResponse;
import 'steve_context_test.dart' show loggedIn, chatContext;
import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'app_test.dart' show openApp;

Map<String, dynamic> contestResponse(String id) => {
  ...steveResponse('porcentagem'),
  'topicId': id,
  'sources': [
    for (final source in contestFixture().find(id)!.module.sources)
      {'title': source.title, 'url': source.url},
  ],
};
void main() {
  testWidgets('material_quiz_steve_account_preserves_module', (tester) async {
    await openApp(tester);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    c
        .read(routerProvider)
        .go('/concursos/bb2026/bancarios/bb2026-b01/material');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Desafio 8 bits'));
    await tester.tap(find.text('Desafio 8 bits'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Começar desafio'));
    await tester.tap(find.text('Começar desafio'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      final q = c.read(quizProvider('bb2026-b01')).round.question;
      await tester.ensureVisible(find.text(q.options[q.correctIndex]));
      await tester.tap(find.text(q.options[q.correctIndex]));
      await tester.pumpAndSettle();
      final next = find.text(i == 4 ? 'Ver resultado' : 'Próxima pergunta');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Perguntar ao Steve'));
    await tester.tap(find.text('Perguntar ao Steve'));
    await tester.pumpAndSettle();
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/concursos/bb2026/bancarios/bb2026-b01/steve',
    );
    await tester.ensureVisible(find.text('Entrar para conversar'));
    await tester.tap(find.text('Entrar para conversar'));
    await tester.pumpAndSettle();
    expect(find.text('Sua conta'), findsOneWidget);
    expect(c.read(learningProvider).topicId, 'bb2026-b01');
    expect(tester.takeException(), isNull);
  });
  test('contest_reply_accepts_only_curated_sources', () async {
    final contests = contestFixture();
    final entry = LearningEntry.fromContest(
      contests,
      contests.find('bb2026-b01')!,
    );
    var response = contestResponse(entry.topic.id), calls = 0;
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        calls++;
        return jsonResponse(response);
      });
    final api = SteveApi(
      baseUrl: Uri.parse('https://study.example'),
      token: () async => 'id-token',
      findTopic: (id) => id == entry.topic.id ? entry.topic : null,
      dio: dio,
    );
    Future<dynamic> send([String? id]) => api.send(
      topicId: id ?? entry.topic.id,
      message: 'Explique',
      history: [],
      cancelToken: CancelToken(),
    );
    final reply = await send();
    expect(reply.topicId, entry.topic.id);
    expect(reply.sources.first.url, entry.topic.sources.first.url);
    response = {...contestResponse(entry.topic.id), 'topicId': 'bb2026-r01'};
    await expectLater(send(), throwsA(isA<ApiFailure>()));
    response = {
      ...contestResponse(entry.topic.id),
      'sources': [
        {'title': 'Foreign', 'url': 'https://foreign.example'},
      ],
    };
    await expectLater(send(), throwsA(isA<ApiFailure>()));
    final before = calls;
    await expectLater(send('bb2026-unknown'), throwsA(isA<ApiFailure>()));
    expect(calls, before);
  });
  for (final journey in [
    ['porcentagem', 'bb2026-b01', 'porcentagem'],
    ['bb2026-b01', 'bb2026-r01', 'bb2026-b01'],
  ]) {
    test('area_round_trip_discards_old_reply_${journey.first}', () async {
      final pending = Completer<ResponseBody>(), started = Completer<void>();
      late CancelToken cancel;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': 'internal', 'plan': 'FREE'});
          }
          if (r.path.endsWith('/messages')) {
            cancel = r.cancelToken!;
            started.complete();
            return pending.future;
          }
          return jsonResponse(authResponse('id-token', 3600));
        });
      final c = await loggedIn(dio, contests: contestFixture());
      addTearDown(c.dispose);
      c.read(learningProvider.notifier).selectTopic(journey.first);
      final old = steveProvider(chatContext(c));
      c.listen(old, (_, _) {});
      final sending = c.read(old.notifier).send('Minha dúvida');
      await started.future;
      for (final id in journey.skip(1)) {
        c.read(learningProvider.notifier).selectTopic(id);
      }
      expect(cancel.isCancelled, isTrue);
      pending.complete(
        jsonResponse(
          journey.first.startsWith('bb2026-')
              ? contestResponse(journey.first)
              : steveResponse(journey.first),
        ),
      );
      await sending;
      expect(c.read(old).turns, isEmpty);
      expect(c.read(old).quota, isNull);
      final current = steveProvider(chatContext(c));
      expect(c.read(current).turns, isEmpty);
      expect(c.read(current).quota, isNull);
    });
  }
  testWidgets('redacao_suggestions_are_formative_and_account_keeps_context', (
    tester,
  ) async {
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter(
        (r) async => r.path.endsWith('/v1/me')
            ? jsonResponse({'id': 'internal', 'plan': 'FREE'})
            : jsonResponse(authResponse('id-token', 3600)),
      );
    await openApp(tester, dio: dio, scale: 2);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    await tester.runAsync(
      () => c.read(sessionProvider.notifier).login('a@example.com', 'password'),
    );
    c.read(routerProvider).go('/concursos/bb2026/redacao/bb2026-r05/steve');
    await tester.pumpAndSettle();
    final module = c
        .read(contestCatalogProvider)
        .requireValue
        .find('bb2026-r05')!
        .module;
    for (final suggestion in module.suggestions) {
      expect(find.text(suggestion), findsOneWidget);
    }
    expect(
      find.text('Qual é a diferença entre cadeia e teia alimentar?'),
      findsNothing,
    );
    expect(find.textContaining('sem nota oficial'), findsOneWidget);
    expect(tester.takeException(), isNull);
    c.read(sessionProvider.notifier).signOut();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Entrar para conversar'));
    await tester.tap(find.text('Entrar para conversar'));
    await tester.pumpAndSettle();
    expect(c.read(learningProvider).topicId, 'bb2026-r05');
    expect(find.text('Sua conta'), findsOneWidget);
  });
}
