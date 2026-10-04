import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/study_card.dart';
import '../../design_system/tokens.dart';
import '../learning/learning_entry.dart';
import '../learning/study_routes.dart';
import 'study_history_models.dart';

class DailyStudyPlan extends StatelessWidget {
  const DailyStudyPlan({
    super.key,
    required this.data,
    required this.entry,
    required this.onPractice,
  });
  final StudyDashboard data;
  final LearningEntry? entry;
  final VoidCallback onPractice;
  @override
  Widget build(BuildContext context) {
    final remaining = (data.goal.dailyTarget - data.today.differentQuestions)
        .clamp(0, data.goal.dailyTarget);
    final canResume =
        data.resume != null &&
        entry != null &&
        data.resume!.contentVersion == entry!.contentVersion;
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seu próximo passo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            remaining == 0
                ? 'Meta de hoje concluída'
                : 'Faltam $remaining questões para sua meta',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            data.pendingErrors > 0
                ? 'Comece pelas dúvidas pendentes, retome o conteúdo e pratique uma nova rodada.'
                : remaining == 0
                ? 'Você pode encerrar por hoje ou explorar outro assunto no seu ritmo.'
                : 'Estude o conteúdo e teste o que aprendeu. Cada questão diferente respondida hoje conta para sua meta.',
          ),
          if (entry != null) ...[
            const SizedBox(height: 16),
            Text(
              '${canResume ? 'Último assunto praticado' : 'Assunto selecionado'} · ${entry!.topic.title}',
              style: TextStyle(color: AppColors.of(context).muted),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (canResume)
                FilledButton.icon(
                  onPressed: () => context.go(
                    StudyRoutes.path(
                      entry!,
                      entry!.area == LearningArea.contest
                          ? StudyAction.material
                          : StudyAction.lessons,
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Continuar estudando'),
                ),
              if (data.pendingErrors > 0)
                OutlinedButton.icon(
                  onPressed: () => context.go('/meus-erros'),
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: const Text('Revisar pendências'),
                ),
              OutlinedButton.icon(
                onPressed: onPractice,
                icon: const Icon(Icons.play_arrow_outlined),
                label: Text(
                  data.resume == null
                      ? 'Começar meu primeiro desafio'
                      : 'Praticar uma rodada',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StudyProgressPanel extends StatelessWidget {
  const StudyProgressPanel({super.key, required this.progress});
  final StudyProgress progress;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final questionMilestone = progress.catalogQuestions < 25
        ? progress.catalogQuestions
        : 25;
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sua evolução', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Respostas confirmadas nesta área de estudo. Repetições não aumentam a cobertura.',
            style: TextStyle(color: colors.muted),
          ),
          const SizedBox(height: 24),
          Text(
            '${progress.practicedQuestions} de ${progress.catalogQuestions} questões praticadas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.catalogQuestions == 0
                ? 0
                : progress.practicedQuestions / progress.catalogQuestions,
            minHeight: 8,
            semanticsLabel: 'Cobertura de questões praticadas',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 28,
            runSpacing: 20,
            children: [
              _ProgressStat(
                icon: Icons.local_fire_department_outlined,
                text:
                    '${progress.currentStreak} ${progress.currentStreak == 1 ? 'dia de sequência' : 'dias de sequência'}',
                detail:
                    'Maior sequência: ${progress.bestStreak} ${progress.bestStreak == 1 ? 'dia' : 'dias'}',
              ),
              _ProgressStat(
                icon: Icons.event_available_outlined,
                text:
                    '${progress.activeDays} ${progress.activeDays == 1 ? 'dia com estudo' : 'dias com estudo'}',
                detail: 'Ao menos uma resposta confirmada',
              ),
              _ProgressStat(
                icon: Icons.task_alt,
                text:
                    '${progress.reviewedErrors} ${progress.reviewedErrors == 1 ? 'erro revisado' : 'erros revisados'}',
                detail: 'Erros com último resultado correto',
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Conquistas de aprendizagem',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Milestone(
                title: 'Primeira prática',
                detail: 'Responder uma questão',
                earned: progress.practicedQuestions > 0,
              ),
              _Milestone(
                title: 'Primeira revisão',
                detail: 'Acertar uma questão na revisão',
                earned: progress.correctReviewQuestions > 0,
              ),
              _Milestone(
                title: '3 dias seguidos',
                detail: 'Estudar em três dias consecutivos',
                earned: progress.bestStreak >= 3,
              ),
              _Milestone(
                title: '$questionMilestone questões',
                detail: 'Praticar $questionMilestone questões diferentes',
                earned:
                    questionMilestone > 0 &&
                    progress.practicedQuestions >= questionMilestone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.icon,
    required this.text,
    required this.detail,
  });
  final IconData icon;
  final String text, detail;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 260),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.of(context).primary),
        const SizedBox(height: 8),
        Text(text, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          detail,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.of(context).muted),
        ),
      ],
    ),
  );
}

class _Milestone extends StatelessWidget {
  const _Milestone({
    required this.title,
    required this.detail,
    required this.earned,
  });
  final String title, detail;
  final bool earned;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title: ${earned ? 'alcançada' : 'a conquistar'}. $detail',
    excludeSemantics: true,
    child: Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.of(context).border),
        borderRadius: BorderRadius.circular(8),
        color: earned ? AppColors.of(context).successSoft : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            earned ? Icons.verified_outlined : Icons.lock_outline,
            color: earned
                ? AppColors.of(context).successInk
                : AppColors.of(context).muted,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: earned ? AppColors.of(context).successInk : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            earned ? 'Alcançada' : detail,
            style: TextStyle(
              color: earned
                  ? AppColors.of(context).successInk
                  : AppColors.of(context).muted,
            ),
          ),
        ],
      ),
    ),
  );
}
