import '../../core/api_failure.dart';

enum StudyScope { freeStudy, bb2026 }

enum AnswerSource { quiz, review }

enum ErrorStatus { pending, reviewed }

enum ContentStatus { current, outdated }

Never invalidHistory() => throw const ApiFailure('INVALID_RESPONSE');
Map<String, dynamic> historyObject(Object? v) =>
    v is Map<String, dynamic> ? v : invalidHistory();
String historyText(Object? v) =>
    v is String && v.isNotEmpty ? v : invalidHistory();
int historyInt(Object? v, {int min = 0, int? max}) =>
    v is int && v >= min && (max == null || v <= max) ? v : invalidHistory();
T historyEnum<T extends Enum>(Object? v, List<T> values) =>
    values.where((e) => e.name == v).firstOrNull ?? invalidHistory();
String historyId(Object? value) {
  final v = historyText(value);
  if (!RegExp(r'^[a-z0-9-]{1,100}$').hasMatch(v)) invalidHistory();
  return v;
}

String historyUuid(Object? value) {
  final v = historyText(value);
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(v)) {
    invalidHistory();
  }
  return v;
}

DateTime historyTime(Object? value) {
  final text = historyText(value), p = DateTime.tryParse(text);
  if (p == null ||
      !p.isUtc ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$')
          .hasMatch(text) ||
      p.toIso8601String().substring(0, 19) != text.substring(0, 19)) {
    invalidHistory();
  }
  return p;
}

String historyDate(Object? value) {
  final v = historyText(value), p = DateTime.tryParse(v);
  if (p == null ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ||
      p.toIso8601String().substring(0, 10) != v) {
    invalidHistory();
  }
  return v;
}

List<T> historyList<T>(Object? v, T Function(Object?) parse) =>
    v is List ? List.unmodifiable(v.map(parse)) : invalidHistory();

class StudyGoalContext {
  const StudyGoalContext({
    required this.id,
    required this.scope,
    required this.timezone,
    required this.dailyTarget,
  });
  final String id, timezone;
  final StudyScope scope;
  final int dailyTarget;
  factory StudyGoalContext.fromJson(Object? value) {
    final v = historyObject(value), target = historyInt(v['dailyTarget']);
    if (![5, 10, 20].contains(target) || v['timezone'] != 'America/Sao_Paulo') {
      invalidHistory();
    }
    return StudyGoalContext(
      id: historyUuid(v['id']),
      scope: historyEnum(v['scope'], StudyScope.values),
      timezone: v['timezone'] as String,
      dailyTarget: target,
    );
  }
}

class StudyAnswerInput {
  const StudyAnswerInput({
    required this.topicId,
    required this.contentVersion,
    required this.questionId,
    required this.optionIndex,
    required this.source,
  });
  final String topicId, questionId;
  final int contentVersion, optionIndex;
  final AnswerSource source;
  Map<String, Object> toJson() => {
    'topicId': topicId,
    'contentVersion': contentVersion,
    'questionId': questionId,
    'optionIndex': optionIndex,
    'source': source.name,
  };
}

class ConfirmedAnswer {
  const ConfirmedAnswer(
    this.answerId,
    this.goalId,
    this.input,
    this.correct,
    this.receivedAt,
  );
  final String answerId, goalId;
  final StudyAnswerInput input;
  final bool correct;
  final DateTime receivedAt;
  factory ConfirmedAnswer.fromJson(
    Object? value, {
    required String answerId,
    required String goalId,
    required StudyAnswerInput input,
  }) {
    final v = historyObject(value);
    if (historyUuid(v['answerId']) != answerId ||
        historyUuid(v['goalId']) != goalId ||
        input.toJson().entries.any((e) => v[e.key] != e.value) ||
        v['correct'] is! bool) {
      invalidHistory();
    }
    return ConfirmedAnswer(
      answerId,
      goalId,
      input,
      v['correct'] as bool,
      historyTime(v['receivedAt']),
    );
  }
}

class DailyActivity {
  const DailyActivity(
    this.date,
    this.differentQuestions,
    this.attempts,
    this.correct,
  );
  final String date;
  final int differentQuestions, attempts, correct;
  factory DailyActivity.fromJson(Object? value) {
    final v = historyObject(value),
        a = historyInt(v['attempts']),
        c = historyInt(v['correct'], max: a),
        q = historyInt(v['differentQuestions'], max: a);
    return DailyActivity(historyDate(v['date']), q, a, c);
  }
}

