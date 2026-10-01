import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/app/app.dart';

import 'app_test.dart' show openApp;

void main() {
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
