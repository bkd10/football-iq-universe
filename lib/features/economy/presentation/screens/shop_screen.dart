import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '../../../../core/constants/route_names.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/browser/browser.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../legal/presentation/screens/legal_screen.dart';

/// Pack de Ballons tel que fixé côté serveur (`coin_packs`) : l'appli
/// n'invente jamais un prix.
class _BallonPack {
  const _BallonPack({
    required this.id,
    required this.ballons,
    required this.priceCents,
    required this.currency,
    this.bonusLabel,
  });

  factory _BallonPack.fromJson(Map<String, dynamic> j) => _BallonPack(
        id: j['id'] as String,
        ballons: (j['coins'] as num).toInt(),
        priceCents: (j['price_cents'] as num).toInt(),
        currency: (j['currency'] as String?) ?? 'eur',
        bonusLabel: j['bonus_label'] as String?,
      );

  final String id;
  final int ballons;
  final int priceCents;
  final String currency;
  final String? bonusLabel;

  String get priceLabel {
    final euros = (priceCents / 100).toStringAsFixed(2);
    final symbol = currency == 'eur' ? '€' : currency.toUpperCase();
    return L10n.language == 'en' ? '$symbol$euros' : '${euros.replaceAll('.', ',')} $symbol';
  }
}

final _packsProvider = FutureProvider.autoDispose<List<_BallonPack>>((ref) async {
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('coin_packs')
      .select()
      .eq('active', true)
      .order('sort_order', ascending: true);
  return rows.map(_BallonPack.fromJson).toList();
});

/// Boutique de Ballons, paiement par Stripe (fonction Edge
/// `create-checkout`). Les Ballons sont crédités par le webhook Stripe,
/// jamais par l'appli.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _busyPack;

  Future<void> _buy(_BallonPack pack) async {
    setState(() => _busyPack = pack.id);
    String? error;
    try {
      final res = await ref.read(supabaseClientProvider).functions.invoke(
        'create-checkout',
        body: {'pack_id': pack.id, 'return_origin': Uri.base.origin},
      );
      final url = (res.data as Map?)?['url'] as String?;
      if (url == null || !openExternalLink(url)) {
        error = 'Le paiement n\'a pas pu s\'ouvrir.'.tr;
      }
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['error'] as String? : null;
      error = message != null ? message.trServer : 'Le paiement n\'est pas encore disponible.'.tr;
    } catch (_) {
      error = 'Vérifie ta connexion internet.'.tr;
    }
    if (!mounted) return;
    setState(() => _busyPack = null);
    if (error != null) context.showSnackBar(error, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(_packsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Boutique'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    ('Paiement sécurisé par Stripe. Les Ballons servent à entrer '
                            'dans les défis et aux bonus, et n\'ont aucune valeur en '
                            'argent. Moins de 18 ans : achats avec l\'accord de tes '
                            'parents, 50 € maximum par mois.')
                        .tr,
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...packs.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (_, __) => [Text('Une erreur inattendue est survenue.'.tr)],
            data: (list) => [
              for (final pack in list) ...[
                _PackTile(
                  pack: pack,
                  busy: _busyPack == pack.id,
                  onBuy: _busyPack == null ? () => _buy(pack) : null,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push(RouteNames.legalPath(LegalDoc.ballons.slug)),
            child: Text('Règles des Ballons'.tr),
          ),
        ],
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack, required this.busy, this.onBuy});

  final _BallonPack pack;
  final bool busy;
  final VoidCallback? onBuy;

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
                  'Ballons'.tr,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton(
            // Le thème donne aux boutons toute la largeur : ici, taille fixe.
            style: OutlinedButton.styleFrom(minimumSize: const Size(104, 44)),
            onPressed: onBuy,
            child: busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(pack.priceLabel),
          ),
        ],
      ),
    );
  }
}
