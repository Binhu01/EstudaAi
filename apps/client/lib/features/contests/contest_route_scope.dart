import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learning/learning_catalog_providers.dart';
import '../learning/learning_entry_view.dart';
import '../learning/learning_entry.dart';

class ContestRouteScope extends ConsumerWidget {
  const ContestRouteScope({
    super.key,
    required this.courseId,
    this.disciplineId,
    this.topicId,
    required this.child,
  });
  final String courseId;
  final String? disciplineId, topicId;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(contestCatalogProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, stack) => CatalogRecovery(
          onRetry: () => ref.invalidate(contestCatalogProvider),
        ),
        data: (catalog) {
          final discipline = disciplineId == null
              ? null
              : catalog.findDiscipline(disciplineId!);
          final location = topicId == null ? null : catalog.find(topicId!);
          if (courseId != catalog.course.id ||
              (disciplineId != null && discipline == null) ||
              (topicId != null &&
                  (disciplineId == null ||
                      location == null ||
                      location.discipline.id != disciplineId)))
            return const ContestRecovery();
          return topicId == null
              ? LearningAreaScope(area: LearningArea.contest, child: child)
              : child;
        },
      );
}
