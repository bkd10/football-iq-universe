import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '../../../../core/config/store_rules.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/browser/browser.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../legal/presentation/screens/legal_screen.dart';
import '../../../safety/presentation/providers/safety_providers.dart';

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
    if (!inAppPurchasesAllowed) {
      return Scaffold(
        appBar: AppBar(title: Text('Boutique'.tr)),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            ('La boutique n\'est pas disponible dans cette version de '
                    'l\'appli. Gagne des Ballons en jouant : missions, défis '
                    'et bonus.')
                .tr,
            style: context.textTheme.bodyMedium,
          ),
        ),
      );
    }
    final safety = ref.watch(mySafetyNowProvider);
    // Moins de 18 ans sans accord parental : aucun pack ni prix affiché,
    // pas d'incitation à acheter (le serveur refuse de toute façon).
    if (safety.hideShop) {
      return Scaffold(
        appBar: AppBar(title: Text('Boutique'.tr)),
        body: _MinorShopNotice(parentalMode: safety.parentalPurchaseMode),
      );
    }
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
                    safety.isMinor
                        ? ('Paiement sécurisé par Stripe. Les Ballons servent à entrer '
                                'dans les défis et aux bonus, et n\'ont aucune valeur en '
                                'argent. Ton parent a donné son accord : {limit} € maximum par mois.')
                            .trArgs({'limit': (safety.minorMonthlyLimitCents / 100).toStringAsFixed(0)})
                        : ('Paiement sécurisé par Stripe. Les Ballons servent à entrer '
                                'dans les défis et aux bonus, et n\'ont aucune valeur en '
                                'argent.')
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
          // Informations obligatoires avant l'achat (Code de la consommation,
          // art. L221-5 et L221-28 13°) : prix final, paiement unique,
          // renonciation au droit de rétractation.
          Text(
            ('Prix TTC, paiement unique : pas d\'abonnement, pas de frais '
                    'cachés. Les Ballons arrivent tout de suite après le paiement : '
                    'sur la page de paiement, tu demandes cette livraison immédiate '
                    'et tu renonces au délai de rétractation de 14 jours. Paiement '
                    'en double ou Ballons non reçus : remboursés.')
                .tr,
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push(RouteNames.legalPath(LegalDoc.ballons.slug)),
            child: Text('Règles des Ballons et remboursements'.tr),
          ),
        ],
      ),
    );
  }
}

/// Ce que voit un joueur de moins de 18 ans qui ne peut pas acheter.
/// Mode `parental_consent` : il peut créer un lien à envoyer à son parent.
class _MinorShopNotice extends ConsumerStatefulWidget {
  const _MinorShopNotice({required this.parentalMode});

  final bool parentalMode;

  @override
  ConsumerState<_MinorShopNotice> createState() => _MinorShopNoticeState();
}

class _MinorShopNoticeState extends ConsumerState<_MinorShopNotice> {
  bool _busy = false;
  String? _link;

  Future<void> _createLink() async {
    setState(() => _busy = true);
    try {
      final token = await ref.read(safetyDataSourceProvider).requestParentPurchaseConsent();
      final link = '${Uri.base.origin}${RouteNames.parentConsentPrefix}$token';
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) setState(() => _link = link);
    } on Failure catch (f) {
      if (mounted) context.showSnackBar(f.message, isError: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Icon(Icons.shield_outlined, size: 40, color: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.parentalMode
              ? ('Tu as moins de 18 ans : pour acheter des Ballons, il faut '
                      'l\'accord d\'un parent.')
                  .tr
              : 'Les achats de Ballons sont désactivés pour les moins de 18 ans.'.tr,
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          ('Tu peux gagner des Ballons gratuitement en jouant : missions, '
                  'défis et bonus. Tout le jeu reste accessible sans payer.')
              .tr,
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          icon: const Icon(Icons.emoji_events_outlined, size: 18),
          label: Text('Comment gagner'.tr),
          onPressed: () => context.push(RouteNames.earnBallons),
        ),
        if (widget.parentalMode) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _busy ? null : _createLink,
            child: Text('Demander l\'accord de mon parent'.tr),
          ),
          if (_link != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Lien copié. Envoie-le à ton parent : il reste valable quelques jours.'.tr,
              style: context.textTheme.bodySmall,
            ),
            SelectableText(_link!, style: context.textTheme.bodySmall),
          ],
        ],
      ],
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
