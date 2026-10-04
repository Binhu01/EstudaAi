import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/components/feedback.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_repository.dart';

/// Preferences apply only to reading prose, alongside device text scaling.
class ReadingBody extends ConsumerWidget {
  const ReadingBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final factor = switch (settings.readingTextSize) {
      ReadingTextSize.standard => 1.0,
      ReadingTextSize.large => 1.125,
      ReadingTextSize.extraLarge => 1.25,
    };
    TextStyle? adjust(TextStyle? style) => style?.copyWith(
      fontSize: (style.fontSize ?? 14) * factor,
      height:
          (style.height ?? 1.6) +
          (settings.readingComfortableSpacing ? 0.25 : 0),
    );
    final readingTheme = theme.textTheme.copyWith(
      bodyLarge: adjust(theme.textTheme.bodyLarge),
      bodyMedium: adjust(theme.textTheme.bodyMedium),
      bodySmall: adjust(theme.textTheme.bodySmall),
    );
    return Theme(
      data: theme.copyWith(textTheme: readingTheme),
      child: DefaultTextStyle.merge(
        style: readingTheme.bodyMedium,
        child: child,
      ),
    );
  }
}

class ReadingControls extends ConsumerWidget {
  const ReadingControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    Future<void> update({
      ReadingTextSize? size,
      bool? comfortableSpacing,
    }) async {
      try {
        await ref
            .read(settingsProvider.notifier)
            .update(
              readingTextSize: size,
              readingComfortableSpacing: comfortableSpacing,
            );
      } catch (_) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            'Não foi possível salvar a preferência. Tente novamente.',
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tamanho do texto', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final option in const [
              (ReadingTextSize.standard, 'Padrão'),
              (ReadingTextSize.large, 'Maior'),
              (ReadingTextSize.extraLarge, 'Extra'),
            ])
              ChoiceChip(
                label: Text(option.$2),
                selected: settings.readingTextSize == option.$1,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (selected) {
                  if (selected) update(size: option.$1);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mais espaço entre linhas'),
          value: settings.readingComfortableSpacing,
          onChanged: (value) => update(comfortableSpacing: value),
        ),
      ],
    );
  }
}
