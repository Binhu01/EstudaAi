import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/page_heading.dart';
import '../../design_system/tokens.dart';
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
        final catalog = ref.watch(contestCatalogProvider).requireValue;
        final course = catalog.course;
        final colors = AppColors.of(context);
        final modules = catalog.disciplines.fold<int>(
          0,
          (total, discipline) => total + discipline.modules.length,
        );
        return ContestPage(
          children: [
            PageHeading(
              eyebrow: 'SUA PRÓXIMA CONQUISTA',
              title: 'Concursos',
              description:
                  'Escolha sua preparação e estude um módulo de cada vez.',
              trailing: OutlinedButton.icon(
                onPressed: () => context.go('/meu-estudo'),
                icon: const Icon(Icons.today_outlined),
                label: const Text('Meu estudo'),
              ),
            ),
            const SizedBox(height: 48),
            const SectionLabel(text: 'PREPARAÇÕES DISPONÍVEIS'),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/concursos/${course.id}'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 28,
                            color: colors.accentText,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Preparação',
                            style: TextStyle(color: colors.accentText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        course.track,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${catalog.disciplines.length} disciplinas · $modules módulos · material autoral',
                        style: TextStyle(color: colors.muted),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Abrir preparação →',
                            style: TextStyle(
                              color: colors.linkInk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
