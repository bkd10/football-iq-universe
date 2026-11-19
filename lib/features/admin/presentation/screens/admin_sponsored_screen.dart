import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../challenges/presentation/widgets/date_time_field.dart';
import '../../../sponsored/domain/sponsored_models.dart';
import '../../../sponsored/presentation/providers/sponsored_providers.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_providers.dart';

/// Défis sponsorisés : fréquence de la carte dans le fil, et brouillons
/// (dont Passe D). Un brouillon n'est jamais visible des joueurs ; le
/// serveur refuse de l'activer tant qu'il manque un champ ou que le sponsor
/// n'est pas coché « confirmé ».
class AdminSponsoredScreen extends ConsumerWidget {
  const AdminSponsoredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(adminSponsoredDraftsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Défis sponsorisés'.tr)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(adminSponsoredDraftsProvider)
            ..invalidate(sponsoredFeedConfigProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _FeedFrequencyCard(),
            const SizedBox(height: AppSpacing.lg),
            drafts.when(
              loading: () => const Center(child: AppLoader()),
              error: (e, _) => Text(adminErrorText(e), style: const TextStyle(color: AppColors.error)),
              data: (list) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final d in list) _DraftForm(key: ValueKey(d.id), draft: d),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text('Nouveau brouillon'.tr),
                    onPressed: () async {
                      try {
                        await ref.read(adminDataSourceProvider).saveSponsoredDraft(null, const {});
                        ref.invalidate(adminSponsoredDraftsProvider);
                      } catch (e) {
                        if (context.mounted) context.showSnackBar(adminErrorText(e), isError: true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedFrequencyCard extends ConsumerStatefulWidget {
  const _FeedFrequencyCard();

  @override
  ConsumerState<_FeedFrequencyCard> createState() => _FeedFrequencyCardState();
}

class _FeedFrequencyCardState extends ConsumerState<_FeedFrequencyCard> {
  int? _everyN;
  bool? _enabled;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(sponsoredFeedConfigProvider).valueOrNull ?? const SponsoredFeedConfig();
    final everyN = _everyN ?? config.everyN;
    final enabled = _enabled ?? config.enabled;
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dans le fil'.tr, style: context.textTheme.titleMedium),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Montrer les défis sponsorisés actifs'.tr),
              value: enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            Text(
              'Une carte « Sponsorisé » toutes les {n} vidéos (Pour toi et Tendances).'.trArgs({'n': everyN}),
            ),
            Slider(
              value: everyN.toDouble(),
              min: SponsoredFeedConfig.minEveryN.toDouble(),
              max: 20,
              divisions: 20 - SponsoredFeedConfig.minEveryN,
              label: '$everyN',
              onChanged: (v) => setState(() => _everyN = v.round()),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await ref
                              .read(adminDataSourceProvider)
                              .setSponsoredFeed(everyN: everyN, enabled: enabled);
                          ref.invalidate(sponsoredFeedConfigProvider);
                          if (context.mounted) context.showSnackBar('Réglage enregistré.'.tr);
                        } catch (e) {
                          if (context.mounted) context.showSnackBar(adminErrorText(e), isError: true);
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text('Enregistrer'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftForm extends ConsumerStatefulWidget {
  const _DraftForm({required this.draft, super.key});

  final AdminSponsoredDraft draft;

  @override
  ConsumerState<_DraftForm> createState() => _DraftFormState();
}

class _DraftFormState extends ConsumerState<_DraftForm> {
  late final _title = TextEditingController(text: widget.draft.title);
  late final _description = TextEditingController(text: widget.draft.description);
  late final _sponsor = TextEditingController(text: widget.draft.sponsorName);
  late final _logo = TextEditingController(text: widget.draft.sponsorLogoUrl);
  late final _entry = TextEditingController(text: widget.draft.entryCost?.toString());
  late final _stars = TextEditingController(text: widget.draft.rewardStars?.toString());
  late final _prize = TextEditingController(text: widget.draft.prizeDescription);
  late DateTime? _start = widget.draft.startDate;
  late DateTime? _end = widget.draft.endDate;
  late bool _confirmed = widget.draft.sponsorConfirmed;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_title, _description, _sponsor, _logo, _entry, _stars, _prize]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> get _fields => {
        'title': _title.text,
        'description': _description.text,
        'sponsor_name': _sponsor.text,
        'sponsor_logo_url': _logo.text,
        'sponsor_confirmed': _confirmed,
        'start_date': _start?.toUtc().toIso8601String(),
        'end_date': _end?.toUtc().toIso8601String(),
        'entry_cost': int.tryParse(_entry.text.trim()),
        'reward_stars': int.tryParse(_stars.text.trim()),
        'prize_description': _prize.text,
      };

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) context.showSnackBar(adminErrorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _run(() async {
        await ref.read(adminDataSourceProvider).saveSponsoredDraft(widget.draft.id, _fields);
        ref.invalidate(adminSponsoredDraftsProvider);
        if (mounted) context.showSnackBar('Brouillon enregistré (non activé).'.tr);
      });

  Future<void> _activate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activer ce défi ?'.tr),
        content: Text(
          ('Il apparaîtra dans le fil de tous les joueurs et chacun recevra la '
                  'notification « Nouveau challenge ». Cette action ne s\'annule pas.')
              .tr,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler'.tr)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Activer'.tr)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final ds = ref.read(adminDataSourceProvider);
      await ds.saveSponsoredDraft(widget.draft.id, _fields);
      final id = await ds.activateSponsoredDraft(widget.draft.id);
      ref
        ..invalidate(adminSponsoredDraftsProvider)
        ..invalidate(sponsoredFeedChallengesProvider);
      if (mounted) unawaited(context.push(RouteNames.challengeDetailPath(id)));
    });
  }

  Widget _dateTile(String label, DateTime? value, ValueChanged<DateTime> onChanged) {
    final now = DateTime.now();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value == null ? '[À COMPLÉTER]'.tr : DateTimeField.format(value),
        style: TextStyle(color: value == null ? AppColors.gold : null),
      ),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: widget.draft.isActivated
          ? null
          : () async {
              final initial = value ?? now.add(const Duration(days: 1));
              final date = await showDatePicker(
                context: context,
                initialDate: initial.isBefore(now) ? now : initial,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (date == null || !mounted) return;
              final time = await showTimePicker(
                // ignore: use_build_context_synchronously
                context: context,
                initialTime: TimeOfDay.fromDateTime(initial),
              );
              if (time == null) return;
              setState(() => onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute)));
            },
    );
  }

  InputDecoration _deco(String label, {String? helper}) => InputDecoration(
        labelText: label,
        hintText: '[À COMPLÉTER]'.tr,
        helperText: helper,
        helperMaxLines: 3,
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final locked = d.isActivated;
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.title?.isNotEmpty ?? false ? d.title! : 'Défi {sponsor}'.trArgs({'sponsor': d.sponsorName}),
                    style: context.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    locked
                        ? 'Activé'.tr
                        : 'Brouillon — non activé'.tr,
                  ),
                  backgroundColor: locked ? AppColors.primary.withValues(alpha: 0.2) : Colors.white10,
                ),
              ],
            ),
            if (!locked && d.missing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Il manque : {list}'.trArgs({'list': d.missing.map((m) => m.tr).join(', ')}),
                  style: const TextStyle(color: AppColors.gold),
                ),
              ),
            TextField(controller: _title, enabled: !locked, maxLength: 80, decoration: _deco('Titre'.tr)),
            TextField(
              controller: _description,
              enabled: !locked,
              maxLength: 1000,
              maxLines: 4,
              decoration: _deco('Description et règles'.tr),
            ),
            TextField(controller: _sponsor, enabled: !locked, decoration: _deco('Sponsor'.tr)),
            TextField(
              controller: _logo,
              enabled: !locked,
              keyboardType: TextInputType.url,
              decoration: _deco(
                'Logo du sponsor (adresse https)'.tr,
                helper: '[À FOURNIR] Image carrée, fond clair de préférence.'.tr,
              ),
            ),
            _dateTile('Début des votes'.tr, _start, (v) => _start = v),
            _dateTile('Fin du défi'.tr, _end, (v) => _end = v),
            TextField(
              controller: _entry,
              enabled: !locked,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deco(
                'Coût d\'entrée en Ballons'.tr,
                helper: 'Les défis d\'une marque sont annoncés « gratuits » dans les conditions : 0 recommandé.'.tr,
              ),
            ),
            TextField(
              controller: _stars,
              enabled: !locked,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deco('Récompense du gagnant en Stars'.tr),
            ),
            TextField(
              controller: _prize,
              enabled: !locked,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Lot réel offert par le sponsor (optionnel)'.tr,
                helperText: 'Avec un lot réel, l\'entrée doit être gratuite.'.tr,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirmed,
              onChanged: locked ? null : (v) => setState(() => _confirmed = v ?? false),
              title: Text('Sponsor confirmé (contrat signé)'.tr),
              subtitle: Text('Ne coche que quand le partenariat est officiel.'.tr),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!locked) ...[
              OutlinedButton(
                onPressed: _busy ? null : _save,
                child: Text('Enregistrer le brouillon'.tr),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppPrimaryButton(
                label: 'Activer le défi'.tr,
                isLoading: _busy,
                onPressed: _activate,
              ),
            ] else
              OutlinedButton(
                onPressed: () => context.push(RouteNames.challengeDetailPath(d.challengeId!)),
                child: Text('Voir le défi'.tr),
              ),
          ],
        ),
      ),
    );
  }
}
