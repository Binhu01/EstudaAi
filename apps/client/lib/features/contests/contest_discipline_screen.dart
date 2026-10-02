import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        final d = ref
            .watch(contestCatalogProvider)
            .requireValue
            .findDiscipline(disciplineId)!;
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
            Text(d.title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(d.summary),
            const SizedBox(height: 12),
            Text('${d.modules.length} módulos · escolha por onde começar'),
            const SizedBox(height: 20),
            for (final m in d.modules)
              Card(
                child: InkWell(
                  onTap: () => context.go(
                    '/concursos/$courseId/$disciplineId/${m.id}/material',
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.researchId,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(m.summary),
                        const SizedBox(height: 8),
                        const Text('Material · Aulas · Desafio · Steve'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
