import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';
import 'package:estuda_ai/features/learning/lesson_player.dart';

import 'app_test.dart' show openApp;

void main() {
  testWidgets('lesson_is_discipline_support_with_lazy_player_and_fallback', (
    tester,
  ) async {
    await openApp(tester, scale: 2, openLink: (_) async => false);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EstudaAiApp)),
    );
    c.read(routerProvider).go('/concursos/bb2026/ingles/bb2026-e01/aulas');
    await tester.pumpAndSettle();
    final lessons = c
        .read(contestCatalogProvider)
        .requireValue
        .findDiscipline('ingles')!
        .lessons;
    for (final l in lessons) {
      expect(find.text(l.title), findsOneWidget);
    }
    expect(find.byType(LessonPlayer), findsNothing);
    await tester.ensureVisible(find.text(lessons.first.title));
    await tester.tap(find.text(lessons.first.title));
    await tester.pumpAndSettle();
    expect(find.byType(LessonPlayer), findsOneWidget);
    await tester.ensureVisible(find.text('Abrir no YouTube'));
    await tester.tap(find.text('Abrir no YouTube'));
    await tester.pump();
    expect(
      find.text('Não foi possível abrir o vídeo. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Desafio 8 bits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'large text preserves the alternate video action and reports failure',
    (tester) async {
      await openApp(tester, scale: 2, openLink: (_) async => false);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      container.read(routerProvider).go('/aprender/ecologia');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ecossistemas e biomas'));
      await tester.tap(find.text('Ecossistemas e biomas'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Abrir no YouTube'));
      await tester.tap(find.text('Abrir no YouTube'));
      await tester.pump();
      expect(
        find.text('Não foi possível abrir o vídeo. Tente novamente.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'topic route shows its lessons and loads a player only on selection',
    (tester) async {
      await openApp(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(EstudaAiApp)),
      );
      for (final entry in {
        'porcentagem': 'Porcentagem e decimal',
        'interpretacao-texto': 'Compreensão x Interpretação no ENEM',
        'ecologia': 'Ecossistemas e biomas',
      }.entries) {
        container.read(routerProvider).go('/aprender/${entry.key}');
        await tester.pumpAndSettle();
        expect(find.text('Abrir no YouTube'), findsNothing);
        await tester.ensureVisible(find.text(entry.value));
        await tester.tap(find.text(entry.value));
        await tester.pumpAndSettle();
        expect(find.text('Abrir no YouTube'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      container.read(routerProvider).go('/aprender/inexistente');
      await tester.pumpAndSettle();
      expect(find.text('Assunto não encontrado'), findsOneWidget);
      await tester.tap(find.text('Voltar ao início'));
      await tester.pumpAndSettle();
      expect(find.text('Escolher meu assunto'), findsOneWidget);
    },
  );
}
