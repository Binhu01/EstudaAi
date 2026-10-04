import 'package:flutter/material.dart';

import '../tokens.dart';

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    this.eyebrow,
    required this.title,
    this.description,
    this.trailing,
  });
  final String? eyebrow, description;
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final colors = AppColors.of(context);
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            SectionLabel(text: eyebrow!),
            const SizedBox(height: 16),
          ],
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontSize: constraints.maxWidth < 600 ? 32 : 44),
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Text(
                description!,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colors.muted),
              ),
            ),
          ],
        ],
      );
      if (trailing == null) return heading;
      if (constraints.maxWidth < 760 ||
          MediaQuery.textScalerOf(context).scale(16) > 22) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [heading, const SizedBox(height: 24), trailing!],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: heading),
          const SizedBox(width: 24),
          trailing!,
        ],
      );
    },
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.dark.accent
          : AppColors.light.primary,
    ),
  );
}
