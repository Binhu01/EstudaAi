import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../learning/learning_catalog_providers.dart';
import '../learning/learning_entry.dart';
import '../learning/study_routes.dart';
import 'contest_models.dart';

class ContestModuleNavigation extends ConsumerWidget {
  const ContestModuleNavigation({
    super.key,
    required this.entry,
    required this.action,
  });
  final LearningEntry entry;
  final StudyAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = entry.contestLocation!.discipline.modules;
    final index = modules.indexWhere((module) => module.id == entry.topic.id);
    final previous = index > 0 ? modules[index - 1] : null;
    final next = index >= 0 && index + 1 < modules.length
        ? modules[index + 1]
        : null;

    Widget button(ContestModule? module, String label, IconData icon) =>
        OutlinedButton.icon(
          onPressed: module == null
              ? null
              : () => context.go(
                  StudyRoutes.path(
                    ref.read(learningEntryProvider(module.id)).requireValue!,
                    action,
                  ),
                ),
          icon: Icon(icon, size: 20),
          label: Text(label),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 20),
        Text(
          'Módulo ${index + 1} de ${modules.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final previousButton = button(
              previous,
              'Módulo anterior',
              Icons.arrow_back,
            );
            final nextButton = button(
              next,
              'Próximo módulo',
              Icons.arrow_forward,
            );
            if (constraints.maxWidth < 600 ||
                MediaQuery.textScalerOf(context).scale(16) > 24) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  previousButton,
                  const SizedBox(height: 12),
                  nextButton,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: previousButton),
                const SizedBox(width: 16),
                Expanded(child: nextButton),
              ],
            );
          },
        ),
      ],
    );
  }
}
