import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/core/api_origin.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/study_history/study_context_controller.dart';
import 'package:estuda_ai/features/study_history/study_history_api.dart';
import 'package:estuda_ai/features/study_history/study_history_models.dart';
import 'package:estuda_ai/features/study_history/answer_submission.dart';

import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'helpers/study_history_fixtures.dart';

void main() {
  test(
    'logout clears private context and return to same scope rejects old result',
    () async {
      final pending = Completer<ResponseBody>(), started = Completer<void>();
      var ensures = 0;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': historyUser, 'plan': 'FREE'});
          }
          if (r.path.endsWith('/ensure')) {
            ensures++;
            if (ensures == 1) {
              started.complete();
              return pending.future;
            }
            return jsonResponse(goalReply());
          }
          return jsonResponse(authResponse('token', 3600));
        });
      final c = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(c.dispose);
      final session = c.read(sessionProvider.notifier);
      await session.login('a@example.com', 'password');
      final controller = c.read(studyContextProvider.notifier);
      final first = controller.ensureActive();
      await started.future;
      session.signOut();
      expect(c.read(studyContextProvider).snapshot, isNull);
      await session.login('a@example.com', 'password');
      pending.complete(jsonResponse(goalReply()));
      expect(await first, isNull);
      expect(await controller.ensureActive(), isNotNull);
      expect(
        c.read(studyContextProvider).snapshot?.context.userId,
        historyUser,
      );
      session.signOut();
      expect(c.read(studyContextProvider).snapshot, isNull);
    },
  );
  test(
    'retry reuses UUID and payload and continue never schedules another write',
    () async {
      final requests = <RequestOptions>[];
      var status = 503;
      final dio = Dio()
        ..httpClientAdapter = ScriptAdapter((r) async {
          if (r.path.endsWith('/v1/me')) {
            return jsonResponse({'id': historyUser, 'plan': 'FREE'});
          }
          if (r.path.endsWith('/ensure')) return jsonResponse(goalReply());
          if (r.method == 'PUT') {
            requests.add(r);
            return status == 503
                ? jsonResponse({'code': 'UNAVAILABLE'}, 503)
                : jsonResponse({
                    ...r.data as Map,
                    'answerId': r.uri.pathSegments.last,
                    'goalId': historyGoal,
                    'correct': true,
                    'receivedAt': '2026-10-02T12:00:00.000Z',
                  });
          }
          return jsonResponse(authResponse('token', 3600));
        });
      final c = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(dio),
          catalogProvider.overrideWith((ref) async => historyCatalog()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(catalogProvider.future);
      await c.read(sessionProvider.notifier).login('a@example.com', 'password');
      final context = c.read(studyContextProvider.notifier);
      final submission = AnswerSubmissionController(
        api: () => c.read(studyHistoryApiProvider),
        capture: context.capture,
        stillCurrent: context.isCurrent,
      );
      addTearDown(submission.cancel);
      final q = historyEntry('porcentagem')!.topic.questions.first;
      final input = StudyAnswerInput(
        topicId: 'porcentagem',
        contentVersion: 1,
        questionId: q.id,
        optionIndex: q.correctIndex,
        source: AnswerSource.quiz,
      );
      await submission.submit(input);
      expect(submission.state.status, SubmissionStatus.unconfirmed);
      status = 200;
      await submission.retry();
      expect(submission.state.status, SubmissionStatus.confirmed);
      expect(requests[0].uri, requests[1].uri);
      expect(requests[0].data, requests[1].data);
      expect(
        RegExp(r'^[0-9a-f-]{36}$').hasMatch(requests[0].uri.pathSegments.last),
        true,
      );
      submission.cancel();
      status = 503;
      await submission.submit(input);
      submission.continueStudy();
      expect(submission.state.status, SubmissionStatus.idle);
      expect(requests.length, 3);
    },
  );
}
