import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_catalog_providers.dart';
import '../learning/learning_entry.dart';
import '../learning/study_routes.dart';
import 'errors_controller.dart';
import 'study_history_models.dart';
import 'study_history_widgets.dart';

class ErrorsScreen extends ConsumerWidget {
  const ErrorsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(errorsProvider),
        controller = ref.read(errorsProvider.notifier);
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
        const SizedBox(height: 24),
        if (!ref.watch(sessionProvider).isAuthenticated)
          const HistoryLoginGate()
        else ...[
          const Text(
            'Revisite suas respostas, entenda o motivo do erro e pratique de novo. Uma resposta correta confirmada marca a questão como revisada.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final status in ErrorStatus.values)
                ChoiceChip(
                  label: Text(
                    status == ErrorStatus.pending ? 'Pendentes' : 'Revisados',
                  ),
                  selected: view.query.status == status,
                  onSelected: (_) => controller.load(
                    ErrorQuery(status: status, subjectId: view.query.subjectId),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
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
              border: const OutlineInputBorder(),
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
          const SizedBox(height: 24),
          if (view.pending)
            const LinearProgressIndicator(
              semanticsLabel: 'Carregando seu caderno',
            ),
          if (view.error != null)
            HistoryFailure(error: view.error!, onRetry: controller.retry),
          if (!view.pending && view.error == null && view.items.isEmpty)
            Text(
              view.query.status == ErrorStatus.pending
                  ? 'Nenhum erro pendente neste filtro. Continue praticando.'
                  : 'Nenhuma questão revisada neste filtro.',
            ),
          for (final item in current) _ErrorCard(item: item),
          if (old.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Conteúdo de outra versão',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Estes registros ficam no seu histórico. A revisão usa somente questões da versão atual.',
            ),
            for (final item in old) _ErrorCard(item: item),
          ],
          if (view.nextCursor != null)
            OutlinedButton(
              onPressed: view.pending ? null : controller.nextPage,
              child: const Text('Carregar mais'),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: view.pending ? null : controller.retry,
            child: const Text('Atualizar caderno'),
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
    final entry = ref.watch(learningEntryProvider(item.topicId)).asData?.value;
    final outdated = item.contentStatus == ContentStatus.outdated;
    final q = outdated
        ? null
        : entry?.topic.questions
              .where((q) => q.id == item.questionId)
              .firstOrNull;
    return Card(
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry?.topic.title ?? 'Conteúdo anterior',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (q != null) Text(q.prompt),
            Text(
              '${item.wrongCount} ${item.wrongCount == 1 ? 'erro registrado' : 'erros registrados'} · ${item.status == ErrorStatus.reviewed ? 'Revisado' : 'Pendente'}',
            ),
            const SizedBox(height: 12),
            if (!outdated && q != null)
              FilledButton(
                onPressed: () => context.go(
                  '/meus-erros/${item.topicId}/${item.contentVersion}/${item.questionId}',
                ),
                child: const Text('Revisar questão'),
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
