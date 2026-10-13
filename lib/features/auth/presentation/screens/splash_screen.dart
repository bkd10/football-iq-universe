import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Écran affiché au lancement pendant que la session est vérifiée et que
/// les feature flags sont chargés. La navigation qui suit (feed / login /
/// onboarding) est entièrement pilotée par le `redirect` de GoRouter, qui
/// réagit à `authStateProvider` — cet écran n'a donc aucune logique de
/// routage propre, uniquement l'identité visuelle.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(FeatureFlags.load());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AnimatedLogo(),
            SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.sports_soccer, size: 88, color: AppColors.primary)
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.05, 1.05),
          duration: 900.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .shimmer(duration: 1200.ms, color: AppColors.primaryLight);
  }
}
