import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../domain/safety_models.dart';
import '../providers/safety_providers.dart';

/// Réglages > Sécurité et confidentialité. Pour les moins de 18 ans, les
/// valeurs de départ sont les plus protectrices (voir
/// `app_config.legal.minor_defaults`) et les messages privés ne peuvent
/// jamais s'ouvrir à tout le monde.
class SafetySettingsScreen extends ConsumerStatefulWidget {
  const SafetySettingsScreen({super.key});

  @override
  ConsumerState<SafetySettingsScreen> createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends ConsumerState<SafetySettingsScreen> {
  bool _saving = false;

  Future<void> _save(Map<String, Object?> change) async {
    setState(() => _saving = true);
    try {
      await ref.read(safetyDataSourceProvider).updateSettings(change);
      ref.invalidate(mySafetyProvider);
      await ref.read(mySafetyProvider.future);
    } on Failure catch (f) {
      if (mounted) context.showSnackBar(f.message, isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mySafetyProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Sécurité et confidentialité'.tr)),
      body: async.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(child: Text(e is Failure ? e.message : 'Erreur de chargement.'.tr)),
        data: (s) => AbsorbPointer(
          absorbing: _saving,
          child: ListView(
            children: [
              ListTile(
                leading: Icon(s.isProtected ? Icons.shield : Icons.person_outline),
                title: Text(s.isProtected ? 'Mode protégé'.tr : 'Mode standard'.tr),
                subtitle: Text(
                  s.isProtected
                      ? 'Compte de moins de 18 ans : protections renforcées.'.tr
                      : 'Compte de 18 ans et plus.'.tr,
                ),
              ),
              if (s.isMinor)
                Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    ('Tu as moins de 18 ans : ton compte démarre avec les réglages '
                            'les plus protecteurs. Tu peux en changer certains, '
                            'idéalement avec tes parents.')
                        .tr,
                  ),
                ),
              _Section('PROFIL'.tr),
              SwitchListTile(
                secondary: const Icon(Icons.lock_outline),
                title: Text('Profil limité'.tr),
                subtitle: Text(
                  ('Les inconnus voient seulement ton pseudo, ton niveau et ton '
                          'poste. Tes abonnés, ta bio et tes infos restent pour les '
                          'joueurs que tu suis.')
                      .tr,
                ),
                value: s.profileVisibility == 'limited',
                onChanged: (v) => _save({'profile_visibility': v ? 'limited' : 'public'}),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.location_off_outlined),
                title: Text('Montrer ma ville'.tr),
                subtitle: Text(
                  'Ta ville apparaît sur ton profil et dans le classement de ta ville. Aucune position GPS n\'est jamais collectée.'.tr,
                ),
                value: s.showLocation,
                onChanged: (v) => _save({'show_location': v}),
              ),
              _Section('MESSAGES PRIVÉS'.tr),
              RadioGroup<String>(
                groupValue: s.dmFrom,
                onChanged: (v) => v == null ? null : _save({'dm_from': v}),
                child: Column(
                  children: [
                    if (!s.isMinor)
                      RadioListTile<String>(value: 'everyone', title: Text('Tout le monde'.tr)),
                    RadioListTile<String>(
                      value: 'mutual',
                      title: Text('Seulement mes abonnés mutuels'.tr),
                      subtitle: Text('Vous vous suivez tous les deux.'.tr),
                    ),
                    RadioListTile<String>(value: 'nobody', title: Text('Personne'.tr)),
                  ],
                ),
              ),
              if (s.isMinor)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    ('Une marque ne peut jamais t\'écrire en privé. Un recruteur '
                            'doit être ton abonné mutuel et avoir l\'accord de ton parent.')
                        .tr,
                    style: context.textTheme.bodySmall,
                  ),
                ),
              _Section('BATTLES'.tr),
              SwitchListTile(
                secondary: const Icon(Icons.shuffle),
                title: Text('Accepter les Battles contre un adversaire aléatoire'.tr),
                subtitle: Text('Sinon, seuls les joueurs qui te choisissent par ton pseudo peuvent te défier.'.tr),
                value: s.allowRandomBattles,
                onChanged: (v) => _save({'allow_random_battles': v}),
              ),
              _Section('TEMPS D\'ÉCRAN'.tr),
              SwitchListTile(
                secondary: const Icon(Icons.local_fire_department_outlined),
                title: Text('Afficher les séries de jours'.tr),
                value: s.showStreaks,
                onChanged: (v) => _save({'show_streaks': v}),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.favorite_border),
                title: Text('Séries sans perte'.tr),
                subtitle: Text('Un jour sans jouer ne remet pas ta série à zéro.'.tr),
                value: s.gentleStreaks,
                onChanged: (v) => _save({'gentle_streaks': v}),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.timer_outlined),
                title: Text('Afficher les comptes à rebours'.tr),
                subtitle: Text('Sinon, la date de fin des défis est affichée.'.tr),
                value: s.showCountdowns,
                onChanged: (v) => _save({'show_countdowns': v}),
              ),
              ListTile(
                leading: const Icon(Icons.self_improvement),
                title: Text('Rappel de pause'.tr),
                subtitle: Text(
                  s.breakReminderMinutes == 0
                      ? 'Désactivé'.tr
                      : 'Après {n} minutes d\'utilisation'.trArgs({'n': s.breakReminderMinutes}),
                ),
                trailing: DropdownButton<int>(
                  value: const [0, 30, 45, 60, 90].contains(s.breakReminderMinutes) ? s.breakReminderMinutes : 45,
                  items: [
                    for (final m in const [0, 30, 45, 60, 90])
                      DropdownMenuItem(value: m, child: Text(m == 0 ? 'Désactivé'.tr : '{n} min'.trArgs({'n': m}))),
                  ],
                  onChanged: (m) => m == null ? null : _save({'break_reminder_minutes': m}),
                ),
              ),
              _Section('JOUEURS BLOQUÉS'.tr),
              const _BlockedList(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: Text('Sécurité et aide'.tr),
                subtitle: Text('Conseils, signaler un problème, nous contacter.'.tr),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RouteNames.legalPath('securite')),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
        child: Text(text, style: context.textTheme.bodySmall?.copyWith(letterSpacing: 1)),
      );
}

class _BlockedList extends ConsumerWidget {
  const _BlockedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBlocksProvider);
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: Center(child: AppLoader())),
      error: (e, _) => ListTile(title: Text(e is Failure ? e.message : 'Erreur de chargement.'.tr)),
      data: (List<BlockedUser> list) {
        if (list.isEmpty) {
          return ListTile(title: Text('Aucun joueur bloqué.'.tr, style: context.textTheme.bodyMedium));
        }
        return Column(
          children: [
            for (final b in list)
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('@${b.username}'),
                trailing: TextButton(
                  onPressed: () async {
                    try {
                      await ref.read(safetyDataSourceProvider).unblock(b.userId);
                      ref
                        ..invalidate(myBlocksProvider)
                        ..invalidate(publicProfileProvider(b.userId));
                    } on Failure catch (f) {
                      if (context.mounted) context.showSnackBar(f.message, isError: true);
                    }
                  },
                  child: Text('Débloquer'.tr),
                ),
              ),
          ],
        );
      },
    );
  }
}
