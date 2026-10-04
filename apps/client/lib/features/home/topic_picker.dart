import 'package:flutter/material.dart';

import '../../design_system/tokens.dart';
import '../learning/study_catalog.dart';

class TopicPicker extends StatelessWidget {
  const TopicPicker({
    super.key,
    required this.topics,
    required this.selectedId,
    required this.onSelected,
  });
  final List<StudyTopic> topics;
  final String selectedId;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final colors = AppColors.of(context);
      final columns = constraints.maxWidth >= 850
          ? 3
          : constraints.maxWidth >= 560 &&
                MediaQuery.textScalerOf(context).scale(16) <= 20
          ? 2
          : 1;
      final width = (constraints.maxWidth - 24 * (columns - 1)) / columns;
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          for (var i = 0; i < topics.length; i++)
            SizedBox(
              width: width,
              child: Semantics(
                selected: topics[i].id == selectedId,
                button: true,
                child: Material(
                  color: topics[i].id == selectedId
                      ? colors.primarySoft
                      : colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    side: BorderSide(
                      color: topics[i].id == selectedId
                          ? colors.primary
                          : colors.border,
                      width: topics[i].id == selectedId ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelected(topics[i].id),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                [
                                  Icons.percent_rounded,
                                  Icons.menu_book_outlined,
                                  Icons.eco_outlined,
                                ][i % 3],
                                size: 32,
                                color: colors.text,
                              ),
                              const Spacer(),
                              if (topics[i].id == selectedId)
                                Icon(
                                  Icons.check_circle_outline,
                                  color: colors.text,
                                  semanticLabel: 'Assunto selecionado',
                                )
                              else
                                Text(
                                  '0${i + 1}',
                                  style: TextStyle(color: colors.muted),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            topics[i].subject,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colors.muted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            topics[i].title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            topics[i].summary,
                            style: TextStyle(color: colors.muted, height: 1.6),
                          ),
                          const SizedBox(height: 24),
                          Divider(color: colors.border),
                          const SizedBox(height: 12),
                          Text(
                            '${topics[i].lessons.length} aulas · desafios de 5 questões',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
