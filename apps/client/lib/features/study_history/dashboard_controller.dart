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

class DashboardViewState {
  const DashboardViewState({
    this.data,
    this.pending = false,
    this.saving = false,
    this.error,
  });
  final StudyDashboard? data;
  final bool pending, saving;
  final ApiFailure? error;
}

final dashboardProvider =
    NotifierProvider.autoDispose<DashboardController, DashboardViewState>(
      DashboardController.new,
    );

class DashboardController extends Notifier<DashboardViewState> {
  int _generation = 0;
  CancelToken? _cancel;
  HistorySnapshot? _snapshot;
  @override
  DashboardViewState build() {
    ref.listen(sessionProvider, (previous, next) {
      if (previous?.generation != next.generation ||
          previous?.profile?.id != next.profile?.id) {
        _reset();
      }
    });
    ref.listen(learningProvider, (previous, next) {
      if (previous?.generation != next.generation) _reset();
    });
    ref.listen(studyContextProvider, (previous, next) {
      if (next.snapshot != null &&
          previous?.revision != next.revision &&
          previous?.snapshot?.goal.dailyTarget ==
              next.snapshot!.goal.dailyTarget) {
        unawaited(load());
      }
    });
    ref.onDispose(() {
      _generation++;
      _cancel?.cancel();
    });
    Future.microtask(() {
      if (ref.mounted) unawaited(load());
    });
    return const DashboardViewState();
  }

  void _reset() {
    _generation++;
    _cancel?.cancel();
    _snapshot = null;
    state = const DashboardViewState();
    unawaited(load());
  }

  Future<void> retry() => load();
  Future<void> load() async {
    final generation = ++_generation;
    _cancel?.cancel();
    final cancel = CancelToken();
    _cancel = cancel;
    if (!ref.read(sessionProvider).isAuthenticated) {
      state = const DashboardViewState();
      return;
    }
    state = DashboardViewState(data: state.data, pending: true);
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
      _snapshot = snapshot;
      bool current() =>
          ref.mounted &&
          generation == _generation &&
          controller.isCurrent(snapshot);
      final data = await controller.gate.run(
        snapshot.context,
        () => ref
            .read(studyHistoryApiProvider)
            .readDashboard(
              snapshot.context,
              snapshot.goal.scope,
              cancelToken: cancel,
              stillCurrent: current,
            ),
        cancel: () => cancel.cancel(),
      );
      if (current() && data != null) state = DashboardViewState(data: data);
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = DashboardViewState(
          data: state.data,
          error: error is ApiFailure ? error : const ApiFailure('UNAVAILABLE'),
        );
      }
    }
  }

  Future<void> setDailyTarget(int target) async {
    final snapshot = _snapshot, previous = state.data;
    if (snapshot == null || previous == null || state.saving || state.pending) {
      return;
    }
    final generation = _generation, cancel = CancelToken();
    _cancel = cancel;
    final controller = ref.read(studyContextProvider.notifier);
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        controller.isCurrent(snapshot);
    state = DashboardViewState(data: previous, saving: true);
    try {
      final goal = await ref
          .read(studyHistoryApiProvider)
          .setDailyTarget(
            snapshot.context,
            snapshot.goal.scope,
            target,
            cancelToken: cancel,
            stillCurrent: current,
          );
      if (!current()) return;
      state = DashboardViewState(
        data: StudyDashboard(
          goal: goal,
          today: previous.today,
          pendingErrors: previous.pendingErrors,
          activity: previous.activity,
          subjects: previous.subjects,
          resume: previous.resume,
          progress: previous.progress,
        ),
      );
      controller.updateGoal(snapshot, goal);
    } catch (error) {
      if (current()) {
        state = DashboardViewState(
          data: previous,
          error: error is ApiFailure ? error : const ApiFailure('UNAVAILABLE'),
        );
      }
    }
  }
}
