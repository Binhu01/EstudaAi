import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final selected = location == '/' ? 0 : 1;
    void navigate(int index) => context.go(index == 0 ? '/' : '/preferencias');
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
                              label: 'Preferências',
                              icon: AppIcons.settings,
                              selected: selected == 1,
                              onPressed: () => navigate(1),
                            ),
                            const Spacer(),
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
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(AppIcons.home),
                        label: Text('Início'),
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
          appBar: AppBar(title: const Brand()),
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: navigate,
            destinations: const [
              NavigationDestination(icon: Icon(AppIcons.home), label: 'Início'),
              NavigationDestination(
                icon: Icon(AppIcons.settings),
                label: 'Preferências',
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
