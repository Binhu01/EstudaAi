import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_failure.dart';
import '../../core/api_origin.dart';
import '../../core/study_context.dart';
import '../auth/session_controller.dart';
import '../learning/learning_entry.dart';
import '../learning/learning_catalog_providers.dart';
import 'study_history_models.dart';

final studyHistoryApiProvider = Provider<StudyHistoryApi>(
  (ref) => StudyHistoryApi(
    baseUrl: ref.watch(apiOriginProvider),
    dio: ref.watch(dioProvider),
    token: ref.read(sessionProvider.notifier).accessToken,
    findEntry: (id) => ref.read(learningEntryProvider(id)).asData?.value,
  ),
);

class StudyHistoryApi {
  StudyHistoryApi({
    required Uri baseUrl,
    required this.token,
    required this.findEntry,
    Dio? dio,
  }) : baseUrl = validateApiOrigin(baseUrl),
       dio = dio ?? Dio();
  final Uri baseUrl;
  final Dio dio;
  final Future<String?> Function() token;
  final LearningEntry? Function(String) findEntry;
  void _current(CancelToken cancel, bool Function() current) {
    if (cancel.isCancelled || !current()) throw const ApiFailure('CANCELLED');
  }

  Future<Object?> _request(
    String method,
    String path, {
    Object? data,
    Map<String, Object>? query,
    required CancelToken cancelToken,
    required bool Function() stillCurrent,
  }) async {
    _current(cancelToken, stillCurrent);
    final bearer = await token();
    _current(cancelToken, stillCurrent);
    if (bearer == null ||
        !RegExp(r'^[A-Za-z0-9._~-]{1,8192}$').hasMatch(bearer)) {
      throw const ApiFailure('UNAUTHENTICATED');
    }
    try {
      _current(cancelToken, stillCurrent);
      final response = await dio.request<Object?>(
        baseUrl.resolve(path).toString(),
        data: data,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $bearer'},
          followRedirects: false,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      _current(cancelToken, stillCurrent);
      return response.data;
    } on DioException catch (error) {
      throw apiFailure(error);
    }
  }

  bool _belongs(LearningEntry entry, StudyScope scope) =>
      scope == StudyScope.freeStudy
      ? entry.area == LearningArea.freeStudy
      : entry.courseId == 'bb2026';
  Future<StudyGoalContext> ensureContext(
    StudyScope scope, {
    required CancelToken cancelToken,
    required bool Function() stillCurrent,
  }) async {
    final g = StudyGoalContext.fromJson(
      await _request(
        'POST',
        '/v1/study-contexts/${scope.name}/ensure',
        data: <String, Object>{},
        cancelToken: cancelToken,
        stillCurrent: stillCurrent,
      ),
    );
    if (g.scope != scope) invalidHistory();
    return g;
  }

  Future<StudyGoalContext> setDailyTarget(
    StudyContext context,
    StudyScope scope,
    int target, {
    required CancelToken cancelToken,
    required bool Function() stillCurrent,
  }) async {
    if (![5, 10, 20].contains(target)) throw const ApiFailure('INVALID_INPUT');
    historyUuid(context.goalId);
    final g = StudyGoalContext.fromJson(
      await _request(
        'PATCH',
        '/v1/goals/${context.goalId}/daily-target',
        data: {'dailyTarget': target},
        cancelToken: cancelToken,
        stillCurrent: stillCurrent,
      ),
    );
    if (g.id != context.goalId || g.scope != scope || g.dailyTarget != target) {
      invalidHistory();
    }
    return g;
  }

  Future<ConfirmedAnswer> confirmAnswer(
    StudyContext context,
    StudyScope scope,
    String answerId,
    StudyAnswerInput input, {
    bool retry = false,
    required CancelToken cancelToken,
    required bool Function() stillCurrent,
  }) async {
    historyUuid(context.goalId);
    historyUuid(answerId);
    if (!retry) {
      final e = findEntry(input.topicId);
      if (e == null ||
          !_belongs(e, scope) ||
          e.contentVersion != input.contentVersion ||
          !e.topic.questions.any((q) => q.id == input.questionId) ||
          input.optionIndex < 0 ||
          input.optionIndex > 3) {
        throw const ApiFailure('INVALID_INPUT');
      }
    }
    return ConfirmedAnswer.fromJson(
      await _request(
        'PUT',
        '/v1/goals/${context.goalId}/answers/$answerId',
        data: input.toJson(),
        cancelToken: cancelToken,
        stillCurrent: stillCurrent,
      ),
      answerId: answerId,
      goalId: context.goalId,
      input: input,
    );
  }

  Future<StudyDashboard> readDashboard(
    StudyContext context,
    StudyScope scope, {
    required CancelToken cancelToken,
    required bool Function() stillCurrent,
  }) async {
    historyUuid(context.goalId);
    final d = StudyDashboard.fromJson(
      await _request(
        'GET',
        '/v1/goals/${context.goalId}/dashboard',
        cancelToken: cancelToken,
        stillCurrent: stillCurrent,
      ),
    );
    if (d.goal.id != context.goalId || d.goal.scope != scope) invalidHistory();
    if (d.resume case final resume?) {
      final e = findEntry(resume.topicId);
      if (e == null ||
          !_belongs(e, scope) ||
          e.contentVersion != resume.contentVersion) {
        invalidHistory();
      }
    }
    return d;
  }

  Future<StudyErrorPage> listErrors(
    StudyContext context,
    StudyScope scope,
    ErrorQuery query, {
    required CancelToken cancelToken,
    required bool Function() stillCurrent,
  }) async {
    historyUuid(context.goalId);
    if (query.limit < 1 || query.limit > 50) {
      throw const ApiFailure('INVALID_INPUT');
    }
    final p = StudyErrorPage.fromJson(
      await _request(
        'GET',
        '/v1/goals/${context.goalId}/errors',
        query: query.toJson(),
        cancelToken: cancelToken,
        stillCurrent: stillCurrent,
      ),
    );
    if (p.items.length > query.limit ||
        p.items.map((e) => e.key).toSet().length != p.items.length) {
      invalidHistory();
    }
    for (final item in p.items) {
      final e = findEntry(item.topicId);
      if (item.status != query.status ||
          (scope == StudyScope.bb2026
              ? !item.topicId.startsWith('bb2026-')
              : item.topicId.startsWith('bb2026-'))) {
        invalidHistory();
      }
      if (item.contentStatus == ContentStatus.current &&
          (e == null ||
              !_belongs(e, scope) ||
              e.contentVersion != item.contentVersion ||
              !e.topic.questions.any((q) => q.id == item.questionId))) {
        invalidHistory();
      }
      if (query.subjectId != null &&
          e != null &&
          (scope == StudyScope.freeStudy ? e.topic.id : e.disciplineId) !=
              query.subjectId) {
        invalidHistory();
      }
    }
    return p;
  }
}
