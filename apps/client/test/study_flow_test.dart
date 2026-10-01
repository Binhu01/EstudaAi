import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/quiz/quiz_controller.dart';

import 'app_test.dart' show openApp;

void main() {
  testWidgets(
    'study topic survives lessons, five-question quiz, result, Steve and account',
    (tester) async {
      await openApp(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      final catalog = c.read(catalogProvider).requireValue;
      for (final topic in catalog.topics) {
        c.read(learningProvider.notifier).selectTopic(topic.id);
        final lessons = find.text('Aprender com videoaulas');
        await tester.ensureVisible(lessons);
        await tester.tap(lessons);
        await tester.pumpAndSettle();
        expect(find.text(topic.lessons.first.title), findsOneWidget);
        await tester.tap(find.text(topic.lessons.first.title));
        await tester.pumpAndSettle();
        expect(find.text('Abrir no YouTube'), findsOneWidget);
        await tester.tap(find.text('Desafios').first);
        await tester.pumpAndSettle();
        expect(
          c.read(routerProvider).routeInformationProvider.value.uri.path,
          '/desafios/${topic.id}',
        );
        await tester.ensureVisible(find.text('Começar desafio'));
        await tester.tap(find.text('Começar desafio'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 5; i++) {
          final q = c.read(quizProvider(topic.id)).round.question;
          final answer = find.text(q.options[q.correctIndex]);
          await tester.ensureVisible(answer);
          await tester.tap(answer);
          await tester.pumpAndSettle();
          expect(find.text(q.explanation), findsOneWidget);
          final next = find.text(i == 4 ? 'Ver resultado' : 'Próxima pergunta');
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(find.text('5 de 5 acertos'), findsOneWidget);
        await tester.ensureVisible(find.text('Assistir aula'));
        await tester.tap(find.text('Assistir aula'));
        await tester.pumpAndSettle();
        expect(
          c.read(routerProvider).routeInformationProvider.value.uri.path,
          '/aprender/${topic.id}',
        );
        await tester.ensureVisible(find.text('Perguntar ao Steve'));
        await tester.tap(find.text('Perguntar ao Steve'));
        await tester.pumpAndSettle();
        expect(
          c.read(routerProvider).routeInformationProvider.value.uri.path,
          '/steve/${topic.id}',
        );
        await tester.ensureVisible(find.text('Entrar para conversar'));
        await tester.tap(find.text('Entrar para conversar'));
        await tester.pumpAndSettle();
        expect(find.text('Sua conta'), findsOneWidget);
        expect(c.read(learningProvider).topicId, topic.id);
        c.read(routerProvider).go('/');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
