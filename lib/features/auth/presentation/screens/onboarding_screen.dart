import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/onboarding_prefs_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.emoji_events_outlined,
    title: 'Ici, un inconnu peut devenir une star',
    description:
        'Le talent parle, pas les followers. Poste tes gestes techniques et '
        'laisse notre algorithme Talent First te découvrir, où que tu sois.',
  ),
  _OnboardingPage(
    icon: Icons.auto_awesome_outlined,
    title: 'Invente ton Move',
    description:
        'Crée un geste, donne-lui ton nom, et regarde la communauté le '
        'reproduire. Chaque reproduction te crédite — à vie.',
  ),
  _OnboardingPage(
    icon: Icons.trending_up_outlined,
    title: 'Progresse, prouve, sois recruté',
    description:
        'Ton Football IQ n\'est jamais achetable. Ton Football Passport '
        'certifie ton niveau réel — c\'est ce que voient les recruteurs.',
  ),
];

/// Trois écrans qui posent la promesse de l'app, le concept des Moves, et
/// la progression mesurable — voir PARTIE 9.2 de la spécification.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _skipToLogin() async {
    await OnboardingPrefsService.markSeen();
    if (mounted) context.go(RouteNames.login);
  }

  Future<void> _next() async {
    if (_index == _pages.length - 1) {
      await _skipToLogin();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _skipToLogin,
                  child: Text('Passer'.tr),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon, size: 96, color: AppColors.primary)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          page.title.tr,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
                        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.description.tr,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppPrimaryButton(
                label: isLast ? 'Rejoindre l\'aventure'.tr : 'Suivant'.tr,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
