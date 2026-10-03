import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_failure.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_catalog_providers.dart';
import '../learning/learning_entry.dart';
import 'study_context_controller.dart';
import 'study_history_api.dart';
import 'study_history_models.dart';

class ErrorsViewState {
  const ErrorsViewState({
    this.items = const [],
    this.query = const ErrorQuery(),
    this.nextCursor,
    this.pending = false,
    this.error,
  });
  final List<StudyErrorItem> items;
  final ErrorQuery query;
  final String? nextCursor;
  final bool pending;
  final ApiFailure? error;
}

final errorsProvider =
    NotifierProvider.autoDispose<ErrorsController, ErrorsViewState>(
      ErrorsController.new,
    );

class ErrorsController extends Notifier<ErrorsViewState> {
  int _generation = 0;
  CancelToken? _cancel;
  @override
  ErrorsViewState build() {
    ref.listen(sessionProvider, (a, b) {
      if (a?.generation != b.generation || a?.profile?.id != b.profile?.id) {
        _reset();
      }
    });
    ref.listen(learningProvider, (a, b) {
      if (a?.generation != b.generation) _reset();
    });
    ref.listen(studyContextProvider, (a, b) {
      if (b.snapshot != null && a?.revision != b.revision) {
        unawaited(load(state.query));
      }
    });
    ref.onDispose(() {
      _generation++;
      _cancel?.cancel();
    });
    Future.microtask(() {
      if (ref.mounted) unawaited(load(const ErrorQuery()));
    });
    return const ErrorsViewState();
  }

  void _reset() {
    _generation++;
    _cancel?.cancel();
    state = const ErrorsViewState();
    unawaited(load(const ErrorQuery()));
  }

  Future<void> load(ErrorQuery query) => _fetch(
    ErrorQuery(
      status: query.status,
      subjectId: query.subjectId,
      limit: query.limit,
    ),
    false,
  );
  Future<void> retry() => load(state.query);
  Future<void> nextPage() async {
    if (state.pending || state.nextCursor == null) return;
    await _fetch(state.query.next(state.nextCursor!), true);
  }

  Future<void> _fetch(ErrorQuery query, bool append) async {
    final generation = ++_generation;
    _cancel?.cancel();
    final cancel = CancelToken();
    _cancel = cancel;
    final previous = append ? state.items : const <StudyErrorItem>[];
    final baseQuery = ErrorQuery(
      status: query.status,
      subjectId: query.subjectId,
      limit: query.limit,
    );
    final oldCursor = append ? state.nextCursor : null;
    if (!ref.read(sessionProvider).isAuthenticated) {
      state = const ErrorsViewState();
      return;
    }
    state = ErrorsViewState(
      items: previous,
      query: baseQuery,
      pending: true,
      nextCursor: oldCursor,
    );
    try {
      if (ref.read(learningProvider).area == LearningArea.freeStudy) {
        await ref.read(catalogProvider.future);
      } else {
        await ref.read(contestCatalogProvider.future);
      }
      if (!ref.mounted || generation != _generation) return;
      final controller = ref.read(studyContextProvider.notifier),
          snapshot = await controller.capture();
      if (!ref.mounted || generation != _generation) return;
      if (snapshot == null) {
        throw ref.read(studyContextProvider).error ??
            const ApiFailure('UNAUTHENTICATED');
      }
      bool current() =>
          ref.mounted &&
          generation == _generation &&
          controller.isCurrent(snapshot);
      final page = await controller.gate.run(
        snapshot.context,
        () => ref
            .read(studyHistoryApiProvider)
            .listErrors(
              snapshot.context,
              snapshot.goal.scope,
              query,
              cancelToken: cancel,
              stillCurrent: current,
            ),
        cancel: () => cancel.cancel(),
      );
      if (!current() || page == null) return;
      final unique = {
        for (final item in previous) item.key: item,
        for (final item in page.items) item.key: item,
      };
      state = ErrorsViewState(
        items: List.unmodifiable(unique.values),
        query: baseQuery,
        nextCursor: page.nextCursor,
      );
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = ErrorsViewState(
          items: previous,
          query: baseQuery,
          nextCursor: oldCursor,
          error: error is ApiFailure ? error : const ApiFailure('UNAVAILABLE'),
        );
      }
    }
  }
}
