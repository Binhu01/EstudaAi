import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/tokens.dart';
import '../../design_system/components/pixel_avatar.dart';
import '../learning/learning_entry.dart';
import '../learning/learning_entry_view.dart';
import '../learning/study_routes.dart';
import '../contests/contest_module_actions.dart';
import 'quiz_engine.dart';
import 'quiz_controller.dart';
import 'answer_tile.dart';
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
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 24),
                _Round(key: ValueKey(topicId), entry: entry),
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
    final round = view.round, colors = AppColors.of(context);
    if (!view.started) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          border: Border.all(color: colors.primary, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PixelAvatar(),
            const SizedBox(height: 24),
            Text('PRONTO PARA JOGAR?', style: AppTypography.pixel),
            const SizedBox(height: 24),
            const Text(
              'Responda cinco questões e descubra o porquê de cada resposta. Acertos em sequência ganham bônus. Não há limite de tempo.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: controller.start,
              child: const Text('Começar desafio'),
            ),
          ],
        ),
      );
    }
    if (round.phase == QuizPhase.completed) {
      return QuizResult(entry: entry, result: view, onRepeat: controller.start);
    }
    final q = round.question, locked = round.phase == QuizPhase.feedback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            Text(
              'QUESTÃO ${round.questionIndex + 1}/5',
              style: AppTypography.pixel,
            ),
            Text('${round.score} PTS', style: AppTypography.pixel),
            Text('Sequência: ${round.streak}'),
          ],
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: (round.questionIndex + 1) / 5,
          semanticsLabel: 'Progresso do desafio',
        ),
        const SizedBox(height: 28),
        Text(q.prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns =
                constraints.maxWidth >= 700 &&
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
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: round.selectedIndex == q.correctIndex
                    ? colors.successSoft
                    : colors.warningSoft,
                border: Border.all(color: colors.border, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    children: [
                      Icon(
                        round.selectedIndex == q.correctIndex
                            ? Icons.check_circle_outline
                            : Icons.lightbulb_outline,
                      ),
                      Text(
                        round.selectedIndex == q.correctIndex
                            ? 'Resposta correta!'
                            : 'Vamos aprender com essa resposta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    q.explanation,
                    style: TextStyle(
                      color: round.selectedIndex == q.correctIndex
                          ? colors.successInk
                          : colors.warningInk,
                    ),
                  ),
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
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: controller.retryHistory,
                          child: const Text('Tentar novamente'),
                        ),
                        TextButton(
                          onPressed: controller.continueStudy,
                          child: const Text('Continuar estudo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: view.canAdvance ? controller.next : null,
                    child: Text(
                      round.questionIndex == 4
                          ? 'Ver resultado'
                          : 'Próxima pergunta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}
