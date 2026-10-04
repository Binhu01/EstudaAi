import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/core/api_failure.dart';
import 'package:estuda_ai/features/study_history/study_history_models.dart';

import 'helpers/study_history_fixtures.dart';

Map<String, Object> progressReply() => {
  'practicedQuestions': 8,
  'catalogQuestions': 30,
  'reviewedErrors': 2,
  'correctReviewQuestions': 3,
  'activeDays': 7,
  'currentStreak': 2,
  'bestStreak': 4,
};

void main() {
  test('legacy dashboard and subject leave unsupported progress absent', () {
    final dashboard = StudyDashboard.fromJson(dashboardReply());
    expect(dashboard.progress, isNull);
    expect(dashboard.subjects.first.progress, isNull);
  });

  test(
    'new dashboard preserves confirmed distinct progress and consistency',
    () {
      final reply = dashboardReply()..['progress'] = progressReply();
      final subjects = reply['subjects'] as List;
      (subjects.first as Map)['progress'] = {
        'practicedQuestions': 2,
        'latestCorrectQuestions': 1,
        'catalogQuestions': 10,
      };
      final dashboard = StudyDashboard.fromJson(reply);
      expect(dashboard.progress!.practicedQuestions, 8);
      expect(dashboard.progress!.correctReviewQuestions, 3);
      expect(dashboard.progress!.reviewedErrors, 2);
      expect(dashboard.progress!.activeDays, 7);
      expect(dashboard.progress!.currentStreak, 2);
      expect(dashboard.progress!.bestStreak, 4);
      expect(dashboard.subjects.first.progress!.practicedQuestions, 2);
      expect(dashboard.subjects.first.progress!.latestCorrectQuestions, 1);
      expect(dashboard.subjects.first.progress!.catalogQuestions, 10);
    },
  );

  test('inconsistent or malformed aggregate counts are rejected', () {
    for (final change in [
      {'practicedQuestions': 31},
      {'reviewedErrors': 9},
      {'correctReviewQuestions': 9},
      {'currentStreak': 5},
      {'bestStreak': 8},
      {'activeDays': -1},
      {'currentStreak': 1.5},
    ]) {
      final reply = dashboardReply()
        ..['progress'] = {...progressReply(), ...change};
      expect(() => StudyDashboard.fromJson(reply), throwsA(isA<ApiFailure>()));
    }
  });

  test('subject progress cannot exceed its catalog or answered questions', () {
    for (final progress in [
      {
        'practicedQuestions': 11,
        'latestCorrectQuestions': 1,
        'catalogQuestions': 10,
      },
      {
        'practicedQuestions': 2,
        'latestCorrectQuestions': 3,
        'catalogQuestions': 10,
      },
      {
        'practicedQuestions': 4,
        'latestCorrectQuestions': 1,
        'catalogQuestions': 10,
      },
    ]) {
      final reply = dashboardReply();
      ((reply['subjects'] as List).first as Map)['progress'] = progress;
      expect(() => StudyDashboard.fromJson(reply), throwsA(isA<ApiFailure>()));
    }
  });
}
