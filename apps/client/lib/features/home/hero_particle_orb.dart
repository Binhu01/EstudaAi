import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/shader/motion_policy.dart';
import '../../design_system/tokens.dart';

class HeroParticleOrb extends StatefulWidget {
  const HeroParticleOrb({
    super.key,
    required this.animate,
    required this.visible,
    this.respectReducedMotion = true,
  });
  final bool animate, visible, respectReducedMotion;
  @override
  State<HeroParticleOrb> createState() => _HeroParticleOrbState();
}

class _HeroParticleOrbState extends State<HeroParticleOrb>
    with WidgetsBindingObserver {
  static const _frame = Duration(milliseconds: 100);
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(HeroParticleOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    final allowed = ShaderMotionPolicy.allows(
      enabled: widget.animate,
      reduceMotion:
          widget.respectReducedMotion &&
          MediaQuery.disableAnimationsOf(context),
      visible: widget.visible,
      foreground: _foreground,
      tickerEnabled: TickerMode.valuesOf(context).enabled,
    );
    if (!allowed) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(_frame, (_) {
      if (mounted) setState(() => _time += .1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(painter: HeroParticleOrbPainter(time: _time)),
    ),
  );
}

/// The cortex, folds and neural routes are cached. A bounded view keeps both
/// hemispheres recognizable while the breathing and signals share an 8s loop.
class HeroParticleOrbPainter extends CustomPainter {
  const HeroParticleOrbPainter({required this.time});
  final double time;
  static final _geometry = _BrainGeometry.create();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final phase = 2 * math.pi * (time % 8) / 8;
    final unit = math.min(size.width, size.height) / 300;
    final projection = _BrainProjection(
      center: Offset(size.width * .5, size.height * .49),
      scale:
          math.min(size.width, size.height) *
          .43 *
          (1 + .012 * math.sin(phase * 2)),
      yaw: .13 + .075 * math.sin(phase),
      pitch: .25 + .025 * math.sin(phase * 2 + .7),
    );
    final particles = [
      for (final point in _geometry.points) projection.project(point),
    ];
    final dot = Paint()..isAntiAlias = true;
    final glow = Paint()..isAntiAlias = true;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Back cortex first, then the nearer surface; the central gap stays dark.
    for (final front in [false, true]) {
      for (var i = 0; i < particles.length; i++) {
        final projected = particles[i], point = _geometry.points[i];
        if ((projected.depth >= 0) != front) continue;
        final light = ((projected.depth + .75) / 1.5).clamp(0.0, 1.0);
        final color = point.index % 19 == 0
            ? AurosColors.lavender
            : point.index % 7 == 0
            ? AurosColors.mist
            : point.index % 3 == 0
            ? AurosColors.cyan
            : Color.lerp(AurosColors.kelp, AurosColors.cyan, .62)!;
        final pointRadius = unit * (.6 + light * .8);
        if (front && point.index % 31 == 0) {
          glow.color = color.withValues(alpha: .07);
          canvas.drawCircle(projected.position, pointRadius * 2.8, glow);
        }
        dot.color = color.withValues(
          alpha: (.23 + light * .64) * (.53 + point.ridge * .47),
        );
        canvas.drawCircle(projected.position, pointRadius, dot);
      }
    }

    // The darker channel and quiet rim define actual curved cortical folds,
    // rather than adding a flat brain outline on top of the particle cloud.
    final sulcus = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = unit * 2.7
      ..color = AurosColors.deep.withValues(alpha: .82);
    final foldRim = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = unit * .65
      ..color = AurosColors.cyan.withValues(alpha: .19);
    for (final fold in _geometry.folds) {
      final path = _path(fold, projection);
      canvas.drawPath(path, sulcus);
      canvas.drawPath(path, foldRim);
    }

    final connection = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = unit * .7;
    for (final route in _geometry.routes) {
      connection.color = route.color.withValues(alpha: .13);
      canvas.drawPath(_path(route.points, projection), connection);
      final progress =
          ((phase / (2 * math.pi)) * route.cycles + route.offset) % 1;
      // All samples fade at both ends. The wrapped head and its tail therefore
      // have no visible jump, including the seam between time 8 and time 0.
      for (var tail = 9; tail >= 0; tail--) {
        final p = (progress - tail * .023 + 1) % 1;
        final envelope = math.pow(math.sin(math.pi * p), 2).toDouble();
        final strength = envelope * math.pow(.73, tail).toDouble();
        final position = projection.project(route.sample(p)).position;
        glow.color = route.color.withValues(alpha: strength * .10);
        canvas.drawCircle(position, unit * (tail == 0 ? 6.2 : 3.0), glow);
        dot.color = route.color.withValues(alpha: strength * .9);
        canvas.drawCircle(position, unit * (tail == 0 ? 2.0 : .95), dot);
      }
    }
    canvas.restore();
  }

  Path _path(List<_BrainPoint> points, _BrainProjection projection) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = projection.project(points[i]).position;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(HeroParticleOrbPainter oldDelegate) =>
      oldDelegate.time != time;
}

class _BrainGeometry {
  const _BrainGeometry(this.points, this.folds, this.routes);
  final List<_BrainPoint> points;
  final List<List<_BrainPoint>> folds;
  final List<_BrainRoute> routes;

  factory _BrainGeometry.create() {
    final points = List<_BrainPoint>.generate(1400, (index) {
      final side = index < 700 ? -1.0 : 1.0;
      final local = index % 700;
      final latitude = 1 - 2 * (local + .5) / 700;
      final radius = math.sqrt(1 - latitude * latitude);
      final longitude = local * math.pi * (3 - math.sqrt(5));
      final nx = radius * math.cos(longitude);
      final nz = radius * math.sin(longitude);
      final wrinkle = math
          .pow((math.sin(longitude * 5 + latitude * 7) + 1) / 2, 9)
          .toDouble();
      final fold = 1 - .065 * wrinkle;
      // Two separate rounded hemispheres, clipped at the medial wall, create
      // the longitudinal fissure and a walnut-like silhouette at rest.
      final x = math.max(.045, .4 + .51 * nx * fold);
      return _BrainPoint(
        side * x,
        latitude * .78 + radius * .022 * math.sin(longitude * 3),
        nz * .63 * fold,
        ridge: 1 - wrinkle,
        index: index,
      );
    }, growable: false);

    final folds = <List<_BrainPoint>>[];
    for (final side in [-1.0, 1.0]) {
      for (var track = 0; track < 7; track++) {
        folds.add(
          List<_BrainPoint>.generate(58, (step) {
            final t = step / 57;
            final y = (t * 2 - 1) * .83;
            final width = math.sqrt(1 - y * y);
            final band =
                -.72 +
                track * .23 +
                .11 * math.sin(t * math.pi * 3 + track * .83) +
                .035 * math.sin(t * math.pi * 7 + track);
            return _cortex(side, band * width, y);
          }, growable: false),
        );
      }
      // A few transverse folds break up the longitudinal rhythm, like gyri.
      for (var track = 0; track < 3; track++) {
        folds.add(
          List<_BrainPoint>.generate(46, (step) {
            final t = step / 45;
            final x = -.69 + t * 1.42;
            final y =
                -.43 +
                track * .40 +
                .075 * math.sin(t * math.pi * 3 + track * 1.2);
            return _cortex(side, x, y);
          }, growable: false),
        );
      }
    }

    final routes = <_BrainRoute>[];
    for (var i = 0; i < 6; i++) {
      final fold = folds[(i < 3 ? 0 : 10) + 1 + (i % 3) * 2];
      routes.add(
        _BrainRoute(
          fold.sublist(6, fold.length - 6),
          i.isEven ? AurosColors.cyan : AurosColors.lavender,
          (i + 1) / 8,
          i % 3 == 0 ? 2 : 1,
        ),
      );
    }
    // Two subtle interhemispheric links let thoughts meet across the fissure.
    for (var link = 0; link < 2; link++) {
      routes.add(
        _BrainRoute(
          List<_BrainPoint>.generate(42, (step) {
            final t = step / 41;
            return _BrainPoint(
              -.24 + .48 * t,
              -.25 + link * .39 + .12 * math.sin(t * math.pi),
              .58 + .07 * math.sin(t * math.pi),
            );
          }, growable: false),
          link == 0 ? AurosColors.mist : AurosColors.lavender,
          link == 0 ? .08 : .58,
          1,
        ),
      );
    }
    return _BrainGeometry(points, folds, routes);
  }

  static _BrainPoint _cortex(double side, double x, double y) {
    final z = math.sqrt(math.max(.02, 1 - x * x - y * y));
    return _BrainPoint(
      side * math.max(.045, .4 + .51 * x),
      y * .78,
      z * .63 + .012,
    );
  }
}

class _BrainRoute {
  const _BrainRoute(this.points, this.color, this.offset, this.cycles);
  final List<_BrainPoint> points;
  final Color color;
  final double offset;
  final int cycles;
  _BrainPoint sample(double progress) {
    final along = progress * (points.length - 1);
    final index = along.floor();
    final a = points[index], b = points[math.min(index + 1, points.length - 1)];
    final t = along - index;
    return _BrainPoint(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
      a.z + (b.z - a.z) * t + .025,
    );
  }
}

class _BrainProjection {
  _BrainProjection({
    required this.center,
    required this.scale,
    required double yaw,
    required double pitch,
  }) : sinYaw = math.sin(yaw),
       cosYaw = math.cos(yaw),
       sinPitch = math.sin(pitch),
       cosPitch = math.cos(pitch);
  final Offset center;
  final double scale, sinYaw, cosYaw, sinPitch, cosPitch;
  _ProjectedBrainPoint project(_BrainPoint point) {
    final x = point.x * cosYaw + point.z * sinYaw;
    final z = -point.x * sinYaw + point.z * cosYaw;
    final y = point.y * cosPitch - z * sinPitch;
    final depth = point.y * sinPitch + z * cosPitch;
    final perspective = 3.6 / (3.6 - depth);
    return _ProjectedBrainPoint(
      center + Offset(x, -y) * scale * perspective,
      depth,
    );
  }
}

class _ProjectedBrainPoint {
  const _ProjectedBrainPoint(this.position, this.depth);
  final Offset position;
  final double depth;
}

class _BrainPoint {
  const _BrainPoint(this.x, this.y, this.z, {this.ridge = 1, this.index = 0});
  final double x, y, z, ridge;
  final int index;
}
