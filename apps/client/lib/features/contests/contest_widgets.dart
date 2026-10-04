import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/tokens.dart';
import '../learning/study_catalog.dart';
import '../learning/external_links.dart';

class ContestPage extends StatelessWidget {
  const ContestPage({super.key, required this.children, this.maxWidth = 1180});
  final List<Widget> children;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 600 ? 20 : 48,
              vertical: constraints.maxWidth < 600 ? 28 : 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

class MaterialSection extends StatelessWidget {
  const MaterialSection({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    ),
  );
}

/// A readable catalog entry, shared by discipline and module lists.
class ContestContentRow extends StatelessWidget {
  const ContestContentRow({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    required this.metadata,
    required this.onTap,
    this.eyebrow,
  });
  final int index;
  final String title, description, metadata;
  final String? eyebrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: 42,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.linkInk,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(description, style: TextStyle(color: colors.muted)),
                    const SizedBox(height: 12),
                    Text(
                      metadata,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(
                child: Icon(
                  Icons.arrow_outward_rounded,
                  size: 22,
                  color: colors.linkInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudyNotice extends StatelessWidget {
  const StudyNotice({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
  });
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 20, color: colors.muted)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }
}

class StudySourceLinks extends ConsumerWidget {
  const StudySourceLinks({super.key, required this.sources});
  final List<StudySource> sources;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final source in sources)
        TextButton.icon(
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(source.title),
          onPressed: () async {
            final opened = await ref.read(externalLinkProvider)(
              Uri.parse(source.url),
            );
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Não foi possível abrir a fonte. Tente novamente.',
                  ),
                ),
              );
            }
          },
        ),
    ],
  );
}

class StudyBullets extends StatelessWidget {
  const StudyBullets(this.items, {super.key});
  final List<String> items;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•  ',
                style: TextStyle(color: AppColors.of(context).primary),
              ),
              Expanded(child: Text(item)),
            ],
          ),
        ),
    ],
  );
}
