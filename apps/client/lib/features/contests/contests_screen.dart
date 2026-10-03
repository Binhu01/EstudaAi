import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../learning/learning_catalog_providers.dart';
import 'contest_route_scope.dart';
import 'contest_widgets.dart';

class ContestsScreen extends ConsumerWidget {
  const ContestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ContestRouteScope(
    courseId: 'bb2026',
    child: Builder(
      builder: (context) {
        final course = ref.watch(contestCatalogProvider).requireValue.course;
        return ContestPage(
          children: [
            Text('Concursos', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text(
              'Escolha sua preparação e estude um módulo de cada vez.',
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/meu-estudo'),
                icon: const Icon(Icons.today_outlined),
                label: const Text('Meu estudo'),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: InkWell(
                onTap: () => context.go('/concursos/${course.id}'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 36),
                      const SizedBox(height: 16),
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(course.track),
                      const SizedBox(height: 12),
                      const Text('Preparação'),
                      const SizedBox(height: 8),
                      const Text(
                        '9 disciplinas · 126 módulos · material autoral',
                      ),
                      const SizedBox(height: 16),
                      const Text('Abrir preparação →'),
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
