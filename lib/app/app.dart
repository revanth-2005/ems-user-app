import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'app_router.dart';

/// Root application widget. Wraps [MaterialApp.router] with GoRouter
/// and the light theme. Must be a child of [ProviderScope] (set in main.dart).
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'EventSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
