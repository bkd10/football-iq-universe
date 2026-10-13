import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';

/// Boutique de Ballons — packs affichés à titre indicatif, achat désactivé.
///
/// Aucun moyen de paiement réel (App Store/Play Store/Stripe) n'est branché
/// pour l'instant : plutôt que de ne rien montrer, on affiche déjà les
/// packs prévus avec un bouton clairement désactivé, pour ne jamais laisser
/// croire qu'un paiement a été pris alors qu'aucune fonction serveur ne
/// crédite réellement les Ballons.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const _packs = [
    _BallonPack(ballons: 100, priceLabel: '0,99 €'),
    _BallonPack(ballons: 550, priceLabel: '4,99 €', bonusLabel: '+10%'),
    _BallonPack(ballons: 1200, priceLabel: '9,99 €', bonusLabel: '+20%'),
    _BallonPack(ballons: 2500, priceLabel: '19,99 €', bonusLabel: '+25%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boutique')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'L\'achat de Ballons n\'est pas encore disponible. Ces packs '
                    'montrent ce qui arrivera — en attendant, tous les Ballons '
                    's\'obtiennent en jouant.',
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final pack in _packs) ...[
            _PackTile(pack: pack),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _BallonPack {
  const _BallonPack({
    required this.ballons,
    required this.priceLabel,
    this.bonusLabel,
  });

  final int ballons;
  final String priceLabel;
  final String? bonusLabel;
}

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack});

  final _BallonPack pack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.paid_outlined, color: AppColors.gold, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      Formatters.compactCount(pack.ballons),
                      style: context.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (pack.bonusLabel != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          pack.bonusLabel!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Ballons',
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: null,
            child: Text(pack.priceLabel),
          ),
        ],
      ),
    );
  }
}
