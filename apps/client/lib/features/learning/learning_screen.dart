import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/page_heading.dart';
import '../../design_system/tokens.dart';
import '../contests/contest_module_actions.dart';
import '../contests/contest_module_navigation.dart';
import '../contests/contest_widgets.dart';
import 'study_catalog.dart';
import 'lesson_player.dart';
import 'learning_entry.dart';
import 'learning_entry_view.dart';
import 'study_routes.dart';

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
    final entry = widget.entry;
    final topic = entry.topic;
    final colors = AppColors.of(context);
    return ContestPage(
      children: [
        PageHeading(
          eyebrow: entry.area == LearningArea.contest
              ? 'APOIO À PREPARAÇÃO'
              : 'ESTUDO LIVRE',
          title: 'Aprender',
          description: entry.area == LearningArea.contest
              ? '${entry.courseTitle} · ${topic.subject} · apoio externo à disciplina'
              : 'Estudo livre · uma descoberta de cada vez',
        ),
        const SizedBox(height: 32),
        LearningEntrySelector(entry: entry, action: StudyAction.lessons),
        if (entry.area == LearningArea.contest) ...[
          const SizedBox(height: 20),
          ContestModuleActions(entry: entry, selected: StudyAction.lessons),
          const SizedBox(height: 24),
          const StudyNotice(
            text: 'As aulas são complementares e externas. O material autoral reúne a explicação e a prática específicas deste módulo.',
          ),
        ],
        const SizedBox(height: 48),
        Semantics(
          header: true,
          child: Text(
            topic.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        Text(topic.summary, style: TextStyle(color: colors.muted)),
        const SizedBox(height: 12),
        Text(
          topic.level,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 850 &&
                MediaQuery.textScalerOf(context).scale(16) <= 24;
            final choices = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel(text: 'VIDEOAULAS'),
                const SizedBox(height: 16),
                for (final lesson in topic.lessons)
                  _LessonChoice(
                    lesson: lesson,
                    selected: _selected?.id == lesson.id,
                    onTap: () => setState(() => _selected = lesson),
                  ),
              ],
            );
            final media = _selected == null
                ? _LessonPrompt()
                : _SelectedLesson(lesson: _selected!);
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: choices),
                  const SizedBox(width: 36),
                  Expanded(flex: 5, child: media),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                choices,
                if (_selected != null) ...[const SizedBox(height: 28), media],
              ],
            );
          },
        ),
        MaterialSection(
          title: 'Para aprofundar',
          children: [
            Text(topic.notes),
            const SizedBox(height: 12),
            StudySourceLinks(sources: topic.sources),
          ],
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () =>
                context.go(StudyRoutes.path(entry, StudyAction.steve)),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text('Perguntar ao Steve'),
          ),
        ),
        if (entry.area == LearningArea.contest) ...[
          const SizedBox(height: 32),
          ContestModuleNavigation(entry: entry, action: StudyAction.lessons),
        ],
      ],
    );
  }
}

class _LessonChoice extends StatelessWidget {
  const _LessonChoice({
    required this.lesson,
    required this.selected,
    required this.onTap,
  });
  final StudyLesson lesson;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        selected: selected,
        child: Material(
          color: selected ? colors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      selected
                          ? Icons.check_circle_outline
                          : Icons.play_circle_outline,
                      color: colors.linkInk,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${lesson.channel} · ${lesson.level}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.muted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lesson.description,
                          style: TextStyle(color: colors.muted),
                        ),
                        if (selected) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: colors.linkInk,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aula selecionada',
                                  style: TextStyle(color: colors.linkInk),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.ondemand_video_outlined, size: 40, color: colors.primary),
          const SizedBox(height: 28),
          Text(
            'Escolha sua próxima aula.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'O vídeo aparece aqui quando você seleciona uma aula. Você também pode abri-lo no YouTube.',
            style: TextStyle(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _SelectedLesson extends StatelessWidget {
  const _SelectedLesson({required this.lesson});
  final StudyLesson lesson;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionLabel(text: 'ASSISTA E APROFUNDE'),
      const SizedBox(height: 16),
      LessonPlayer(key: ValueKey(lesson.id), lesson: lesson),
    ],
  );
}
