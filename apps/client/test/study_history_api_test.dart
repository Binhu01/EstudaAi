import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/core/api_failure.dart';
import 'package:estuda_ai/core/study_context.dart';
import 'package:estuda_ai/features/study_history/study_history_api.dart';
import 'package:estuda_ai/features/study_history/study_history_models.dart';

import 'auth_api_test.dart' show ScriptAdapter, jsonResponse;
import 'helpers/study_history_fixtures.dart';

void main() {
  test('delayed_token_after_account_change_sends_nothing', () async {
    final pending = Completer<String?>(), tokenStarted = Completer<void>();
    var current = true;
    var sent = 0;
    final api = StudyHistoryApi(
      baseUrl: Uri.parse('https://study.example'),
      findEntry: historyEntry,
      token: () {
        tokenStarted.complete();
        return pending.future;
      },
      dio: Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          sent++;
          return jsonResponse(goalReply());
        }),
    );
    final request = api.ensureContext(
      StudyScope.freeStudy,
      cancelToken: CancelToken(),
      stillCurrent: () => current,
    );
    final check = expectLater(
      request,
      throwsA(isA<ApiFailure>().having((e) => e.code, 'code', 'CANCELLED')),
    );
    await tokenStarted.future;
    current = false;
    pending.complete('new-token');
    await check;
    expect(sent, 0);
  });
  test('foreign_goal_or_malformed_reply_is_rejected', () async {
    for (final change in <Map<String, Object?>>[
      {'goal': goalReply('bb2026')},
      {'pendingErrors': -1},
      {
        'today': {
          'date': '2026-10-02',
          'differentQuestions': 8,
          'attempts': 3,
          'correct': 1,
        },
      },
      {'activity': []},
      {
        'resume': {'topicId': 'missing', 'contentVersion': 1},
      },
    ]) {
      final api = StudyHistoryApi(
        baseUrl: Uri.parse('https://study.example'),
        findEntry: historyEntry,
        token: () async => 'token',
        dio: Dio()
          ..httpClientAdapter = ScriptAdapter(
            (r) async => jsonResponse({...dashboardReply(), ...change}),
          ),
      );
      await expectLater(
        api.readDashboard(
          const StudyContext(historyUser, historyGoal),
          StudyScope.freeStudy,
          cancelToken: CancelToken(),
          stillCurrent: () => true,
        ),
        throwsA(isA<ApiFailure>()),
      );
    }
  });
  test('ack matches captured intent and old acknowledged versions are accepted on retry', () async {
    final q = historyEntry('porcentagem')!.topic.questions.first;
    final input = StudyAnswerInput(
      topicId: 'porcentagem',
      contentVersion: 1,
      questionId: q.id,
      optionIndex: 2,
      source: AnswerSource.quiz,
    );
    Map<String, Object?> reply = {
      ...input.toJson(),
      'answerId': historyAnswer,
      'goalId': historyGoal,
      'correct': false,
      'receivedAt': '2026-10-01T12:00:00.000Z',
    };
    final api = StudyHistoryApi(
      baseUrl: Uri.parse('https://study.example'),
      findEntry: (id) => null,
      token: () async => 'token',
      dio: Dio()
        ..httpClientAdapter = ScriptAdapter((r) async => jsonResponse(reply)),
    );
    final answer = await api.confirmAnswer(
      const StudyContext(historyUser, historyGoal),
      StudyScope.freeStudy,
      historyAnswer,
      input,
      retry: true,
      cancelToken: CancelToken(),
      stillCurrent: () => true,
    );
    expect(answer.receivedAt, DateTime.utc(2026, 10, 1, 12));
    reply = {...reply, 'optionIndex': 3};
    await expectLater(
      api.confirmAnswer(
        const StudyContext(historyUser, historyGoal),
        StudyScope.freeStudy,
        historyAnswer,
        input,
        retry: true,
        cancelToken: CancelToken(),
        stillCurrent: () => true,
      ),
      throwsA(isA<ApiFailure>()),
    );
  });
  test(
    '409 codes remain bounded and session absence sends no request',
    () async {
      for (final code in ['CONFLICT', 'CONTENT_CHANGED', 'unsafe']) {
        final api = StudyHistoryApi(
          baseUrl: Uri.parse('https://study.example'),
          findEntry: historyEntry,
          token: () async => 'token',
          dio: Dio()
            ..httpClientAdapter = ScriptAdapter(
              (r) async => jsonResponse({'code': code}, 409),
            ),
        );
        await expectLater(
          api.ensureContext(
            StudyScope.freeStudy,
            cancelToken: CancelToken(),
            stillCurrent: () => true,
          ),
          throwsA(
            isA<ApiFailure>().having(
              (e) => e.code,
              'code',
              code == 'unsafe' ? 'UNAVAILABLE' : code,
            ),
          ),
        );
      }
      var sent = 0;
      final api = StudyHistoryApi(
        baseUrl: Uri.parse('https://study.example'),
        findEntry: historyEntry,
        token: () async => null,
        dio: Dio()
          ..httpClientAdapter = ScriptAdapter((r) async {
            sent++;
            return jsonResponse(goalReply());
          }),
      );
      await expectLater(
        api.ensureContext(
          StudyScope.freeStudy,
          cancelToken: CancelToken(),
          stillCurrent: () => true,
        ),
        throwsA(isA<ApiFailure>()),
      );
      expect(sent, 0);
    },
  );
}
