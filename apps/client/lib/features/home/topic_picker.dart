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
      final width = constraints.maxWidth >= 800
          ? (constraints.maxWidth - 32) / 3
          : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
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
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: topics[i].id == selectedId
                          ? colors.primary
                          : colors.border,
                      width: topics[i].id == selectedId ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelected(topics[i].id),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Icon(
                                [
                                  Icons.percent_rounded,
                                  Icons.menu_book_rounded,
                                  Icons.eco_outlined,
                                ][i % 3],
                                color: colors.primary,
                              ),
                              Text(
                                topics[i].subject,
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (topics[i].id == selectedId)
                                const Icon(
                                  Icons.check_circle_outline,
                                  semanticLabel: 'Assunto selecionado',
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            topics[i].title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(topics[i].summary),
                          const SizedBox(height: 20),
                          Text(
                            '2 aulas · desafios de 5 questões',
                            style: TextStyle(color: colors.muted, fontSize: 13),
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
