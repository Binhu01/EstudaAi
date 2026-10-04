import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/study_card.dart';
import '../../design_system/tokens.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_catalog_providers.dart';
import '../learning/learning_entry.dart';
import '../learning/study_routes.dart';
import 'errors_controller.dart';
import 'error_review_batch.dart';
import 'study_history_models.dart';
import 'study_history_widgets.dart';

class ErrorsScreen extends ConsumerWidget {
  const ErrorsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(errorsProvider),
        controller = ref.read(errorsProvider.notifier),
        colors = AppColors.of(context);
    final free = ref.watch(catalogProvider),
        contests = ref.watch(contestCatalogProvider),
        area = ref.watch(learningProvider).area;
    final subjects = area == LearningArea.freeStudy
        ? {for (final t in free.asData?.value.topics ?? []) t.id: t.title}
        : {
            for (final d in contests.asData?.value.disciplines ?? [])
              d.id: d.title,
          };
    final current = view.items
            .where((e) => e.contentStatus == ContentStatus.current)
            .toList(),
        old = view.items
            .where((e) => e.contentStatus == ContentStatus.outdated)
            .toList();
    return StudyHistoryPage(
      title: 'Seu caderno de erros',
      children: [
        const HistoryAreaPicker(),
        const SizedBox(height: 28),
        if (!ref.watch(sessionProvider).isAuthenticated)
          const HistoryLoginGate()
        else ...[
          Text(
            'Revisite suas respostas, entenda o motivo do erro e pratique de novo. Uma resposta correta confirmada marca a questão como revisada.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 24),
          StudyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final status in ErrorStatus.values)
                      ChoiceChip(
                        avatar: Icon(
                          status == ErrorStatus.pending
                              ? Icons.bookmark_border_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          status == ErrorStatus.pending
                              ? 'Pendentes'
                              : 'Revisados',
                        ),
                        selected: view.query.status == status,
                        onSelected: (_) => controller.load(
                          ErrorQuery(
                            status: status,
                            subjectId: view.query.subjectId,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  style: Theme.of(context).textTheme.bodyLarge,
                  key: ValueKey('${area.name}-${view.query.subjectId}'),
                  initialValue: subjects.containsKey(view.query.subjectId)
                      ? view.query.subjectId
                      : '',
                  isExpanded: true,
                  itemHeight: null,
                  decoration: InputDecoration(
                    labelText: area == LearningArea.freeStudy
                        ? 'Assunto'
                        : 'Disciplina',
                    prefixIcon: const Icon(Icons.filter_list_rounded),
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todos')),
                    for (final e in subjects.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (id) => controller.load(
                    ErrorQuery(
                      status: view.query.status,
                      subjectId: id == '' ? null : id,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (view.pending)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: LinearProgressIndicator(
                semanticsLabel: 'Carregando seu caderno',
              ),
            ),
          if (view.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: HistoryFailure(
                error: view.error!,
                onRetry: controller.retry,
              ),
            ),
          if (!view.pending && view.error == null && view.items.isEmpty)
            StudyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    view.query.status == ErrorStatus.pending
                        ? Icons.check_circle_outline_rounded
                        : Icons.auto_stories_outlined,
                    color: colors.muted,
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    view.query.status == ErrorStatus.pending
                        ? 'Nenhum erro pendente neste filtro. Continue praticando.'
                        : 'Nenhuma questão revisada neste filtro.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          if (view.query.status == ErrorStatus.pending &&
              current.isNotEmpty) ...[
            FilledButton.icon(
              onPressed: view.pending
                  ? null
                  : () {
                      final session = ref.read(sessionProvider);
                      if (!session.isAuthenticated) return;
                      context.go(
                        '/meus-erros/revisao',
                        extra: ErrorReviewBatch(
                          userId: session.profile!.id,
                          sessionGeneration: session.generation,
                          area: area,
                          items: current,
                        ),
                      );
                    },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Revisar até 5 erros'),
            ),
            const SizedBox(height: 12),
            Text(
              'Rodada com questões pendentes deste filtro. Você aprende com a explicação antes de avançar.',
              style: TextStyle(color: colors.muted),
            ),
            const SizedBox(height: 24),
          ],
          for (final item in current) _ErrorCard(item: item),
          if (old.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Conteúdo de outra versão',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Estes registros ficam no seu histórico. A revisão usa somente questões da versão atual.',
              style: TextStyle(color: colors.muted),
            ),
            const SizedBox(height: 20),
            for (final item in old) _ErrorCard(item: item),
          ],
          if (view.nextCursor != null)
            OutlinedButton(
              onPressed: view.pending ? null : controller.nextPage,
              child: const Text('Carregar mais'),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: view.pending ? null : controller.retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar caderno'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorCard extends ConsumerWidget {
  const _ErrorCard({required this.item});
  final StudyErrorItem item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(learningEntryProvider(item.topicId)).asData?.value,
        colors = AppColors.of(context),
        outdated = item.contentStatus == ContentStatus.outdated;
    final q = outdated || entry?.contentVersion != item.contentVersion
        ? null
        : entry?.topic.questions
              .where((q) => q.id == item.questionId)
              .firstOrNull;
    final reviewed = item.status == ErrorStatus.reviewed;
    final date = item.lastWrongAt.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: StudyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: reviewed ? colors.successSoft : colors.accentSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    reviewed ? 'Revisado' : 'Pendente',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: reviewed ? colors.successInk : colors.accentInk,
                    ),
                  ),
                ),
                Text(
                  '${item.wrongCount} ${item.wrongCount == 1 ? 'erro registrado' : 'erros registrados'}',
                  style: TextStyle(color: colors.muted),
                ),
                Text(
                  'Último erro · ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.muted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              entry?.topic.title ?? 'Conteúdo anterior',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: colors.muted),
            ),
            if (q != null) ...[
              const SizedBox(height: 8),
              Text(q.prompt, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Entender esta questão'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Última resposta registrada: ${q.options[item.lastOptionIndex]}',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Resposta correta: ${q.options[q.correctIndex]}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Text(q.explanation),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (!outdated && q != null)
              FilledButton.icon(
                onPressed: () => context.go(
                  '/meus-erros/${item.topicId}/${item.contentVersion}/${item.questionId}',
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Revisar questão'),
              )
            else
              OutlinedButton(
                onPressed: () => context.go(
                  entry == null
                      ? '/meu-estudo'
                      : StudyRoutes.path(entry, StudyAction.lessons),
                ),
                child: const Text('Estudar conteúdo atual'),
              ),
          ],
        ),
      ),
    );
  }
}
