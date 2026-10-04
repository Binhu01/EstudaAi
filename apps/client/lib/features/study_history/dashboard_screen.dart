import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/study_card.dart';
import '../../design_system/tokens.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_catalog_providers.dart';
import '../learning/study_routes.dart';
import 'dashboard_controller.dart';
import 'daily_study_plan.dart';
import 'study_history_models.dart';
import 'study_history_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider),
        view = ref.watch(dashboardProvider),
        controller = ref.read(dashboardProvider.notifier),
        data = view.data,
        colors = AppColors.of(context);
    final selection = ref.watch(learningProvider), resume = data?.resume;
    final entry = ref
        .watch(learningEntryProvider(resume?.topicId ?? selection.topicId))
        .asData
        ?.value;
    void practice() {
      if (entry != null &&
          (resume == null || entry.contentVersion == resume.contentVersion)) {
        context.go(StudyRoutes.path(entry, StudyAction.quiz));
      } else {
        context.go(selection.area.name == 'contest' ? '/concursos' : '/');
      }
    }

    return StudyHistoryPage(
      title: 'Seu estudo de hoje',
      children: [
        const HistoryAreaPicker(),
        const SizedBox(height: 28),
        if (!session.isAuthenticated)
          const HistoryLoginGate()
        else ...[
          if (view.pending)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: LinearProgressIndicator(
                semanticsLabel: 'Carregando seu estudo',
              ),
            ),
          if (view.error case final error?) ...[
            HistoryFailure(error: error, onRetry: controller.retry),
            const SizedBox(height: 20),
            if (data == null)
              OutlinedButton(
                onPressed: practice,
                child: const Text('Voltar ao estudo'),
              ),
          ],
          if (data != null) ...[
            DailyStudyPlan(data: data, entry: entry, onPractice: practice),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 780 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 22;
                final goal = StudyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, color: colors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Meta diária',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${data.today.differentQuestions} de ${data.goal.dailyTarget} questões diferentes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value:
                            (data.today.differentQuestions /
                                    data.goal.dailyTarget)
                                .clamp(0, 1),
                        semanticsLabel: 'Questões diferentes confirmadas hoje',
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${data.today.correct} ${data.today.correct == 1 ? 'acerto' : 'acertos'} em ${data.today.attempts} ${data.today.attempts == 1 ? 'tentativa' : 'tentativas'}',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<int>(
                        style: Theme.of(context).textTheme.bodyLarge,
                        key: ValueKey(data.goal.dailyTarget),
                        initialValue: data.goal.dailyTarget,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Questões por dia',
                        ),
                        onChanged: view.saving || view.pending
                            ? null
                            : (value) {
                                if (value != null) {
                                  controller.setDailyTarget(value);
                                }
                              },
                        items: [
                          for (final value in [5, 10, 20])
                            DropdownMenuItem(
                              value: value,
                              child: Text('$value questões'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
                final review = HistoryPanel(
                  title:
                      '${data.pendingErrors} ${data.pendingErrors == 1 ? 'erro pendente' : 'erros pendentes'}',
                  icon: Icons.auto_stories_outlined,
                  description:
                      'Uma nova tentativa ajuda a fixar o que você aprendeu.',
                  child: FilledButton.icon(
                    onPressed: () => context.go('/meus-erros'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Revisar meus erros'),
                  ),
                );
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: goal),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: review),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [goal, const SizedBox(height: 20), review],
                      );
              },
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 32),
            if (data.progress != null) ...[
              StudyProgressPanel(progress: data.progress!),
              const SizedBox(height: 24),
            ],
            HistoryPanel(
              title: 'Últimos sete dias',
              description: 'Questões diferentes confirmadas em cada dia.',
              child: _WeekActivity(days: data.activity),
            ),
            const SizedBox(height: 24),
            HistoryPanel(
              title: 'Acertos por assunto',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.subjects.isEmpty)
                    Text(
                      'Seu desempenho aparece aqui depois das primeiras respostas confirmadas.',
                      style: TextStyle(color: colors.muted),
                    ),
                  for (var i = 0; i < data.subjects.length; i++) ...[
                    if (i != 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(height: 1),
                      ),
                    Text(
                      data.subjects[i].title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (data.subjects[i].progress case final progress?) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${progress.practicedQuestions} de ${progress.catalogQuestions} questões praticadas',
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value:
                            progress.practicedQuestions /
                            progress.catalogQuestions,
                        semanticsLabel:
                            'Cobertura de ${data.subjects[i].title}',
                        minHeight: 5,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${progress.latestCorrectQuestions} acertos na última resposta de cada questão',
                        style: TextStyle(color: colors.muted),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${data.subjects[i].title}: ${data.subjects[i].correct} acertos em ${data.subjects[i].attempts} tentativas',
                      style: TextStyle(color: colors.muted),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value:
                          data.subjects[i].correct / data.subjects[i].attempts,
                      semanticsLabel:
                          'Proporção de acertos em ${data.subjects[i].title}',
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: view.pending || view.saving ? null : controller.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar meu estudo'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _WeekActivity extends StatelessWidget {
  const _WeekActivity({required this.days});
  final List<DailyActivity> days;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final most = days.fold<int>(
      1,
      (max, day) => day.differentQuestions > max ? day.differentQuestions : max,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
        final columns = constraints.maxWidth >= (largeText ? 840 : 630)
            ? 7
            : (largeText ? 2 : 3);
        final tileWidth = (constraints.maxWidth - 12 * (columns - 1)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 20,
          children: [
            for (final day in days)
              Semantics(
                label:
                    '${day.date}: ${day.differentQuestions} questões diferentes, ${day.attempts} tentativas',
                excludeSemantics: true,
                child: SizedBox(
                  width: tileWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${day.differentQuestions}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: day.differentQuestions / most,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${day.date.substring(8)}/${day.date.substring(5, 7)}',
                        style: TextStyle(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
