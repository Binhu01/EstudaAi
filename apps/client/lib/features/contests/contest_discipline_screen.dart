import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/page_heading.dart';
import '../../design_system/tokens.dart';
import '../learning/learning_catalog_providers.dart';
import 'contest_route_scope.dart';
import 'contest_widgets.dart';

class ContestDisciplineScreen extends ConsumerWidget {
  const ContestDisciplineScreen({
    super.key,
    required this.courseId,
    required this.disciplineId,
  });
  final String courseId, disciplineId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ContestRouteScope(
    courseId: courseId,
    disciplineId: disciplineId,
    child: Builder(
      builder: (context) {
        final catalog = ref.watch(contestCatalogProvider).requireValue;
        final discipline = catalog.findDiscipline(disciplineId)!;
        return ContestPage(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/concursos/$courseId'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar ao concurso'),
              ),
            ),
            const SizedBox(height: 24),
            PageHeading(
              eyebrow: catalog.course.title,
              title: discipline.title,
              description: discipline.summary,
            ),
            const SizedBox(height: 24),
            Text(
              '${discipline.modules.length} módulos · escolha por onde começar',
              style: TextStyle(color: AppColors.of(context).muted),
            ),
            const SizedBox(height: 36),
            const SectionLabel(text: 'SEU PERCURSO DE ESTUDO'),
            const SizedBox(height: 12),
            for (var i = 0; i < discipline.modules.length; i++)
              ContestContentRow(
                index: i + 1,
                eyebrow: discipline.modules[i].researchId,
                title: discipline.modules[i].title,
                description: discipline.modules[i].summary,
                metadata: 'Material · Aulas · Desafio · Steve',
                onTap: () => context.go(
                  '/concursos/$courseId/$disciplineId/${discipline.modules[i].id}/material',
                ),
              ),
          ],
        );
      },
    ),
  );
}
