import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../design_system/theme.dart';
import '../features/home/home_screen.dart';
import '../features/learning/learning_screen.dart';
import '../features/quiz/quiz_screen.dart';
import '../features/auth/account_screen.dart';
import '../features/steve/steve_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/settings_controller.dart';
import '../design_system/gallery.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/conta',
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: '/steve/:topicId',
            builder: (context, state) =>
                SteveScreen(topicId: state.pathParameters['topicId']!),
          ),
          GoRoute(
            path: '/desafios/:topicId',
            builder: (context, state) =>
                QuizScreen(topicId: state.pathParameters['topicId']!),
          ),
          GoRoute(
            path: '/aprender/:topicId',
            builder: (context, state) =>
                LearningScreen(topicId: state.pathParameters['topicId']!),
          ),
          GoRoute(
            path: '/preferencias',
            builder: (context, state) => const SettingsScreen(),
          ),
          if (kDebugMode)
            GoRoute(
              path: '/componentes',
              builder: (context, state) => const ComponentGallery(),
            ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class EstudaAiApp extends ConsumerWidget {
  const EstudaAiApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Estuda Aí',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(settingsProvider).theme,
      routerConfig: router,
      builder: (context, child) => CallbackShortcuts(
        bindings: {
          const SingleActivator(
            LogicalKeyboardKey.digit1,
            control: true,
            alt: true,
          ): () =>
              router.go('/'),
          const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
              router.go('/preferencias'),
        },
        child: child!,
      ),
    );
  }
}
