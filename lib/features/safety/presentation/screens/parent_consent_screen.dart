import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../providers/safety_providers.dart';

final _requestProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, token) => ref.watch(safetyDataSourceProvider).getParentConsentRequest(token),
);

/// Page ouverte par un parent (sans compte) depuis le lien que son enfant
/// lui a transmis : autoriser ou refuser les achats de Ballons. Utilisée
/// seulement si `app_config.legal.minor_purchases = 'parental_consent'`.
class ParentConsentScreen extends ConsumerStatefulWidget {
  const ParentConsentScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<ParentConsentScreen> createState() => _ParentConsentScreenState();
}

class _ParentConsentScreenState extends ConsumerState<ParentConsentScreen> {
  bool _busy = false;
  bool? _answered;

  Future<void> _answer(bool approve) async {
    setState(() => _busy = true);
    try {
      await ref.read(safetyDataSourceProvider).answerParentConsent(widget.token, approve: approve);
      if (mounted) setState(() => _answered = approve);
    } on Failure catch (f) {
      if (mounted) context.showSnackBar(f.message, isError: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_requestProvider(widget.token));
    return Scaffold(
      appBar: AppBar(title: Text('Accord parental'.tr)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: async.when(
          loading: () => const Center(child: AppLoader()),
          error: (e, _) => Text(e is Failure ? e.message : 'Lien invalide ou déjà utilisé.'.tr),
          data: (req) {
            if (_answered != null) {
              return Text(
                _answered! ? 'Merci : les achats sont autorisés.'.tr : 'Merci : les achats restent bloqués.'.tr,
                style: context.textTheme.titleMedium,
              );
            }
            if (req == null || req['valid'] != true) {
              return Text('Lien invalide ou déjà utilisé.'.tr);
            }
            final limit = ((req['monthly_limit_cents'] as num?) ?? 5000) / 100;
            return ListView(
              children: [
                Text(
                  '@{name} demande ton accord pour acheter des Ballons dans Football IQ.'
                      .trArgs({'name': req['username']}),
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  ('Les Ballons sont une monnaie virtuelle du jeu, sans valeur en '
                          'argent. Ils se gagnent aussi gratuitement en jouant. Chaque '
                          'achat est un paiement unique (pas d\'abonnement), au prix '
                          'affiché avant de payer, avec un plafond de {limit} € par mois. '
                          'Tu peux retirer ton accord à tout moment en écrivant au support.')
                      .trArgs({'limit': limit.toStringAsFixed(0)}),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _busy ? null : () => _answer(true),
                  child: Text('J\'autorise les achats'.tr),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: _busy ? null : () => _answer(false),
                  child: Text('Je refuse'.tr),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
