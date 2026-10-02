import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'learning_catalog_providers.dart';
import 'learning_controller.dart';
import 'learning_entry.dart';
import 'study_routes.dart';
import 'topic_scope.dart';
import 'topic_not_found.dart';

class LearningEntryView extends ConsumerWidget {
  const LearningEntryView({
    super.key,
    required this.topicId,
    required this.area,
    required this.builder,
  });
  final String topicId;
  final LearningArea area;
  final Widget Function(LearningEntry) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A free route never loads or accepts a contest module.
    if ((topicId.startsWith('bb2026-')) != (area == LearningArea.contest)) {
      return area == LearningArea.contest
          ? const ContestRecovery()
          : const TopicNotFound();
    }
    return ref
        .watch(learningEntryProvider(topicId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, stack) => CatalogRecovery(
            onRetry: () => ref.invalidate(
              area == LearningArea.contest
                  ? contestCatalogProvider
                  : catalogProvider,
            ),
          ),
          data: (entry) {
            if (entry == null || entry.area != area) {
              return area == LearningArea.contest
                  ? const ContestRecovery()
                  : const TopicNotFound();
            }
            return TopicScope(topicId: topicId, child: builder(entry));
          },
        );
  }
}

class LearningEntrySelector extends ConsumerWidget {
  const LearningEntrySelector({
    super.key,
    required this.entry,
    required this.action,
  });
  final LearningEntry entry;
  final StudyAction action;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = entry.area == LearningArea.contest
        ? entry.contestLocation!.discipline.modules
              .map((m) => ref.read(learningEntryProvider(m.id)).requireValue!)
              .toList()
        : ref
              .watch(catalogProvider)
              .requireValue
              .topics
              .map((t) => LearningEntry.fromFree(t, entry.contentVersion))
              .toList();
    return DropdownButtonFormField<String>(
      key: ValueKey('${entry.area}-${entry.topic.id}-${action.name}'),
      initialValue: entry.topic.id,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(
        labelText: entry.area == LearningArea.contest ? 'Módulo' : 'Assunto',
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final e in entries)
          DropdownMenuItem(value: e.topic.id, child: Text(e.topic.title)),
      ],
      onChanged: (id) {
        if (id != null) {
          context.go(
            StudyRoutes.path(
              entries.firstWhere((e) => e.topic.id == id),
              action,
            ),
          );
        }
      },
    );
  }
}

class CatalogRecovery extends StatelessWidget {
  const CatalogRecovery({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Não foi possível carregar os conteúdos.'),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}

class ContestRecovery extends StatelessWidget {
  const ContestRecovery({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48),
          const SizedBox(height: 16),
          const Text('Conteúdo de concurso não encontrado'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/concursos'),
            child: const Text('Voltar a Concursos'),
          ),
        ],
      ),
    ),
  );
}

class LearningAreaScope extends ConsumerStatefulWidget {
  const LearningAreaScope({super.key, required this.area, required this.child});
  final LearningArea area;
  final Widget child;
  @override
  ConsumerState<LearningAreaScope> createState() => _LearningAreaScopeState();
}

class _LearningAreaScopeState extends ConsumerState<LearningAreaScope> {
  void sync() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) ref.read(learningProvider.notifier).enterArea(widget.area);
  });
  @override
  void initState() {
    super.initState();
    sync();
  }

  @override
  void didUpdateWidget(LearningAreaScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area != widget.area) sync();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
