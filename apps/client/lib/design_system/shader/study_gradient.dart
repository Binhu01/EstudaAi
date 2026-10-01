import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'motion_policy.dart';
import 'shader_preset.dart';

class StudyGradient extends StatefulWidget {
  const StudyGradient({
    super.key,
    required this.animate,
    this.visible = true,
    this.program,
  });
  final bool animate, visible;
  final Future<ui.FragmentProgram>? program;
  @override
  State<StudyGradient> createState() => _StudyGradientState();
}

class _StudyGradientState extends State<StudyGradient>
    with WidgetsBindingObserver {
  static Future<ui.FragmentProgram>? _cachedProgram;
  ui.FragmentShader? _shader;
  Timer? _timer;
  double _time = 0;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    final program =
        widget.program ??
        (_cachedProgram ??= ui.FragmentProgram.fromAsset(
          'shaders/study_gradient.frag',
        ));
    program
        .then((value) {
          if (!mounted) return;
          setState(() => _shader = value.fragmentShader());
          _syncMotion();
        })
        .catchError((Object _) {
          /* The static surface remains usable on unsupported renderers. */
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(StudyGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    if (!mounted) return;
    final allowed =
        _shader != null &&
        ShaderMotionPolicy.allows(
          enabled: widget.animate,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          visible: widget.visible,
          foreground: _foreground,
          tickerEnabled: TickerMode.valuesOf(context).enabled,
        );
    if (!allowed) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(AppAnimations.shaderFrame, (_) {
      if (mounted) setState(() => _time += 0.1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shader?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: _shader == null
          ? const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.shaderViolet,
                    AppColors.shaderBlue,
                    AppColors.shaderYellow,
                  ],
                ),
              ),
            )
          : CustomPaint(painter: _GradientPainter(_shader!, _time)),
    ),
  );
}

class _GradientPainter extends CustomPainter {
  const _GradientPainter(this.shader, this.time);
  final ui.FragmentShader shader;
  final double time;
  @override
  void paint(Canvas canvas, Size size) {
    const preset = ShaderPreset.reference;
    final values = [
      size.width,
      size.height,
      time,
      preset.color1.r,
      preset.color1.g,
      preset.color1.b,
      preset.color2.r,
      preset.color2.g,
      preset.color2.b,
      preset.color3.r,
      preset.color3.g,
      preset.color3.b,
      preset.brightness,
      preset.density,
      preset.frequency,
      preset.amplitude,
      preset.speed,
      preset.strength,
      preset.rotation,
    ];
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i, values[i]);
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_GradientPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.shader != shader;
}
