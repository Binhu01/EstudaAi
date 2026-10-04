import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/page_heading.dart';
import '../../design_system/tokens.dart';
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
        final catalog = ref.watch(contestCatalogProvider).requireValue;
        final course = catalog.course;
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
            const SizedBox(height: 24),
            PageHeading(
              eyebrow: 'TRILHA DE CONCURSO',
              title: course.title,
              description: course.track,
            ),
            const SizedBox(height: 24),
            Text(
              'Preparação',
              style: TextStyle(
                color: AppColors.of(context).accentText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            StudyNotice(
              text:
                  'Referência histórica: edital 2022/001. Fontes consultadas em $date. Esta trilha não anuncia edital, vagas, banca ou calendário de 2026.',
            ),
            const SizedBox(height: 18),
            const Text(
              'Material autoral, desafios formativos e aulas externas de apoio. A preparação inclui oito disciplinas e oficinas de Redação.',
            ),
            MaterialSection(
              title: 'Disciplinas',
              children: [
                for (var i = 0; i < catalog.disciplines.length; i++)
                  ContestContentRow(
                    index: i + 1,
                    title: catalog.disciplines[i].title,
                    description: catalog.disciplines[i].summary,
                    metadata:
                        '${catalog.disciplines[i].modules.length} módulos · ${catalog.disciplines[i].lessons.length} aulas de apoio',
                    onTap: () => context.go(
                      '/concursos/$courseId/${catalog.disciplines[i].id}',
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
