import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:estuda_ai/core/api_origin.dart';
import 'package:estuda_ai/features/settings/settings_controller.dart';
import 'package:estuda_ai/features/auth/session_controller.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/quiz/quiz_controller.dart';
import 'package:estuda_ai/features/study_history/answer_submission.dart';

import 'auth_api_test.dart' show ScriptAdapter, jsonResponse, authResponse;
import 'helpers/study_history_fixtures.dart';

void main() {
  test('each answer writes once, blocks next until acknowledgement and retries same intent', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sent = <RequestOptions>[];
    final pending = Completer<ResponseBody>(), started = Completer<void>();
    var fail = true;
    final dio = Dio()
      ..httpClientAdapter = ScriptAdapter((r) async {
        if (r.path.endsWith('/v1/me')) {
          return jsonResponse({'id': historyUser, 'plan': 'FREE'});
        }
        if (r.path.endsWith('/ensure')) return jsonResponse(goalReply());
        if (r.method == 'PUT') {
          sent.add(r);
          if (sent.length == 1) {
            started.complete();
            return pending.future;
          }
          return fail
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
        preferencesProvider.overrideWithValue(prefs),
        catalogProvider.overrideWith((ref) async => historyCatalog()),
      ],
    );
    addTearDown(c.dispose);
    await c.read(catalogProvider.future);
    await c.read(sessionProvider.notifier).login('a@example.com', 'password');
    final keep = c.listen(quizProvider('porcentagem'), (_, next) {});
    addTearDown(keep.close);
    final controller = c.read(quizProvider('porcentagem').notifier);
    controller.start();
    final q = c.read(quizProvider('porcentagem')).round.question;
    controller.answer(q.correctIndex);
    controller.answer(0);
    await started.future;
    expect(sent.length, 1);
    expect(
      c.read(quizProvider('porcentagem')).history.status,
      SubmissionStatus.sending,
    );
    final original = historyEntry('porcentagem')!.topic.questions
        .firstWhere((v) => v.id == q.id);
    expect((sent.first.data as Map)['optionIndex'], original.correctIndex);
    controller.next();
    expect(c.read(quizProvider('porcentagem')).round.questionIndex, 0);
    pending.complete(jsonResponse({'code': 'UNAVAILABLE'}, 503));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(
      c.read(quizProvider('porcentagem')).history.status,
      SubmissionStatus.unconfirmed,
    );
    fail = false;
    await controller.retryHistory();
    expect(sent[0].uri, sent[1].uri);
    expect(sent[0].data, sent[1].data);
    expect(
      c.read(quizProvider('porcentagem')).history.status,
      SubmissionStatus.confirmed,
    );
    controller.next();
    expect(c.read(quizProvider('porcentagem')).round.questionIndex, 1);
    fail = true;
    controller.answer(0);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    controller.continueStudy();
    controller.next();
    expect(sent.length, 3);
    expect(c.read(quizProvider('porcentagem')).round.questionIndex, 2);
    c.read(sessionProvider.notifier).signOut();
    controller.answer(0);
    expect(sent.length, 3);
  });
}
