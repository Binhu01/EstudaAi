import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/home/education_hero.dart';

import 'app_test.dart' show openApp;

void main() {
  testWidgets('hero action reveals the subject selection', (tester) async {
    await openApp(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.ensureVisible(find.text('Escolher meu assunto'));
    await tester.tap(find.text('Escolher meu assunto'));
    await tester.pumpAndSettle();
    expect(find.text('Estudo livre'), findsOneWidget);
    expect(find.text('Porcentagem'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing photo and reduced motion keep the action at 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var chosen = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: EducationHero(
                imagePath: 'assets/missing.webp',
                animate: true,
                visible: true,
                onChooseTopic: () => chosen = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Escolher meu assunto'));
    await tester.tap(find.text('Escolher meu assunto'));
    expect(chosen, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });
}
