import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens.dart';
import 'study_catalog.dart';
import 'learning_controller.dart';
import 'topic_scope.dart';
import 'topic_not_found.dart';
import 'lesson_player.dart';
import 'external_links.dart';
import 'learning_entry.dart';
import 'learning_entry_view.dart';
import 'study_routes.dart';
import '../contests/contest_module_actions.dart';

class StudyTopicView extends ConsumerWidget {
  const StudyTopicView({
    super.key,
    required this.topicId,
    required this.builder,
  });
  final String topicId;
  final Widget Function(LearningCatalog, StudyTopic) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(catalogProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível carregar os assuntos.'),
              TextButton(
                onPressed: () => ref.invalidate(catalogProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (catalog) {
          final topic = catalog.find(topicId);
          if (topic == null) return const TopicNotFound();
          return TopicScope(topicId: topicId, child: builder(catalog, topic));
        },
      );
}

class TopicSelector extends StatelessWidget {
  const TopicSelector({
    super.key,
    required this.catalog,
    required this.topicId,
    required this.routePrefix,
  });
  final LearningCatalog catalog;
  final String topicId, routePrefix;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: DropdownButtonFormField<String>(
      initialValue: topicId,
      isExpanded: true,
      itemHeight: null,
      decoration: const InputDecoration(
        labelText: 'Assunto',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final t in catalog.topics)
          DropdownMenuItem(
            value: t.id,
            child: Text(t.title, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) {
        if (id != null) context.go('$routePrefix/$id');
      },
    ),
  );
}

class LearningScreen extends StatelessWidget {
  const LearningScreen({
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
    builder: (entry) => _Lessons(key: ValueKey(entry.topic.id), entry: entry),
  );
}

class _Lessons extends ConsumerStatefulWidget {
  const _Lessons({super.key, required this.entry});
  final LearningEntry entry;
  @override
  ConsumerState<_Lessons> createState() => _LessonsState();
}

class _LessonsState extends ConsumerState<_Lessons> {
  StudyLesson? _selected;
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry,
        topic = entry.topic,
        colors = AppColors.of(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Aprender',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  entry.area == LearningArea.contest
                      ? '${entry.courseTitle} · ${topic.subject} · apoio externo à disciplina'
                      : 'Estudo livre · uma descoberta de cada vez',
                ),
                const SizedBox(height: 24),
                LearningEntrySelector(
                  entry: entry,
                  action: StudyAction.lessons,
                ),
                if (entry.area == LearningArea.contest) ...[
                  const SizedBox(height: 20),
                  ContestModuleActions(
                    entry: entry,
                    selected: StudyAction.lessons,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'As aulas são complementares e externas. O material autoral reúne a explicação e a prática específicas deste módulo.',
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  topic.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(topic.summary),
                const SizedBox(height: 8),
                Text(topic.level, style: TextStyle(color: colors.muted)),
                const SizedBox(height: 24),
                for (final lesson in topic.lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: _selected?.id == lesson.id
                          ? colors.primarySoft
                          : colors.surface,
                      child: InkWell(
                        onTap: () => setState(() => _selected = lesson),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                children: [
                                  Icon(
                                    Icons.play_circle_outline,
                                    color: colors.primary,
                                  ),
                                  Text(
                                    lesson.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${lesson.channel} · ${lesson.level}'),
                              const SizedBox(height: 8),
                              Text(lesson.description),
                              if (_selected?.id == lesson.id)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text('Aula selecionada'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_selected != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: LessonPlayer(
                      key: ValueKey(_selected!.id),
                      lesson: _selected!,
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Para aprofundar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(topic.notes),
                for (final source in topic.sources)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: Text(source.title),
                      onPressed: () async {
                        final opened = await ref.read(externalLinkProvider)(
                          Uri.parse(source.url),
                        );
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Não foi possível abrir a fonte. Tente novamente.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      context.go(StudyRoutes.path(entry, StudyAction.steve)),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Perguntar ao Steve'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
