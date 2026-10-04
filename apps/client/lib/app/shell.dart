import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/tokens.dart';
import '../features/learning/learning_controller.dart';
import '../features/learning/learning_catalog_providers.dart';
import '../features/learning/learning_entry.dart';
import '../features/learning/study_routes.dart';
import 'study_sidebar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarOpen = true;
  bool _searchOpen = false;

  String get _selected => switch (widget.location) {
    final p when p.startsWith('/meus-erros') => 'errors',
    '/meu-estudo' => 'dashboard',
    '/preferencias' => 'settings',
    '/conta' => 'account',
    final p when p.endsWith('/steve') || p.startsWith('/steve/') => 'steve',
    final p when p.endsWith('/desafio') || p.startsWith('/desafios/') => 'quiz',
    final p
        when p.endsWith('/aulas') ||
            p.endsWith('/material') ||
            p.startsWith('/aprender/') =>
      'lessons',
    final p when p.startsWith('/concursos/bb2026') => 'bb2026',
    final p when p.startsWith('/concursos') => 'contests',
    _ => 'home',
  };

  void _navigate(String path) {
    _scaffoldKey.currentState?.closeDrawer();
    context.go(path);
  }

  Future<void> _search(List<SidebarDestination> destinations) async {
    if (_searchOpen) return;
    _searchOpen = true;
    _scaffoldKey.currentState?.closeDrawer();
    try {
      final destination = await showDialog<SidebarDestination>(
        context: context,
        builder: (_) => NavigationSearch(destinations: destinations),
      );
      if (mounted && destination != null) {
        final action = switch (destination.id) {
          'lessons' => StudyAction.lessons,
          'quiz' => StudyAction.quiz,
          'steve' => StudyAction.steve,
          _ => null,
        };
        if (action == null) {
          _navigate(destination.path);
        } else {
          // Resolve the current module after closing the dialog: the catalog or
          // route scope may have finished loading while the search was open.
          final selection = ref.read(learningProvider);
          final entry = ref
              .read(learningEntryProvider(selection.topicId))
              .asData
              ?.value;
          _navigate(
            entry == null
                ? (selection.area == LearningArea.contest ? '/concursos' : '/')
                : StudyRoutes.path(entry, action),
          );
        }
      }
    } finally {
      _searchOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(learningProvider);
    final entry = ref
        .watch(learningEntryProvider(selection.topicId))
        .asData
        ?.value;
    String studyPath(StudyAction action) => entry == null
        ? (selection.area == LearningArea.contest ? '/concursos' : '/')
        : StudyRoutes.path(entry, action);
    final destinations = [
      const SidebarDestination(
        id: 'home',
        label: 'Início',
        icon: AppIcons.home,
        path: '/',
      ),
      SidebarDestination(
        id: 'lessons',
        label: 'Aprender',
        icon: AppIcons.video,
        path: studyPath(StudyAction.lessons),
      ),
      SidebarDestination(
        id: 'quiz',
        label: 'Desafios',
        icon: AppIcons.questions,
        path: studyPath(StudyAction.quiz),
      ),
      SidebarDestination(
        id: 'steve',
        label: 'Steve',
        icon: Icons.chat_bubble_outline,
        path: studyPath(StudyAction.steve),
      ),
      const SidebarDestination(
        id: 'contests',
        label: 'Concursos',
        icon: Icons.account_balance_outlined,
        path: '/concursos',
      ),
      const SidebarDestination(
        id: 'bb2026',
        label: 'Banco do Brasil 2026',
        icon: Icons.menu_book_outlined,
        path: '/concursos/bb2026',
      ),
      const SidebarDestination(
        id: 'dashboard',
        label: 'Meu estudo',
        icon: Icons.today_outlined,
        path: '/meu-estudo',
      ),
      const SidebarDestination(
        id: 'errors',
        label: 'Caderno de erros',
        icon: Icons.history_edu_outlined,
        path: '/meus-erros',
      ),
      const SidebarDestination(
        id: 'settings',
        label: 'Preferências',
        icon: AppIcons.settings,
        path: '/preferencias',
      ),
      const SidebarDestination(
        id: 'account',
        label: 'Conta',
        icon: Icons.account_circle_outlined,
        path: '/conta',
      ),
    ];
    final active = destinations.firstWhere((d) => d.id == _selected);
    final colors = AppColors.of(context);
    final areaLabel = selection.area == LearningArea.contest
        ? 'Concursos'
        : 'Estudo livre';

    Widget sidebar() => StudySidebar(
      key: const ValueKey('study-sidebar'),
      destinations: destinations,
      selectedId: _selected,
      area: selection.area,
      onNavigate: _navigate,
      onSearch: () => _search(destinations),
      onAreaChanged: (area) =>
          _navigate(area == LearningArea.contest ? '/concursos' : '/'),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _search(destinations),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _search(destinations),
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1024;
          final mobile = constraints.maxWidth < 600;
          final bottomIndex = [
            'home',
            'lessons',
            'quiz',
            'steve',
            'contests',
          ].indexOf(_selected == 'bb2026' ? 'contests' : _selected);
          final toolbar = DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: SafeArea(
              bottom: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: desktop
                            ? (_sidebarOpen
                                  ? 'Recolher menu lateral'
                                  : 'Expandir menu lateral')
                            : 'Abrir menu de navegação',
                        onPressed: desktop
                            ? () => setState(() => _sidebarOpen = !_sidebarOpen)
                            : () => _scaffoldKey.currentState?.openDrawer(),
                        icon: Icon(
                          desktop && _sidebarOpen
                              ? Icons.menu_open
                              : Icons.menu,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mobile
                              ? active.label
                              : '$areaLabel  /  ${active.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!desktop || !_sidebarOpen)
                        IconButton(
                          tooltip: 'Buscar atalhos',
                          onPressed: () => _search(destinations),
                          icon: const Icon(Icons.search, size: 20),
                        ),
                      if (mobile)
                        IconButton(
                          tooltip: 'Preferências',
                          onPressed: () => _navigate('/preferencias'),
                          icon: const Icon(AppIcons.settings, size: 20),
                        ),
                      IconButton(
                        tooltip: 'Conta',
                        onPressed: () => _navigate('/conta'),
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          return Scaffold(
            key: _scaffoldKey,
            drawer: desktop
                ? null
                : Drawer(
                    width: 280,
                    backgroundColor: colors.surface,
                    shape: const RoundedRectangleBorder(),
                    child: sidebar(),
                  ),
            body: Row(
              children: [
                if (desktop && _sidebarOpen)
                  SizedBox(width: 260, child: sidebar()),
                Expanded(
                  child: Column(
                    children: [
                      toolbar,
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: mobile && bottomIndex >= 0
                ? NavigationBar(
                    selectedIndex: bottomIndex < 0 ? 0 : bottomIndex,
                    height: MediaQuery.textScalerOf(context)
                        .scale(80)
                        .clamp(80, 140),
                    onDestinationSelected: (index) =>
                        _navigate(destinations[index].path),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(AppIcons.home),
                        label: 'Início',
                      ),
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
                  )
                : null,
          );
        },
      ),
    );
  }
}
