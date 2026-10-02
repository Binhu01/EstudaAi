import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../learning/learning_catalog_providers.dart';
import 'contest_route_scope.dart';
import 'contest_widgets.dart';

class ContestCourseScreen extends ConsumerWidget {
  const ContestCourseScreen({super.key, required this.courseId});
  final String courseId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ContestRouteScope(
    courseId: courseId,
    child: Builder(
      builder: (context) {
        final catalog = ref.watch(contestCatalogProvider).requireValue,
            course = catalog.course;
        final date = course.referenceDate.split('-').reversed.join('/');
        return ContestPage(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/concursos'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Todos os concursos'),
              ),
            ),
            Text(
              course.title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(course.track),
            const SizedBox(height: 12),
            const Text('Preparação'),
            const SizedBox(height: 8),
            Text(
              'Referência histórica: edital 2022/001. Fontes consultadas em $date. Esta trilha não anuncia edital, vagas, banca ou calendário de 2026.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Material autoral, desafios formativos e aulas externas de apoio. A preparação inclui oito disciplinas e oficinas de Redação.',
            ),
            MaterialSection(
              title: 'Disciplinas',
              children: [
                for (final d in catalog.disciplines)
                  Card(
                    child: InkWell(
                      onTap: () => context.go('/concursos/$courseId/${d.id}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(d.summary),
                            const SizedBox(height: 8),
                            Text(
                              '${d.modules.length} módulos · 2 aulas de apoio',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            MaterialSection(
              title: 'Referências da preparação',
              children: [
                StudySourceLinks(
                  sources: [course.syllabusSource, ...course.statusSources],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
