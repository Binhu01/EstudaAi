import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens.dart';
import '../../design_system/components/page_heading.dart';
import '../../design_system/components/study_card.dart';
import '../../design_system/components/feedback.dart';
import 'settings_controller.dart';
import '../learning/reading_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider),
        colors = AppColors.of(context);
    Future<void> update({ThemeMode? theme, bool? animate}) async {
      try {
        await ref
            .read(settingsProvider.notifier)
            .update(theme: theme, animate: animate);
      } catch (_) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            'Não foi possível salvar a preferência. Tente novamente.',
          );
        }
      }
    }

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 20 : 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeading(
                  eyebrow: 'DO SEU JEITO',
                  title: 'Preferências',
                  description:
                      'Um ambiente confortável para você se concentrar.',
                ),
                const SizedBox(height: 32),
                StudyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: colors.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aparência',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escolha um tema ou acompanhe a configuração do seu dispositivo.',
                        style: TextStyle(color: colors.muted),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final largeText =
                              MediaQuery.textScalerOf(context).scale(16) > 22;
                          final wide =
                              constraints.maxWidth >= 540 && !largeText;
                          final options = [
                            for (final option in const [
                              (
                                ThemeMode.system,
                                'Sistema',
                                Icons.brightness_auto_outlined,
                              ),
                              (
                                ThemeMode.light,
                                'Claro',
                                Icons.light_mode_outlined,
                              ),
                              (
                                ThemeMode.dark,
                                'Escuro',
                                Icons.dark_mode_outlined,
                              ),
                            ])
                              _ThemeOption(
                                label: option.$2,
                                icon: option.$3,
                                mode: option.$1,
                                compact: !wide && !largeText,
                                selected: settings.theme == option.$1,
                                onSelected: () => update(theme: option.$1),
                              ),
                          ];
                          return !largeText
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < options.length;
                                      i++
                                    ) ...[
                                      if (i != 0) const SizedBox(width: 16),
                                      Expanded(child: options[i]),
                                    ],
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < options.length;
                                      i++
                                    ) ...[
                                      if (i != 0) const SizedBox(height: 12),
                                      options[i],
                                    ],
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                StudyCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.all(24),
                    title: const Text('Animação do hero'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Pensamentos em movimento no cérebro da tela inicial. Desative para deixar o desenho estático.',
                        style: TextStyle(color: colors.muted),
                      ),
                    ),
                    value: settings.animate,
                    onChanged: (value) => update(animate: value),
                  ),
                ),
                const SizedBox(height: 24),
                StudyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Leitura',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajuste o texto dos materiais dos módulos.',
                        style: TextStyle(color: colors.muted),
                      ),
                      const SizedBox(height: 24),
                      const ReadingControls(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        color: colors.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Um espaço para cada meta',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Os conteúdos, cronogramas e resultados de cada objetivo ficam no seu próprio contexto de estudo.',
                              style: TextStyle(color: colors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.go('/componentes'),
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text('Galeria de componentes'),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  'Estuda Aí · 0.1.0',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.mode,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final bool selected, compact;
  final VoidCallback onSelected;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    final preview = dark ? const Color(0xFF111114) : const Color(0xFFF6F6F8),
        ink = dark ? Colors.white : const Color(0xFF121214);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primarySoft : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? colors.primary : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 12)
                : const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!compact)
                  ExcludeSemantics(
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: preview,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            decoration: BoxDecoration(
                              color: ink.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 5,
                                  color: ink.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 7),
                                Container(
                                  height: 4,
                                  color: ink.withValues(alpha: 0.18),
                                ),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 36,
                                    height: 9,
                                    color: const Color(0xFF8052FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (compact) ...[
                  Row(
                    children: [
                      Icon(icon, size: 18, color: colors.muted),
                      const Spacer(),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: colors.primary,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                ] else
                  Row(
                    children: [
                      Icon(icon, size: 18, color: colors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: colors.primary,
                          size: 18,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
