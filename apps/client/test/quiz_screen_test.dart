import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/quiz/quiz_controller.dart';
import 'package:estuda_ai/features/quiz/quiz_engine.dart';

import 'app_test.dart' show openApp;

void main() {
  testWidgets('each topic plays a complete round and repeat resets the score', (
    tester,
  ) async {
    await openApp(tester);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    for (final topic in ['porcentagem', 'interpretacao-texto', 'ecologia']) {
      c.read(routerProvider).go('/desafios/$topic');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Começar desafio'));
      await tester.tap(find.text('Começar desafio'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        final q = c.read(quizProvider(topic)).round.question;
        final choice = find.text(q.options[q.correctIndex]);
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(find.text('Resposta correta!'), findsOneWidget);
        expect(find.text(q.explanation), findsOneWidget);
        for (var index = 0; index < 4; index++) {
          expect(
            tester
                .widget<FilledButton>(find.byKey(ValueKey('answer-$index')))
                .onPressed,
            isNull,
          );
        }
        final next = find.text(i == 4 ? 'Ver resultado' : 'Próxima pergunta');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      expect(find.text('5 de 5 acertos'), findsOneWidget);
      expect(find.text('700 / 700 pontos'), findsOneWidget);
      expect(find.text('Melhor neste dispositivo: 700'), findsOneWidget);
      await tester.ensureVisible(find.text('Repetir desafio'));
      await tester.tap(find.text('Repetir desafio'));
      await tester.pumpAndSettle();
      expect(c.read(quizProvider(topic)).round.score, 0);
      expect(c.read(quizProvider(topic)).round.phase, QuizPhase.answering);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'keyboard selects once at 200% and switching topics abandons the round',
    (tester) async {
      await openApp(tester, scale: 2);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      c.read(routerProvider).go('/desafios/porcentagem');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Começar desafio'));
      await tester.tap(find.text('Começar desafio'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('answer-0'));
      await tester.ensureVisible(button);
      tester.widget<FilledButton>(button).focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        c.read(quizProvider('porcentagem')).round.phase,
        QuizPhase.feedback,
      );
      final score = c.read(quizProvider('porcentagem')).round.score;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(c.read(quizProvider('porcentagem')).round.score, score);
      expect(tester.takeException(), isNull);
      c.read(routerProvider).go('/desafios/ecologia');
      await tester.pumpAndSettle();
      expect(find.text('Começar desafio'), findsOneWidget);
      expect(c.read(quizProvider('ecologia')).round.score, 0);
      expect(c.read(quizProvider('ecologia')).started, isFalse);
    },
  );
}
