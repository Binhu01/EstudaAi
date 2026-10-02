import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/learning/learning_controller.dart';
import '../features/learning/learning_catalog_providers.dart';
import '../features/learning/learning_entry.dart';
import '../features/learning/study_routes.dart';

import '../design_system/tokens.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = location.startsWith('/preferencias')
        ? 5
        : location.startsWith('/concursos')
        ? (location.endsWith('/steve')
              ? 3
              : location.endsWith('/desafio')
              ? 2
              : location.endsWith('/aulas') || location.endsWith('/material')
              ? 1
              : 4)
        : location.startsWith('/steve')
        ? 3
        : location.startsWith('/desafios')
        ? 2
        : location.startsWith('/aprender')
        ? 1
        : 0;
    final selection = ref.watch(learningProvider);
    final entry = ref
        .watch(learningEntryProvider(selection.topicId))
        .asData
        ?.value;
    void navigate(int index) {
      if (index == 0) {
        context.go('/');
        return;
      }
      if (index == 4) {
        context.go('/concursos');
        return;
      }
      if (index == 5) {
        context.go('/preferencias');
        return;
      }
      if (entry == null) {
        context.go(selection.area == LearningArea.contest ? '/concursos' : '/');
        return;
      }
      context.go(
        StudyRoutes.path(
          entry,
          [StudyAction.lessons, StudyAction.quiz, StudyAction.steve][index - 1],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 232,
                  child: ColoredBox(
                    color: AppColors.of(context).sidebar,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Brand(light: true),
                            const SizedBox(height: AppSpacing.section),
                            NavigationItem(
                              label: 'Início',
                              icon: AppIcons.home,
                              selected: selected == 0,
                              onPressed: () => navigate(0),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            NavigationItem(
                              label: 'Aprender',
                              icon: AppIcons.video,
                              selected: selected == 1,
                              onPressed: () => navigate(1),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            NavigationItem(
                              label: 'Desafios',
                              icon: AppIcons.questions,
                              selected: selected == 2,
                              onPressed: () => navigate(2),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            NavigationItem(
                              label: 'Steve',
                              icon: Icons.chat_bubble_outline,
                              selected: selected == 3,
                              onPressed: () => navigate(3),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            NavigationItem(
                              label: 'Concursos',
                              icon: Icons.account_balance_outlined,
                              selected: selected == 4,
                              onPressed: () => navigate(4),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            NavigationItem(
                              label: 'Preferências',
                              icon: AppIcons.settings,
                              selected: selected == 5,
                              onPressed: () => navigate(5),
                            ),
                            const Spacer(),
                            NavigationItem(
                              label: 'Conta',
                              icon: Icons.account_circle_outlined,
                              selected: location == '/conta',
                              onPressed: () => context.go('/conta'),
                            ),
                            const Divider(color: AppColors.white),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Seu ritmo.\nSeu próximo passo.',
                              style: TextStyle(
                                color: AppColors.white,
                                height: 1.6,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          );
        }
        if (constraints.maxWidth >= 600) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: selected,
                    onDestinationSelected: navigate,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Icon(AppIcons.brand, size: 28),
                    ),
                    labelType: NavigationRailLabelType.all,
                    trailing: IconButton(
                      tooltip: 'Conta',
                      onPressed: () => context.go('/conta'),
                      icon: const Icon(Icons.account_circle_outlined),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(AppIcons.home),
                        label: Text('Início'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(AppIcons.video),
                        label: Text('Aprender'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(AppIcons.questions),
                        label: Text('Desafios'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.chat_bubble_outline),
                        label: Text('Steve'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.account_balance_outlined),
                        label: Text('Concursos'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(AppIcons.settings),
                        label: Text('Preferências'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Brand(),
            actions: [
              IconButton(
                tooltip: 'Preferências',
                onPressed: () => context.go('/preferencias'),
                icon: const Icon(AppIcons.settings),
              ),
              IconButton(
                tooltip: 'Conta',
                onPressed: () => context.go('/conta'),
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ],
          ),
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selected >= 5 ? 0 : selected,
            height: MediaQuery.textScalerOf(context).scale(80).clamp(80, 140),
            onDestinationSelected: navigate,
            destinations: const [
              NavigationDestination(icon: Icon(AppIcons.home), label: 'Início'),
              NavigationDestination(
                icon: Icon(AppIcons.video),
                label: 'Aprender',
              ),
              NavigationDestination(
                icon: Icon(AppIcons.questions),
                label: 'Desafios',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Steve',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_outlined),
                label: 'Concursos',
              ),
            ],
          ),
        );
      },
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        AppIcons.brand,
        color: light ? AppColors.white : AppColors.of(context).primary,
        size: 27,
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          'Estuda Aí',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: light ? AppColors.white : AppColors.of(context).text,
          ),
        ),
      ),
    ],
  );
}

class NavigationItem extends StatelessWidget {
  const NavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Material(
      color: selected
          ? AppColors.white.withValues(alpha: 0.16)
          : AppColors.white.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
