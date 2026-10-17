import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../domain/admin_messages.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_providers.dart';

/// Liste des comptes (les plus récents d'abord), recherche par pseudo, nom
/// ou e-mail, et bannissement / débannissement.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(adminUserSearchProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Joueurs'.tr)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Pseudo, nom ou e-mail'.tr,
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (error, _) => Center(child: Text(adminErrorText(error))),
              data: (users) {
                if (users.isEmpty) {
                  return Center(child: Text('Aucun joueur trouvé.'.tr));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminUsersProvider),
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) => _UserTile(user: users[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});

  final AdminUser user;

  Future<void> _openActions(BuildContext context, WidgetRef ref) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _UserActionsSheet(user: user),
    );
    if (changed ?? false) {
      ref
        ..invalidate(adminUsersProvider)
        ..invalidate(adminStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = [
      if (user.email != null) user.email!,
      '{n} vidéos'.trArgs({'n': user.videosCount}),
      '{n} abonnés'.trArgs({'n': user.followersCount}),
      if (user.reportsCount > 0) '{n} signalements'.trArgs({'n': user.reportsCount}),
    ].join(' · ');

    return ListTile(
      onTap: () => _openActions(context, ref),
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceLight,
        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null ? Text(user.username[0].toUpperCase()) : null,
      ),
      title: Row(
        children: [
          Flexible(child: Text('@${user.username}', overflow: TextOverflow.ellipsis)),
          if (user.role != 'player') ...[
            const SizedBox(width: AppSpacing.xs),
            Text(user.role, style: context.textTheme.bodySmall?.copyWith(color: AppColors.info)),
          ],
          if (user.isBanned) ...[
            const SizedBox(width: AppSpacing.xs),
            Text('BANNI'.tr, style: context.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ],
        ],
      ),
      subtitle: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.more_vert),
    );
  }
}

class _UserActionsSheet extends ConsumerStatefulWidget {
  const _UserActionsSheet({required this.user});

  final AdminUser user;

  @override
  ConsumerState<_UserActionsSheet> createState() => _UserActionsSheetState();
}

class _UserActionsSheetState extends ConsumerState<_UserActionsSheet> {
  final _reasonController = TextEditingController(text: AdminMessages.banReasons.first);
  bool _busy = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _setBan(bool banned) async {
    if (banned && _reasonController.text.trim().isEmpty) {
      context.showSnackBar('Indique la raison du bannissement.'.tr, isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminDataSourceProvider).setBan(
            userId: widget.user.id,
            banned: banned,
            reason: banned ? _reasonController.text.trim() : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      context.showSnackBar(
        (banned ? '@{name} est banni.' : '@{name} est débanni.')
            .trArgs({'name': widget.user.username}),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      context.showSnackBar(adminErrorText(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final joined = '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('@${user.username}', style: context.textTheme.titleLarge),
              Text('Inscrit le {date}'.trArgs({'date': joined}), style: context.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: Text('Voir le profil'.tr),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(RouteNames.otherProfilePath(user.id));
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              if (user.isBanned) ...[
                Text('Banni : {reason}'.trArgs({'reason': user.banReason?.trServer ?? 'sans raison indiquée'.tr}),
                    style: context.textTheme.bodyMedium?.copyWith(color: AppColors.error),),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : () => _setBan(false),
                    child: Text('Débannir'.tr),
                  ),
                ),
              ] else if (user.role != 'admin') ...[
                Text('Bannir ce joueur'.tr,
                    style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),),
                Text(
                  ('Il ne pourra plus se connecter et ses vidéos seront masquées. '
                          'Réversible à tout moment.')
                      .tr,
                  style: context.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final reason in AdminMessages.banReasons)
                      ActionChip(
                        label: Text(reason),
                        onPressed: () => _reasonController.text = reason,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _reasonController,
                  maxLength: 500,
                  decoration: InputDecoration(hintText: 'Raison'.tr),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : () => _setBan(true),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    child: Text('Bannir'.tr),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
