import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/learning/study_catalog.dart';
import 'package:estuda_ai/features/quiz/quiz_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'displayed options map to their canonical positions across every question',
    () async {
      final topic = (await loadCatalog(rootBundle)).find('porcentagem')!;
      final engine = QuizEngine(questions: topic.questions, random: Random(42))
        ..start();
      for (var round = 0; round < 5; round++) {
        final q = engine.state.question,
            original = topic.questions.firstWhere((v) => v.id == q.id);
        for (var displayed = 0; displayed < 4; displayed++) {
          expect(
            original.options[engine.canonicalOptionIndex(displayed)],
            q.options[displayed],
          );
        }
        expect(() => engine.canonicalOptionIndex(4), throwsRangeError);
        engine.answer(0);
        engine.next();
      }
    },
  );
  test(
    'a full perfect round has five unique questions and 700 points',
    () async {
      final topic = (await loadCatalog(rootBundle)).find('porcentagem')!;
      final engine = QuizEngine(questions: topic.questions, random: Random(42))
        ..start();
      expect(engine.state.roundQuestions.map((q) => q.id).toSet().length, 5);
      for (final q in engine.state.roundQuestions) {
        final original = topic.questions.firstWhere((item) => item.id == q.id);
        expect(
          q.options[q.correctIndex],
          original.options[original.correctIndex],
        );
        expect(q.options.toSet(), original.options.toSet());
      }
      expect(
        engine.state.roundQuestions.any(
          (q) =>
              q.options.join('|') !=
              topic.questions
                  .firstWhere((original) => original.id == q.id)
                  .options
                  .join('|'),
        ),
        isTrue,
      );
      engine.next();
      expect(engine.state.questionIndex, 0);
      for (var i = 0; i < 5; i++) {
        final q = engine.state.roundQuestions[i];
        expect(engine.answer(q.correctIndex), isTrue);
        final score = engine.state.score;
        expect(engine.answer(q.correctIndex), isFalse);
        expect(engine.state.score, score);
        engine.next();
      }
      expect(engine.state.phase, QuizPhase.completed);
      expect(engine.state.score, 700);
      expect(engine.state.correctCount, 5);
      engine.start();
      expect(engine.state.score, 0);
      expect(engine.state.selectedIndex, isNull);
    },
  );
  test(
    'a wrong answer resets the streak and invalid choices are rejected',
    () async {
      final topic = (await loadCatalog(rootBundle)).find('ecologia')!;
      final engine = QuizEngine(questions: topic.questions, random: Random(1))
        ..start();
      expect(() => engine.answer(4), throwsRangeError);
      engine.answer(engine.state.roundQuestions[0].correctIndex);
      engine.next();
      engine.answer((engine.state.roundQuestions[1].correctIndex + 1) % 4);
      expect(engine.state.streak, 0);
      engine.next();
      engine.answer(engine.state.roundQuestions[2].correctIndex);
      expect(engine.state.score, 200);
      expect(engine.state.correctCount, 2);
    },
  );
}
