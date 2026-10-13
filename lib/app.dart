import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/responsive_app_frame.dart';

class FootballIqUniverseApp extends ConsumerWidget {
  const FootballIqUniverseApp({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: config.isDev,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      // Contraint l'app à une largeur "mobile" sur un navigateur de bureau
      // large — voir `ResponsiveAppFrame`. No-op en dessous de 480px
      // (mobile réel, ou fenêtre navigateur étroite).
      builder: (context, child) =>
          ResponsiveAppFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
