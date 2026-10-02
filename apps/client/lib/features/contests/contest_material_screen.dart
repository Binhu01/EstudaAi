import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../learning/learning_entry_view.dart';
import '../learning/learning_entry.dart';
import '../learning/study_routes.dart';
import 'contest_module_actions.dart';
import 'contest_widgets.dart';
import 'material_blocks.dart';

class ContestMaterialScreen extends StatelessWidget {
  const ContestMaterialScreen({super.key, required this.topicId});
  final String topicId;
  @override
  Widget build(BuildContext context) => LearningEntryView(
    topicId: topicId,
    area: LearningArea.contest,
    builder: (entry) {
      final m = entry.contestLocation!.module;
      return ContestPage(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.go(
                '/concursos/${entry.courseId}/${entry.disciplineId}',
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar à disciplina'),
            ),
          ),
          Text(
            '${entry.courseTitle} · ${entry.topic.subject}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Text(m.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Material autoral · Estuda Aí'),
          const SizedBox(height: 8),
          Text(m.level),
          const SizedBox(height: 20),
          LearningEntrySelector(entry: entry, action: StudyAction.material),
          const SizedBox(height: 20),
          ContestModuleActions(entry: entry, selected: StudyAction.material),
          MaterialSection(
            title: 'Objetivos deste módulo',
            children: [StudyBullets(m.objectives)],
          ),
          if (m.prerequisites.isNotEmpty)
            MaterialSection(
              title: 'Antes de começar',
              children: [StudyBullets(m.prerequisites)],
            ),
          MaterialBlocks(blocks: m.blocks),
          MaterialSection(
            title: 'Atenção aos erros frequentes',
            children: [StudyBullets(m.pitfalls)],
          ),
          MaterialSection(
            title: 'Revisão rápida',
            children: [StudyBullets(m.recap)],
          ),
          MaterialSection(
            title: 'Recupere sem consultar',
            children: [StudyBullets(m.retrieval)],
          ),
          for (final task in m.writingTasks)
            MaterialSection(
              title: task.title,
              children: [
                Text(task.prompt),
                const SizedBox(height: 12),
                Text(task.motivatingText),
                const SizedBox(height: 12),
                const Text(
                  'Planeje sua resposta',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                StudyBullets(task.planning),
                const Text(
                  'Revise seu texto',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                StudyBullets(task.selfReview),
                const Text(
                  'Escreva no seu caderno ou editor. Esta atividade é formativa, sem nota oficial.',
                ),
              ],
            ),
          MaterialSection(
            title: 'Fontes de consulta',
            children: [
              Text(
                'Material revisado em ${m.updatedAt.split('-').reversed.join('/')}. Referência histórica; confira as fontes para regras e versões atuais.',
              ),
              StudySourceLinks(sources: m.sources),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () =>
                context.go(StudyRoutes.path(entry, StudyAction.quiz)),
            icon: const Icon(Icons.sports_esports_outlined),
            label: const Text('Praticar este módulo'),
          ),
        ],
      );
    },
  );
}
