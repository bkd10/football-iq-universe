import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../domain/entities/pepite_of_the_day.dart';
import '../providers/pepite_providers.dart';

/// "La Pépite du Jour" — voir PARTIE 8.9 / 9.2 (écran 6). Premier écran vu
/// à chaque entrée dans l'app authentifiée (voir le redirect de
/// `AppRouter`) : incarne la promesse centrale du produit — "Ici, un
/// inconnu peut devenir une star." — avant de rejoindre le feed.
class PepiteOfTheDayScreen extends ConsumerWidget {
  const PepiteOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pepiteAsync = ref.watch(pepiteOfTheDayProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: pepiteAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          // En cas d'échec (réseau, aucune vidéo candidate ce jour-là) : on
          // ne bloque jamais l'accès à l'app pour un contenu éditorial.
          error: (_, __) => const _NoPepiteBody(),
          data: (pepite) =>
              pepite == null ? const _NoPepiteBody() : _PepiteBody(pepite: pepite),
        ),
      ),
    );
  }
}

class _NoPepiteBody extends StatelessWidget {
  const _NoPepiteBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 56, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Football IQ Universe',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ici, un inconnu peut devenir une star.'.tr,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: 'Voir le feed'.tr,
            onPressed: () => context.go(RouteNames.feed),
          ),
        ],
      ),
    );
  }
}

class _PepiteBody extends StatelessWidget {
  const _PepiteBody({required this.pepite});

  final PepiteOfTheDay pepite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 34, height: 2, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'LA PÉPITE DU JOUR'.tr,
                style: AppTypography.stat(fontSize: 12, color: AppColors.primary),
              ),
            ],
          ),
          const Spacer(),
          if (pepite.country != null)
            Text(_flagFor(pepite.country!), style: const TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.md),
          Text(
            (pepite.displayName ?? pepite.username).toUpperCase(),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              if (pepite.playerPosition != null) pepite.playerPosition!,
              if (pepite.city != null) pepite.city!,
            ].join(' · '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
            decoration: const BoxDecoration(
              border: BorderDirectional(start: BorderSide(color: AppColors.primary, width: 2)),
            ),
            child: Text(
              pepite.caption,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(value: Formatters.compactCount(pepite.viewsCount), label: 'vues'.tr),
              _MiniStat(value: Formatters.compactCount(pepite.stars), label: 'Stars'.tr),
              _MiniStat(value: '#${pepite.worldRank}', label: 'mondial'.tr),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'À ton tour.'.tr,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Voir le feed →'.tr,
            onPressed: () => context.go(RouteNames.feed),
          ),
        ],
      ),
    );
  }

  String _flagFor(String country) {
    const flags = {
      'FR': '🇫🇷', 'SN': '🇸🇳', 'CI': '🇨🇮', 'BR': '🇧🇷', 'MA': '🇲🇦',
      'DE': '🇩🇪', 'ES': '🇪🇸', 'PT': '🇵🇹', 'GB': '🇬🇧', 'US': '🇺🇸',
    };
    return flags[country.toUpperCase()] ?? '🌍';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.stat(fontSize: 19)),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1),
        ),
      ],
    );
  }
}
