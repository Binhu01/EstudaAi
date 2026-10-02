import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learning/study_catalog.dart';
import '../learning/external_links.dart';

class ContestPage extends StatelessWidget {
  const ContestPage({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
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
    padding: const EdgeInsets.only(top: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
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
          icon: const Icon(Icons.open_in_new),
          label: Text(source.title),
          onPressed: () async {
            final opened = await ref.read(externalLinkProvider)(
              Uri.parse(source.url),
            );
            if (!opened && context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Não foi possível abrir a fonte. Tente novamente.',
                  ),
                ),
              );
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
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(item)),
            ],
          ),
        ),
    ],
  );
}
