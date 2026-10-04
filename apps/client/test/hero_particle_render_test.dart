import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/design_system/tokens.dart';
import 'package:estuda_ai/features/home/hero_particle_orb.dart';

Future<Uint8List> renderParticles(double time, int dimension) async {
  const margin = 12;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawColor(AurosColors.abyss, BlendMode.src)
    ..translate(margin.toDouble(), margin.toDouble());
  HeroParticleOrbPainter(time: time)
      .paint(canvas, Size.square(dimension.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    dimension + margin * 2,
    dimension + margin * 2,
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'particle thoughts move, loop seamlessly and remain inside the hero',
    () async {
      for (final dimension in [200, 240, 300]) {
        final first = await renderParticles(0, dimension);
        final moving = await renderParticles(2, dimension);
        final last = await renderParticles(8, dimension);
        expect(
          listEquals(first, moving),
          isFalse,
          reason: 'Visible pixels must change with time.',
        );
        expect(
          listEquals(first, last),
          isTrue,
          reason: 'The eight second cycle must close without a jump.',
        );
        final side = dimension + 24;
        var visiblePixels = 0;
        var escapedPixels = 0;
        for (var y = 0; y < side; y++) {
          for (var x = 0; x < side; x++) {
            final offset = (y * side + x) * 4;
            final painted =
                moving[offset] != 1 ||
                moving[offset + 1] != 38 ||
                moving[offset + 2] != 36;
            if (!painted) continue;
            visiblePixels++;
            if (x < 12 ||
                y < 12 ||
                x >= dimension + 12 ||
                y >= dimension + 12) {
              escapedPixels++;
            }
          }
        }
        expect(
          visiblePixels,
          greaterThan(300),
          reason: 'The graphic must remain visible.',
        );
        expect(
          escapedPixels,
          0,
          reason: 'Particles and thought trails must stay within their allocated space.',
        );
      }
    },
  );
}
