import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learning/learning_catalog_providers.dart';
import 'quiz_engine.dart';
import 'best_score_repository.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../study_history/study_history_api.dart';
import '../study_history/study_history_models.dart';
import '../study_history/study_context_controller.dart';
import '../study_history/answer_submission.dart';

class QuizViewState {
  const QuizViewState({
    required this.round,
    required this.best,
    this.started = false,
    this.saving = false,
    this.saveFailed = false,
    this.history = const AnswerSubmissionState(),
  });
  final QuizState round;
  final int best;
  final bool started, saving, saveFailed;
  final AnswerSubmissionState history;
  bool get canAdvance =>
      history.status == SubmissionStatus.idle ||
      history.status == SubmissionStatus.confirmed;
}

final quizProvider = NotifierProvider.autoDispose
    .family<QuizController, QuizViewState, String>(QuizController.new);

class QuizController extends Notifier<QuizViewState> {
  QuizController(this.topicId);
  final String topicId;
  late QuizEngine _engine;
  late int _version;
  int _generation = 0;
  late AnswerSubmissionController _submission;
  bool _disposing = false;
  @override
  QuizViewState build() {
    final entry = ref.read(learningEntryProvider(topicId)).requireValue;
    if (entry == null) {
      throw ArgumentError.value(topicId);
    }
    _version = entry.contentVersion;
    _engine = QuizEngine(questions: entry.topic.questions, random: Random())
      ..start();
    final historyContext = ref.read(studyContextProvider.notifier);
    _submission = AnswerSubmissionController(
      api: () => ref.read(studyHistoryApiProvider),
      capture: () => ref.read(learningProvider).topicId == topicId
          ? historyContext.capture()
          : Future.value(null),
      stillCurrent: historyContext.isCurrent,
      onConfirmed: historyContext.noteConfirmed,
      onChanged: (history) {
        if (ref.mounted && !_disposing) {
          state = QuizViewState(
            round: state.round,
            best: state.best,
            started: state.started,
            saving: state.saving,
            saveFailed: state.saveFailed,
            history: history,
          );
        }
      },
    );
    ref.listen(sessionProvider, (previous, next) {
      if (previous?.generation != next.generation ||
          previous?.profile?.id != next.profile?.id) {
        _submission.cancel();
      }
    });
    ref.listen(learningProvider, (previous, next) {
      if (previous?.generation != next.generation) _submission.cancel();
    });
    ref.onDispose(() {
      _disposing = true;
      _generation++;
      _submission.cancel();
    });
    return QuizViewState(
      round: _engine.state,
      best: ref.read(bestScoreProvider).read(topicId, _version),
    );
  }

  void start() {
    _generation++;
    _submission.cancel();
    _engine.start();
    state = QuizViewState(
      round: _engine.state,
      best: ref.read(bestScoreProvider).read(topicId, _version),
      started: true,
    );
  }

  void answer(int index) {
    if (state.started && _engine.answer(index)) {
      state = QuizViewState(
        round: _engine.state,
        best: state.best,
        started: true,
      );
      if (ref.read(sessionProvider).isAuthenticated) {
        unawaited(
          _submission.submit(
            StudyAnswerInput(
              topicId: topicId,
              contentVersion: _version,
              questionId: state.round.question.id,
              optionIndex: _engine.canonicalOptionIndex(index),
              source: AnswerSource.quiz,
            ),
          ),
        );
      }
    }
  }

  void next() {
    if (_engine.state.phase != QuizPhase.feedback || !state.canAdvance) {
      return;
    }
    _submission.cancel();
    _engine.next();
    state = QuizViewState(
      round: _engine.state,
      best: state.best,
      started: true,
    );
    if (state.round.phase == QuizPhase.completed) {
      unawaited(_save(_generation, state.round.score));
    }
  }

  Future<void> retryHistory() => _submission.retry();
  void continueStudy() {
    if (state.history.status == SubmissionStatus.unconfirmed) {
      _submission.continueStudy();
    }
  }

  Future<void> _save(int generation, int score) async {
    state = QuizViewState(
      round: state.round,
      best: state.best,
      started: true,
      saving: true,
    );
    try {
      await ref.read(bestScoreProvider).saveIfHigher(topicId, _version, score);
      if (ref.mounted && generation == _generation) {
        state = QuizViewState(
          round: state.round,
          best: ref.read(bestScoreProvider).read(topicId, _version),
          started: true,
        );
      }
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        state = QuizViewState(
          round: state.round,
          best: state.best,
          started: true,
          saveFailed: true,
        );
      }
    }
  }
}
