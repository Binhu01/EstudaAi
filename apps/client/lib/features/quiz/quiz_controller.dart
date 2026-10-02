import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learning/learning_catalog_providers.dart';
import 'quiz_engine.dart';
import 'best_score_repository.dart';

class QuizViewState {
  const QuizViewState({
    required this.round,
    required this.best,
    this.started = false,
    this.saving = false,
    this.saveFailed = false,
  });
  final QuizState round;
  final int best;
  final bool started, saving, saveFailed;
}

final quizProvider = NotifierProvider.autoDispose
    .family<QuizController, QuizViewState, String>(QuizController.new);

class QuizController extends Notifier<QuizViewState> {
  QuizController(this.topicId);
  final String topicId;
  late QuizEngine _engine;
  late int _version;
  int _generation = 0;
  @override
  QuizViewState build() {
    final entry = ref.read(learningEntryProvider(topicId)).requireValue;
    if (entry == null) {
      throw ArgumentError.value(topicId);
    }
    _version = entry.contentVersion;
    _engine = QuizEngine(questions: entry.topic.questions, random: Random())
      ..start();
    return QuizViewState(
      round: _engine.state,
      best: ref.read(bestScoreProvider).read(topicId, _version),
    );
  }

  void start() {
    _generation++;
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
    }
  }

  void next() {
    if (_engine.state.phase != QuizPhase.feedback) {
      return;
    }
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
