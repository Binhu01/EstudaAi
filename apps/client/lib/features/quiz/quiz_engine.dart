import 'dart:math';

import '../learning/study_catalog.dart';

enum QuizPhase { answering, feedback, completed }

class QuizState {
  const QuizState({
    required this.phase,
    required this.roundQuestions,
    this.questionIndex = 0,
    this.selectedIndex,
    this.score = 0,
    this.streak = 0,
    this.correctCount = 0,
  });
  final QuizPhase phase;
  final List<StudyQuestion> roundQuestions;
  final int questionIndex, score, streak, correctCount;
  final int? selectedIndex;
  StudyQuestion get question => roundQuestions[questionIndex];
}

class QuizEngine {
  QuizEngine({required List<StudyQuestion> questions, required this.random})
    : _questions = List.unmodifiable(questions) {
    if (questions.length < 5 ||
        questions.map((q) => q.id).toSet().length != questions.length) {
      throw ArgumentError('São necessárias cinco perguntas únicas.');
    }
  }
  final List<StudyQuestion> _questions;
  final Random random;
  late QuizState _state;
  QuizState get state => _state;
  void start() {
    final pool = _questions.toList()..shuffle(random);
    _state = QuizState(
      phase: QuizPhase.answering,
      roundQuestions: List.unmodifiable(
        pool.take(5).map((question) {
          final order = [0, 1, 2, 3]..shuffle(random);
          return StudyQuestion(
            question.id,
            question.prompt,
            List.unmodifiable(order.map((index) => question.options[index])),
            order.indexOf(question.correctIndex),
            question.explanation,
          );
        }),
      ),
    );
  }

  bool answer(int optionIndex) {
    RangeError.checkValidIndex(optionIndex, _state.question.options);
    if (_state.phase != QuizPhase.answering) {
      return false;
    }
    final correct = optionIndex == _state.question.correctIndex;
    _state = QuizState(
      phase: QuizPhase.feedback,
      roundQuestions: _state.roundQuestions,
      questionIndex: _state.questionIndex,
      selectedIndex: optionIndex,
      score: _state.score + (correct ? 100 + min(80, 20 * _state.streak) : 0),
      streak: correct ? _state.streak + 1 : 0,
      correctCount: _state.correctCount + (correct ? 1 : 0),
    );
    return true;
  }

  void next() {
    if (_state.phase != QuizPhase.feedback) {
      return;
    }
    final done = _state.questionIndex == 4;
    _state = QuizState(
      phase: done ? QuizPhase.completed : QuizPhase.answering,
      roundQuestions: _state.roundQuestions,
      questionIndex: done ? 4 : _state.questionIndex + 1,
      score: _state.score,
      streak: _state.streak,
      correctCount: _state.correctCount,
    );
  }
}
