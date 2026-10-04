import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/home/education_hero.dart';
import 'package:estuda_ai/features/home/hero_particle_orb.dart';

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

  testWidgets(
    'hero action remains usable at 200% with the requested brain motion',
    (tester) async {
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
                  animate: true,
                  visible: true,
                  onChooseTopic: () => chosen = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.text('Escolher meu assunto'));
      await tester.tap(find.text('Escolher meu assunto'));
      expect(chosen, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('hero keeps a static particle graphic without external media', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EducationHero(
              animate: false,
              visible: true,
              onChooseTopic: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HeroParticleOrb), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const ValueKey('hero-video-surface')), findsNothing);
    final graphic = find.descendant(
      of: find.byType(HeroParticleOrb),
      matching: find.byType(CustomPaint),
    );
    final before =
        (tester.widget<CustomPaint>(graphic).painter as HeroParticleOrbPainter)
            .time;
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      (tester.widget<CustomPaint>(graphic).painter as HeroParticleOrbPainter)
          .time,
      before,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'orb rotation pauses for lifecycle, visibility and motion preferences',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      Future<void> showOrb({
        bool animate = true,
        bool visible = true,
        bool reduceMotion = false,
        bool tickerEnabled = true,
        bool respectReducedMotion = true,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: TickerMode(
                enabled: tickerEnabled,
                child: SizedBox.square(
                  dimension: 320,
                  child: HeroParticleOrb(
                    animate: animate,
                    visible: visible,
                    respectReducedMotion: respectReducedMotion,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      double orbTime() =>
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(HeroParticleOrb),
                          matching: find.byType(CustomPaint),
                        ),
                      )
                      .painter
                  as HeroParticleOrbPainter)
              .time;
      await showOrb();
      final first = orbTime();
      await tester.pump(const Duration(milliseconds: 300));
      expect(orbTime(), greaterThan(first));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      final inactive = orbTime();
      await tester.pump(const Duration(milliseconds: 300));
      expect(orbTime(), inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 200));
      expect(orbTime(), greaterThan(inactive));
      for (final condition in [
        (
          animate: false,
          visible: true,
          reduceMotion: false,
          tickerEnabled: true,
        ),
        (
          animate: true,
          visible: false,
          reduceMotion: false,
          tickerEnabled: true,
        ),
        (animate: true, visible: true, reduceMotion: true, tickerEnabled: true),
        (
          animate: true,
          visible: true,
          reduceMotion: false,
          tickerEnabled: false,
        ),
      ]) {
        await showOrb(
          animate: condition.animate,
          visible: condition.visible,
          reduceMotion: condition.reduceMotion,
          tickerEnabled: condition.tickerEnabled,
        );
        final stopped = orbTime();
        await tester.pump(const Duration(milliseconds: 300));
        expect(orbTime(), stopped);
      }
      await showOrb(reduceMotion: true, respectReducedMotion: false);
      final requested = orbTime();
      await tester.pump(const Duration(milliseconds: 300));
      expect(orbTime(), greaterThan(requested));
      await showOrb(
        animate: false,
        reduceMotion: true,
        respectReducedMotion: false,
      );
      final manuallyPaused = orbTime();
      await tester.pump(const Duration(milliseconds: 300));
      expect(orbTime(), manuallyPaused);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
