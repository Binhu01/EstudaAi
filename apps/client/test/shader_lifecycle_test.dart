import 'dart:async';
import 'dart:ui' as ui;

import 'package:estuda_ai/app/app.dart';
import 'package:estuda_ai/design_system/shader/study_gradient.dart';
import 'package:estuda_ai/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:estuda_ai/features/learning/study_catalog.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';

Finder get _gradient => find.byType(StudyGradient, skipOffstage: false);

// Inspect the actual painter's public time value rather than duplicating the
// motion policy. Off-screen render objects remain available for this check.
double _shaderTime(WidgetTester tester) {
  final paint = find.descendant(
    of: _gradient,
    matching: find.byType(CustomPaint, skipOffstage: false),
    skipOffstage: false,
  );
  expect(paint, findsOneWidget, reason: 'The compiled shader must be loaded.');
  final dynamic painter = tester.widget<CustomPaint>(paint).painter;
  return painter.time as double;
}

void main() {
  testWidgets('real shader pauses for lifecycle, reduced motion and scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    // Load the compiled asset in the real async zone. Missing or invalid shader
    // assets must fail this test instead of quietly exercising only fallback.
    await tester.runAsync(() async {
      await ui.FragmentProgram.fromAsset('shaders/study_gradient.frag');
    });
    SharedPreferences.setMockInitialValues({'animate': true});
    final preferences = await SharedPreferences.getInstance();
    final catalog = await tester.runAsync(() => loadCatalog(rootBundle));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          catalogProvider.overrideWith((ref) async => catalog!),
        ],
        child: const EstudaAiApp(),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(_gradient);
    await tester.pump();
    final initial = _shaderTime(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_shaderTime(tester), greaterThan(initial));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final inactive = _shaderTime(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_shaderTime(tester), inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_shaderTime(tester), greaterThan(inactive));

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();
    final reduced = _shaderTime(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_shaderTime(tester), reduced);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_shaderTime(tester), greaterThan(reduced));

    final scroll = find.byType(SingleChildScrollView).first;
    await tester.drag(scroll, const Offset(0, -1000));
    await tester.pump();
    expect(tester.widget<StudyGradient>(_gradient).visible, false);
    final offscreen = _shaderTime(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_shaderTime(tester), offscreen);
    await tester.ensureVisible(_gradient);
    await tester.pump();
    expect(tester.widget<StudyGradient>(_gradient).visible, true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_shaderTime(tester), greaterThan(offscreen));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shader compilation failure keeps the static surface usable', (
    tester,
  ) async {
    final program = Completer<ui.FragmentProgram>();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 200,
          child: StudyGradient(animate: true, program: program.future),
        ),
      ),
    );
    program.completeError(StateError('Shader compilation failed.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.descendant(of: _gradient, matching: find.byType(DecoratedBox)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _gradient, matching: find.byType(CustomPaint)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