class SubjectStats {
  const SubjectStats(this.id, this.title, this.attempts, this.correct);
  final String id, title;
  final int attempts, correct;
  factory SubjectStats.fromJson(Object? value) {
    final v = historyObject(value), a = historyInt(v['attempts'], min: 1);
    return SubjectStats(
      historyId(v['id']),
      historyText(v['title']),
      a,
      historyInt(v['correct'], max: a),
    );
  }
}

class StudyResume {
  const StudyResume(this.topicId, this.contentVersion);
  final String topicId;
  final int contentVersion;
}

class StudyDashboard {
  const StudyDashboard({
    required this.goal,
    required this.today,
    required this.pendingErrors,
    required this.activity,
    required this.subjects,
    this.resume,
  });
  final StudyGoalContext goal;
  final DailyActivity today;
  final int pendingErrors;
  final List<DailyActivity> activity;
  final List<SubjectStats> subjects;
  final StudyResume? resume;
  factory StudyDashboard.fromJson(Object? value) {
    final v = historyObject(value),
        days = historyList(v['activity'], DailyActivity.fromJson),
        today = DailyActivity.fromJson(v['today']);
    if (days.length != 7 ||
        days.last.date != today.date ||
        days.last.attempts != today.attempts ||
        days.last.correct != today.correct ||
        days.last.differentQuestions != today.differentQuestions) {
      invalidHistory();
    }
    for (var i = 1; i < days.length; i++) {
      if (DateTime.parse(days[i].date)
              .difference(DateTime.parse(days[i - 1].date))
              .inDays !=
          1) {
        invalidHistory();
      }
    }
    final r = v['resume'] == null ? null : historyObject(v['resume']);
    final subjects = historyList(v['subjects'], SubjectStats.fromJson);
    if (subjects.map((s) => s.id).toSet().length != subjects.length) {
      invalidHistory();
    }
    return StudyDashboard(
      goal: StudyGoalContext.fromJson(v['goal']),
      today: today,
      pendingErrors: historyInt(v['pendingErrors']),
      activity: days,
      subjects: subjects,
      resume: r == null
          ? null
          : StudyResume(
              historyId(r['topicId']),
              historyInt(r['contentVersion'], min: 1),
            ),
    );
  }
}

class StudyErrorItem {
  const StudyErrorItem({
    required this.topicId,
    required this.contentVersion,
    required this.questionId,
    required this.wrongCount,
    required this.firstWrongAt,
    required this.lastWrongAt,
    required this.lastAnswerAt,
    required this.lastOptionIndex,
    required this.status,
    required this.contentStatus,
  });
  final String topicId, questionId;
  final int contentVersion, wrongCount, lastOptionIndex;
  final DateTime firstWrongAt, lastWrongAt, lastAnswerAt;
  final ErrorStatus status;
  final ContentStatus contentStatus;
  String get key => '$topicId:$contentVersion:$questionId';
  factory StudyErrorItem.fromJson(Object? value) {
    final v = historyObject(value);
    return StudyErrorItem(
      topicId: historyId(v['topicId']),
      contentVersion: historyInt(v['contentVersion'], min: 1),
      questionId: historyId(v['questionId']),
      wrongCount: historyInt(v['wrongCount'], min: 1),
      firstWrongAt: historyTime(v['firstWrongAt']),
      lastWrongAt: historyTime(v['lastWrongAt']),
      lastAnswerAt: historyTime(v['lastAnswerAt']),
      lastOptionIndex: historyInt(v['lastOptionIndex'], max: 3),
      status: historyEnum(v['status'], ErrorStatus.values),
      contentStatus: historyEnum(v['contentStatus'], ContentStatus.values),
    );
  }
}

class ErrorQuery {
  const ErrorQuery({
    this.status = ErrorStatus.pending,
    this.subjectId,
    this.limit = 20,
    this.cursor,
  });
  final ErrorStatus status;
  final String? subjectId, cursor;
  final int limit;
  Map<String, Object> toJson() => {
    'status': status.name,
    'limit': limit,
    'subjectId': ?subjectId,
    'cursor': ?cursor,
  };
  ErrorQuery next(String cursor) => ErrorQuery(
    status: status,
    subjectId: subjectId,
    limit: limit,
    cursor: cursor,
  );
}

class StudyErrorPage {
  const StudyErrorPage(this.items, this.nextCursor);
  final List<StudyErrorItem> items;
  final String? nextCursor;
  factory StudyErrorPage.fromJson(Object? value) {
    final v = historyObject(value), c = v['nextCursor'];
    if (c != null &&
        (c is! String ||
            c.isEmpty ||
            c.length > 4096 ||
            !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(c))) {
      invalidHistory();
    }
    return StudyErrorPage(
      historyList(v['items'], StudyErrorItem.fromJson),
      c as String?,
    );
  }
}
