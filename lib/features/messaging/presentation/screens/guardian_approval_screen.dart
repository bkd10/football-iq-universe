import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../providers/messaging_providers.dart';

/// Écran d'approbation tuteur — voir PARTIE 8.4/8.5. Volontairement
/// accessible SANS connexion (le tuteur n'a pas nécessairement de compte) :
/// n'importe qui connaissant le code peut approuver/refuser, exactement
/// comme les fonctions serveur `approve_guardian_contact`/
/// `decline_guardian_contact` (ouvertes à `anon`) le permettent déjà — ce
/// code est un jeton uuid aléatoire, jamais énumérable.
class GuardianApprovalScreen extends ConsumerStatefulWidget {
  const GuardianApprovalScreen({this.initialToken, super.key});

  final String? initialToken;

  @override
  ConsumerState<GuardianApprovalScreen> createState() =>
      _GuardianApprovalScreenState();
}

class _GuardianApprovalScreenState extends ConsumerState<GuardianApprovalScreen> {
  late final _tokenController = TextEditingController(text: widget.initialToken ?? '');
  bool _isSubmitting = false;
  String? _resultMessage;
  bool _resultIsError = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _act(bool approve) async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _resultMessage = 'Renseigne le code reçu du joueur.';
        _resultIsError = true;
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _resultMessage = null;
    });

    final notifier = ref.read(messagingActionsControllerProvider.notifier);
    final success = approve
        ? await notifier.approveGuardianContact(token)
        : await notifier.declineGuardianContact(token);

    if (!mounted) return;
    final error = ref.read(messagingActionsControllerProvider).error;
    setState(() {
      _isSubmitting = false;
      _resultIsError = !success;
      _resultMessage = success
          ? (approve
              ? 'Contact approuvé — le joueur peut désormais échanger avec ce recruteur.'
              : 'Contact refusé.')
          : (error is Failure ? error.message : 'Une erreur est survenue.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approbation tuteur')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Un recruteur vérifié souhaite contacter un joueur mineur.',
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Football IQ Universe médie systématiquement tout contact '
                'avec un joueur mineur : ce contact ne sera possible que si '
                'tu l\'approuves ici, en tant que tuteur.',
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'Code reçu du joueur'),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_resultMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (_resultIsError ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    _resultMessage!,
                    style: TextStyle(
                      color: _resultIsError ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppPrimaryButton(
                label: 'Approuver le contact',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : () => _act(true),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => _act(false),
                child: const Text('Refuser le contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
