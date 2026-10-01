import 'package:flutter/material.dart';

import '../tokens.dart';

class PixelAvatar extends StatelessWidget {
  const PixelAvatar({super.key, this.size = 80});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Steve, seu companheiro de estudo',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _PixelPainter()),
    ),
  );
}

class _PixelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 16;
    final grid = [
      '......bb........',
      '.....bbbb.......',
      '...bbbbbbbbbb...',
      '..bwwwwwwwwwwb..',
      '..bwbbwwbbwwwb..',
      '..bwwwwwwwwwwb..',
      '..bwwbbbbwwwwb..',
      '...bbbbbbbbbb...',
      '......bb........',
      '..bbbbbbbbbbbb..',
      '..bvvvbbvvvwwb..',
      '..bvvvbbvvvwwb..',
      '..bvvvbbvvvwwb..',
      '...bbbbbbbbbb...',
      '....bb....bb....',
      '...bbb....bbb...',
    ];
    final colors = {
      'b': AppColors.pixelInk,
      'w': AppColors.white,
      'v': AppColors.pixelViolet,
    };
    for (var y = 0; y < grid.length; y++) {
      for (var x = 0; x < grid[y].length; x++) {
        final color = colors[grid[y][x]];
        if (color != null) {
          canvas.drawRect(
            Rect.fromLTWH(x * unit, y * unit, unit, unit),
            Paint()
              ..color = color
              ..isAntiAlias = false,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PixelPainter oldDelegate) => false;
}
