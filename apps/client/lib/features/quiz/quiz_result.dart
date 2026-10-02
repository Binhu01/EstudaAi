import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/pixel_avatar.dart';
import '../../design_system/tokens.dart';
import '../settings/settings_controller.dart';
import 'quiz_controller.dart';
import '../learning/learning_entry.dart';
import '../learning/study_routes.dart';

class QuizResult extends ConsumerWidget {
  const QuizResult({
    super.key,
    required this.entry,
    required this.result,
    required this.onRepeat,
  });
  final LearningEntry entry;
  final QuizViewState result;
  final VoidCallback onRepeat;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Celebration(
        animate:
            result.round.correctCount >= 3 &&
            ref.watch(settingsProvider).animate &&
            !MediaQuery.disableAnimationsOf(context),
      ),
      const SizedBox(height: 24),
      Text('RODADA COMPLETA', style: AppTypography.pixel),
      const SizedBox(height: 24),
      Text(
        '${result.round.correctCount} de 5 acertos',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      Text(
        '${result.round.score} / 700 pontos',
        style: AppTypography.pixel.copyWith(fontSize: 18),
      ),
      const SizedBox(height: 20),
      Text('Melhor neste dispositivo: ${result.best}'),
      const SizedBox(height: 8),
      const Text(
        'O recorde é por assunto e fica salvo somente neste dispositivo.',
      ),
      if (result.saving)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Salvando recorde…'),
        ),
      if (result.saveFailed)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Seu resultado está aqui, mas não foi possível salvar o recorde.',
          ),
        ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton(
            onPressed: onRepeat,
            child: const Text('Repetir desafio'),
          ),
          OutlinedButton(
            onPressed: () =>
                context.go(StudyRoutes.path(entry, StudyAction.lessons)),
            child: const Text('Assistir aula'),
          ),
          if (entry.area == LearningArea.contest) ...[
            OutlinedButton(
              onPressed: () =>
                  context.go(StudyRoutes.path(entry, StudyAction.material)),
              child: const Text('Revisar material'),
            ),
            OutlinedButton(
              onPressed: () =>
                  context.go(StudyRoutes.path(entry, StudyAction.steve)),
              child: const Text('Perguntar ao Steve'),
            ),
          ],
        ],
      ),
    ],
  );
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.animate});
  final bool animate;
  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_Celebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    height: 110,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const PixelAvatar(),
        if (widget.animate)
          ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) => CustomPaint(
                size: const Size(160, 110),
                painter: _Confetti(_controller.value),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Confetti extends CustomPainter {
  const _Confetti(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) {
      return;
    }
    for (var i = 0; i < 12; i++) {
      final x = (i * 43 % 150).toDouble();
      final y = -10 + progress * (70 + i * 4);
      canvas.drawRect(
        Rect.fromLTWH(x, y, 5, 5),
        Paint()
          ..color = AppColors.quizAnswers[i % 4].withValues(alpha: 1 - progress)
          ..isAntiAlias = false,
      );
    }
  }

  @override
  bool shouldRepaint(_Confetti oldDelegate) => oldDelegate.progress != progress;
}
