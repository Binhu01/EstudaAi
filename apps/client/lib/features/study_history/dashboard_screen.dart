import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_catalog_providers.dart';
import '../learning/study_routes.dart';
import 'dashboard_controller.dart';
import 'study_history_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider),
        view = ref.watch(dashboardProvider),
        controller = ref.read(dashboardProvider.notifier),
        data = view.data;
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
        const SizedBox(height: 24),
        if (!session.isAuthenticated)
          const HistoryLoginGate()
        else ...[
          if (view.pending)
            const LinearProgressIndicator(
              semanticsLabel: 'Carregando seu estudo',
            ),
          if (view.error case final error?) ...[
            HistoryFailure(error: error, onRetry: controller.retry),
            const SizedBox(height: 16),
            if (data == null)
              OutlinedButton(
                onPressed: practice,
                child: const Text('Voltar ao estudo'),
              ),
          ],
          if (data != null) ...[
          Card(
            semanticContainer:false,
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${data.today.differentQuestions} de ${data.goal.dailyTarget} questões diferentes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value:
                          (data.today.differentQuestions /
                                  data.goal.dailyTarget)
                              .clamp(0, 1),
                      semanticsLabel: 'Questões diferentes confirmadas hoje',
                    ),
                    const SizedBox(height: 20),
                    const Text('Meta diária'),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      isExpanded: true,
                      value: data.goal.dailyTarget,
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
                    const SizedBox(height: 12),
                    Text(
                      '${data.today.correct} ${data.today.correct == 1 ? 'acerto' : 'acertos'} em ${data.today.attempts} ${data.today.attempts == 1 ? 'tentativa' : 'tentativas'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.pendingErrors} ${data.pendingErrors == 1 ? 'erro pendente' : 'erros pendentes'}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/meus-erros'),
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: const Text('Revisar meus erros'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: entry == null ? null : practice,
              icon: const Icon(Icons.play_arrow_outlined),
              label: Text(
                resume == null
                    ? 'Começar meu primeiro desafio'
                    : 'Continuar último assunto praticado',
              ),
            ),
            if (resume == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Responda um desafio para começar seu histórico. Cada resposta confirmada conta, mesmo antes de terminar a rodada.',
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Últimos sete dias',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final day in data.activity)
                  Semantics(
                    label:
                        '${day.date}: ${day.differentQuestions} questões diferentes, ${day.attempts} tentativas',
                    child: Chip(
                      label: Text(
                        '${day.date.substring(8)}/${day.date.substring(5, 7)} · ${day.differentQuestions} questões',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Acertos por assunto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (data.subjects.isEmpty)
              const Text(
                'Seu desempenho aparece aqui depois das primeiras respostas confirmadas.',
              ),
            for (final subject in data.subjects)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${subject.title}: ${subject.correct} acertos em ${subject.attempts} tentativas',
                ),
              ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: view.pending || view.saving ? null : controller.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar meu estudo'),
            ),
          ],
        ],
      ],
    );
  }
}
