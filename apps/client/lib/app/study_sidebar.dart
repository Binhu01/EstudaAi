import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/tokens.dart';
import '../features/learning/learning_entry.dart';

class SidebarDestination {
  const SidebarDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.path,
  });
  final String id, label, path;
  final IconData icon;
}

class StudySidebar extends StatefulWidget {
  const StudySidebar({
    super.key,
    required this.destinations,
    required this.selectedId,
    required this.area,
    required this.onNavigate,
    required this.onSearch,
    required this.onAreaChanged,
  });
  final List<SidebarDestination> destinations;
  final String selectedId;
  final LearningArea area;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSearch;
  final ValueChanged<LearningArea> onAreaChanged;
  @override
  State<StudySidebar> createState() => _StudySidebarState();
}

class _StudySidebarState extends State<StudySidebar> {
  late bool _contestsOpen;
  @override
  void initState() {
    super.initState();
    _contestsOpen = widget.area == LearningArea.contest;
  }

  @override
  void didUpdateWidget(StudySidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.area != oldWidget.area && widget.area == LearningArea.contest) {
      _contestsOpen = true;
    }
  }

  SidebarDestination destination(String id) =>
      widget.destinations.firstWhere((d) => d.id == id);
  Widget item(String id) {
    final d = destination(id);
    return SidebarButton(
      key: ValueKey('nav-$id'),
      label: d.label,
      icon: d.icon,
      selected: widget.selectedId == id,
      onPressed: () => widget.onNavigate(d.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final header = <Widget>[
      _AreaSwitcher(area: widget.area, onChanged: widget.onAreaChanged),
      const SizedBox(height: 16),
      Tooltip(
        message: 'Buscar atalhos',
        child: SidebarButton(
          label: 'Buscar atalhos',
          icon: Icons.search,
          selected: false,
          onPressed: widget.onSearch,
          trailing: ExcludeSemantics(
            child: Text(
              defaultTargetPlatform == TargetPlatform.macOS ? '⌘ K' : 'Ctrl K',
              style: TextStyle(fontSize: 10, color: colors.muted),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
    final navigation = <Widget>[
      const _GroupLabel('Explorar'),
      item('home'),
      item('lessons'),
      item('quiz'),
      item('steve'),
      Row(
        children: [
          Expanded(child: item('contests')),
          IconButton(
            tooltip: _contestsOpen
                ? 'Ocultar preparações'
                : 'Exibir preparações',
            onPressed: () => setState(() => _contestsOpen = !_contestsOpen),
            icon: Icon(
              _contestsOpen ? Icons.keyboard_arrow_down : Icons.chevron_right,
              size: 18,
            ),
          ),
        ],
      ),
      if (_contestsOpen)
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 4, bottom: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: item('bb2026'),
            ),
          ),
        ),
      const SizedBox(height: 20),
      const _GroupLabel('Seu espaço'),
      item('dashboard'),
      item('errors'),
    ];
    final footer = <Widget>[
      const SizedBox(height: 8),
      const Divider(height: 16),
      item('settings'),
      item('account'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keep every destination reachable when zoom or a short window leaves
              // too little room for fixed header and footer sections.
              final scrollAll =
                  constraints.maxHeight <
                  420 + MediaQuery.textScalerOf(context).scale(70);
              if (scrollAll) {
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [...header, ...navigation, ...footer],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...header,
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: navigation,
                    ),
                  ),
                  ...footer,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AreaSwitcher extends StatelessWidget {
  const _AreaSwitcher({required this.area, required this.onChanged});
  final LearningArea area;
  final ValueChanged<LearningArea> onChanged;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PopupMenuButton<LearningArea>(
      tooltip: 'Trocar área de estudo',
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      color: colors.surface,
      itemBuilder: (_) => [
        PopupMenuItem(
          key: const ValueKey('area-free'),
          value: LearningArea.freeStudy,
          child: _AreaOption(
            label: 'Estudo livre',
            selected: area == LearningArea.freeStudy,
            icon: Icons.school_outlined,
          ),
        ),
        PopupMenuItem(
          key: const ValueKey('area-contest'),
          value: LearningArea.contest,
          child: _AreaOption(
            label: 'Concursos',
            selected: area == LearningArea.contest,
            icon: Icons.account_balance_outlined,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                AppIcons.brand,
                color: AppColors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estuda Aí',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    area == LearningArea.contest ? 'Concursos' : 'Estudo livre',
                    style: TextStyle(fontSize: 12, color: colors.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.unfold_more, size: 17, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

class _AreaOption extends StatelessWidget {
  const _AreaOption({
    required this.label,
    required this.selected,
    required this.icon,
  });
  final String label;
  final bool selected;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Text(label)),
      if (selected) const Icon(Icons.check, size: 18),
    ],
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.of(context).muted,
      ),
    ),
  );
}

class SidebarButton extends StatefulWidget {
  const SidebarButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.trailing,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final Widget? trailing;
  @override
  State<SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<SidebarButton> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final foreground = widget.selected ? colors.text : colors.muted;
    return Semantics(
      selected: widget.selected,
      button: true,
      child: Material(
        color: widget.selected
            ? colors.text.withValues(alpha: .07)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: _focused ? colors.linkInk : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onFocusChange: (focused) => setState(() => _focused = focused),
          onTap: widget.onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(widget.icon, color: foreground, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationSearch extends StatefulWidget {
  const NavigationSearch({super.key, required this.destinations});
  final List<SidebarDestination> destinations;
  @override
  State<NavigationSearch> createState() => _NavigationSearchState();
}

class _NavigationSearchState extends State<NavigationSearch> {
  String _query = '';
  String _normalize(String text) {
    var result = text.toLowerCase();
    const accents = {
      'áàâãä': 'a',
      'éèêë': 'e',
      'íìîï': 'i',
      'óòôõö': 'o',
      'úùûü': 'u',
      'ç': 'c',
    };
    for (final entry in accents.entries) {
      for (final letter in entry.key.split('')) {
        result = result.replaceAll(letter, entry.value);
      }
    }
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final results = widget.destinations
        .where((d) => _normalize(d.label).contains(_normalize(_query)))
        .toList();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Dialog(
        backgroundColor: colors.surface,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 540),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('navigation-search'),
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          labelText: 'Buscar atalhos',
                          hintText: 'Para onde você quer ir?',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                        onSubmitted: (_) {
                          if (results.isNotEmpty) {
                            Navigator.of(context).pop(results.first);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Fechar busca',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Nenhum atalho encontrado.',
                      style: TextStyle(color: colors.muted),
                    ),
                  ),
                if (results.isNotEmpty)
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final d in results)
                          SidebarButton(
                            key: ValueKey('search-${d.id}'),
                            label: d.label,
                            icon: d.icon,
                            selected: false,
                            onPressed: () => Navigator.of(context).pop(d),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
