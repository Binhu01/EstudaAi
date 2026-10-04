import 'package:flutter/material.dart';

import '../../design_system/tokens.dart';

/// A readable study console, with the handheld identity confined to the game.
class QuizConsole extends StatelessWidget {
  const QuizConsole({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      return Container(
        padding: EdgeInsets.all(compact ? 12 : 24),
        decoration: BoxDecoration(
          color: GameColors.yellow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(color: GameColors.ink, offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 12,
              children: [
                Text(
                  'ESTUDA AÍ',
                  style: AppTypography.pixel.copyWith(
                    color: GameColors.ink,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'DESAFIO 8 BITS',
                  style: AppTypography.pixel.copyWith(
                    color: GameColors.ink,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(compact ? 16 : 28),
              decoration: BoxDecoration(
                color: GameColors.screen,
                border: Border.all(color: GameColors.ink, width: 6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: GameColors.screenInk,
                    displayColor: GameColors.screenInk,
                  ),
                  iconTheme: const IconThemeData(color: GameColors.screenInk),
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: GameColors.screenInk,
                    fontSize: 16,
                    height: 1.6,
                  ),
                  child: child,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ExcludeSemantics(
              child: Row(
                children: [
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CustomPaint(painter: _ConsoleDetail()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'SEM CRONÔMETRO',
                      style: AppTypography.pixel.copyWith(
                        color: GameColors.ink,
                        fontSize: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.more_horiz, color: GameColors.ink, size: 32),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return GameColors.screenInk.withValues(alpha: 0.15);
        }
        return secondary ? GameColors.screen : GameColors.violet;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return GameColors.screenInk;
        return secondary ? GameColors.screenInk : Colors.white;
      }),
      minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: GameColors.screenInk, width: 3);
        }
        return BorderSide(
          color: secondary ? GameColors.screenInk : GameColors.violet,
          width: 1.5,
        );
      }),
      overlayColor: WidgetStatePropertyAll(
        (secondary ? GameColors.violet : Colors.white).withValues(alpha: 0.1),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.4),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

/// Original one-bit book artwork. It adds no unearned rewards or game state.
class PixelStudyArt extends StatelessWidget {
  const PixelStudyArt({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _StudyArt()),
    ),
  );
}

class _StudyArt extends CustomPainter {
  const _StudyArt();

  @override
  void paint(Canvas canvas, Size size) {
    const rows = [
      '................',
      '.##..........##.',
      '.#.###....###.#.',
      '.#....####....#.',
      '.#.##..##..##.#.',
      '.#.....##.....#.',
      '.#.###.##.###.#.',
      '.#.....##.....#.',
      '.#.##..##..##.#.',
      '.#.....##.....#.',
      '.######..######.',
      '.......##.......',
      '................',
      '..##........##..',
      '...##########...',
      '................',
    ];
    final unit = size.width / 16;
    final paint = Paint()
      ..color = GameColors.screenInk
      ..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] == '#') {
          canvas.drawRect(Rect.fromLTWH(x * unit, y * unit, unit, unit), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StudyArt oldDelegate) => false;
}

class _ConsoleDetail extends CustomPainter {
  const _ConsoleDetail();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 7;
    final paint = Paint()
      ..color = GameColors.ink
      ..isAntiAlias = false;
    canvas.drawRect(Rect.fromLTWH(2 * unit, 0, 3 * unit, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, 2 * unit, size.width, 3 * unit), paint);
    canvas.drawRect(
      Rect.fromLTWH(3 * unit, 3 * unit, unit, unit),
      Paint()..color = GameColors.yellow,
    );
  }

  @override
  bool shouldRepaint(_ConsoleDetail oldDelegate) => false;
}
