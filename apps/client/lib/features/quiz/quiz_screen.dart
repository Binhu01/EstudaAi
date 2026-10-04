import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/tokens.dart';
import '../learning/learning_entry.dart';
import '../learning/learning_entry_view.dart';
import '../learning/study_routes.dart';
import '../contests/contest_module_actions.dart';
import 'quiz_engine.dart';
import 'quiz_controller.dart';
import 'answer_tile.dart';
import 'quiz_console.dart';
import 'quiz_result.dart';
import '../study_history/answer_submission.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({
    super.key,
    required this.topicId,
    this.area = LearningArea.freeStudy,
  });
  final String topicId;
  final LearningArea area;
  @override
  Widget build(BuildContext context) => LearningEntryView(
    topicId: topicId,
    area: area,
    builder: (entry) => SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Desafios',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cinco perguntas. Seu ritmo. Um novo nível de conhecimento.',
                ),
                const SizedBox(height: 24),
                LearningEntrySelector(entry: entry, action: StudyAction.quiz),
                if (entry.area == LearningArea.contest) ...[
                  const SizedBox(height: 20),
                  ContestModuleActions(
                    entry: entry,
                    selected: StudyAction.quiz,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Desafio formativo · ${entry.courseTitle} · ${entry.topic.subject}',
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  entry.topic.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _Round(key: ValueKey(topicId), entry: entry),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Round extends ConsumerWidget {
  const _Round({super.key, required this.entry});
  final LearningEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicId = entry.topic.id;
    final view = ref.watch(quizProvider(topicId));
    final controller = ref.read(quizProvider(topicId).notifier);
    final round = view.round;
    if (!view.started) {
      return QuizConsole(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PixelStudyArt(),
            const SizedBox(height: 24),
            Text(
              'PRONTO PARA JOGAR?',
              style: AppTypography.pixel.copyWith(color: GameColors.screenInk),
            ),
            const SizedBox(height: 20),
            const Text(
              'Responda cinco questões e descubra o porquê de cada resposta. Acertos em sequência ganham bônus. Não há limite de tempo.',
            ),
            const SizedBox(height: 24),
            const Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _GameRule(icon: Icons.quiz_outlined, text: '5 questões'),
                _GameRule(icon: Icons.timer_off_outlined, text: 'Sem pressa'),
                _GameRule(
                  icon: Icons.auto_stories_outlined,
                  text: 'Aprenda a cada resposta',
                ),
              ],
            ),
            const SizedBox(height: 28),
            GameButton(
              label: 'Começar desafio',
              icon: Icons.play_arrow_rounded,
              onPressed: controller.start,
            ),
          ],
        ),
      );
    }
    if (round.phase == QuizPhase.completed) {
      return QuizResult(entry: entry, result: view, onRepeat: controller.start);
    }
    final q = round.question, locked = round.phase == QuizPhase.feedback;
    return QuizConsole(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 24,
            runSpacing: 12,
            children: [
              Text(
                'QUESTÃO ${round.questionIndex + 1}/5',
                style: AppTypography.pixel.copyWith(
                  color: GameColors.screenInk,
                  fontSize: 10,
                ),
              ),
              Text(
                '${round.score} PTS',
                style: AppTypography.pixel.copyWith(
                  color: GameColors.screenInk,
                  fontSize: 10,
                ),
              ),
              Text('Sequência: ${round.streak}'),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: (round.questionIndex + 1) / 5,
            semanticsLabel: 'Progresso do desafio',
            color: GameColors.screenInk,
            backgroundColor: GameColors.screenInk.withValues(alpha: 0.15),
            minHeight: 6,
            borderRadius: BorderRadius.zero,
          ),
          const SizedBox(height: 28),
          Text(
            q.prompt,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: GameColors.screenInk, height: 1.5),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns =
                  constraints.maxWidth >= 660 &&
                  MediaQuery.textScalerOf(context).scale(16) <= 24;
              final width = twoColumns
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (var i = 0; i < 4; i++)
                    SizedBox(
                      width: width,
                      child: AnswerTile(
                        index: i,
                        text: q.options[i],
                        selected: round.selectedIndex == i,
                        correct: locked && q.correctIndex == i,
                        onPressed: locked ? null : () => controller.answer(i),
                      ),
                    ),
                ],
              );
            },
          ),
          if (locked)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: GameColors.screenInk, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Icon(
                        round.selectedIndex == q.correctIndex
                            ? Icons.check_circle_outline
                            : Icons.lightbulb_outline,
                        color: GameColors.screenInk,
                      ),
                      Text(
                        round.selectedIndex == q.correctIndex
                            ? 'Resposta correta!'
                            : 'Vamos aprender com essa resposta',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: GameColors.screenInk),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(q.explanation),
                  const SizedBox(height: 20),
                  if (view.history.status == SubmissionStatus.sending) ...[
                    Semantics(
                      liveRegion: true,
                      child: const Text('Confirmando sua resposta…'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (view.history.status == SubmissionStatus.confirmed) ...[
                    Semantics(
                      liveRegion: true,
                      child: const Text('Resposta salva na sua conta.'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (view.history.status == SubmissionStatus.unconfirmed) ...[
                    Semantics(
                      liveRegion: true,
                      child: const Text(
                        'Não foi possível confirmar o registro desta resposta. Tente novamente ou continue estudando.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        GameButton(
                          label: 'Tentar novamente',
                          secondary: true,
                          onPressed: controller.retryHistory,
                        ),
                        GameButton(
                          label: 'Continuar estudo',
                          secondary: true,
                          onPressed: controller.continueStudy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  GameButton(
                    label: round.questionIndex == 4
                        ? 'Ver resultado'
                        : 'Próxima pergunta',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: view.canAdvance ? controller.next : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GameRule extends StatelessWidget {
  const _GameRule({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: GameColors.screenInk),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(
            color: GameColors.screenInk,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
