import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_failure.dart';
import '../../core/study_context.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_entry.dart';
import 'study_history_api.dart';
import 'study_history_models.dart';

typedef HistoryIdentity = ({
  String userId,
  StudyScope scope,
  int sessionGeneration,
  int learningGeneration,
});

class HistorySnapshot {
  const HistorySnapshot(
    this.context,
    this.goal,
    this.identity,
    this.generation,
  );
  final StudyContext context;
  final StudyGoalContext goal;
  final HistoryIdentity identity;
  final int generation;
}

class StudyContextState {
  const StudyContextState({
    this.snapshot,
    this.pending = false,
    this.error,
    this.revision = 0,
  });
  final HistorySnapshot? snapshot;
  final bool pending;
  final ApiFailure? error;
  final int revision;
}

final studyContextProvider =
    NotifierProvider<StudyContextController, StudyContextState>(
      StudyContextController.new,
    );

class StudyContextController extends Notifier<StudyContextState> {
  final gate = ContextGate();
  int _generation = 0;
  HistoryIdentity? _activeIdentity;
  CancelToken? _cancel;
  Future<StudyGoalContext?>? _pending;
  @override
  StudyContextState build() {
    _activeIdentity = _identity();
    ref.listen(sessionProvider, (_, next) => _sync());
    ref.listen(learningProvider, (_, next) => _sync());
    ref.onDispose(() {
      _generation++;
      _cancel?.cancel();
      gate.activate(null);
    });
    return const StudyContextState();
  }

  HistoryIdentity? _identity() {
    final s = ref.read(sessionProvider), l = ref.read(learningProvider);
    return !s.isAuthenticated
        ? null
        : (
            userId: s.profile!.id,
            scope: l.area == LearningArea.freeStudy
                ? StudyScope.freeStudy
                : StudyScope.bb2026,
            sessionGeneration: s.generation,
            learningGeneration: l.generation,
          );
  }

  void _sync() {
    final next = _identity();
    if (next == _activeIdentity) return;
    _activeIdentity = next;
    _generation++;
    _cancel?.cancel();
    _cancel = null;
    _pending = null;
    gate.activate(null);
    state = const StudyContextState();
  }

  bool isCurrent(HistorySnapshot snapshot) =>
      ref.mounted &&
      snapshot.identity == _identity() &&
      snapshot.generation == _generation &&
      state.snapshot?.context == snapshot.context;
  Future<HistorySnapshot?> capture() async {
    _sync();
    final identity = _activeIdentity, generation = _generation;
    final goal = await ensureActive();
    return ref.mounted &&
            goal != null &&
            identity == _identity() &&
            generation == _generation
        ? state.snapshot
        : null;
  }

  Future<StudyGoalContext?> ensureActive() {
    _sync();
    if (_activeIdentity == null) return Future.value(null);
    if (state.snapshot != null) return Future.value(state.snapshot!.goal);
    if (_pending != null) return _pending!;
    final identity = _activeIdentity!,
        generation = _generation,
        cancel = CancelToken();
    _cancel = cancel;
    state = const StudyContextState(pending: true);
    late Future<StudyGoalContext?> operation;
    operation = _ensure(identity, generation, cancel).whenComplete(() {
      if (identical(_pending, operation)) _pending = null;
    });
    _pending = operation;
    return operation;
  }

  Future<StudyGoalContext?> _ensure(
    HistoryIdentity identity,
    int generation,
    CancelToken cancel,
  ) async {
    bool current() =>
        ref.mounted && _identity() == identity && generation == _generation;
    try {
      final goal = await ref
          .read(studyHistoryApiProvider)
          .ensureContext(
            identity.scope,
            cancelToken: cancel,
            stillCurrent: current,
          );
      if (!current()) return null;
      final context = StudyContext(identity.userId, goal.id);
      gate.activate(context);
      state = StudyContextState(
        snapshot: HistorySnapshot(context, goal, identity, generation),
      );
      return goal;
    } catch (error) {
      if (current()) {
        state = StudyContextState(
          error: error is ApiFailure ? error : const ApiFailure('UNAVAILABLE'),
        );
      }
      return null;
    }
  }

  void noteConfirmed(HistorySnapshot snapshot) {
    if (isCurrent(snapshot)) {
      state = StudyContextState(
        snapshot: state.snapshot,
        revision: state.revision + 1,
      );
    }
  }

  void updateGoal(HistorySnapshot snapshot, StudyGoalContext goal) {
    if (isCurrent(snapshot)) {
      state = StudyContextState(
        snapshot: HistorySnapshot(
          snapshot.context,
          goal,
          snapshot.identity,
          snapshot.generation,
        ),
        revision: state.revision + 1,
      );
    }
  }
}
