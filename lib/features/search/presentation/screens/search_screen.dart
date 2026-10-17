import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/string_extensions.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../domain/entities/search_results.dart';
import '../providers/search_providers.dart';

/// Écran "Search" (PARTIE 9.2, écran 34) : joueurs par username, Moves par
/// nom — les deux entrées de découverte hors de l'algorithme du feed.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Chercher un joueur ou un Move…'.tr,
            border: InputBorder.none,
          ),
          onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
        ),
      ),
      body: query.trim().length < 2
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Tape au moins 2 caractères pour chercher un joueur ou un Move.'.tr,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : resultsAsync.when(
              loading: () => const AppFullScreenLoader(),
              error: (error, _) => Center(
                child: Text(error is Failure ? error.message : 'Erreur de recherche.'.tr),
              ),
              data: (results) => _SearchResultsList(results: results),
            ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    if (results.players.isEmpty && results.moves.isEmpty) {
      return Center(child: Text('Aucun résultat.'.tr));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (results.players.isNotEmpty) ...[
          _SectionLabel(label: 'Joueurs'.tr),
          ...results.players.map(
            (p) => ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceLight,
                child: Text(p.username.isNotEmpty ? p.username[0].toUpperCase() : '?'),
              ),
              title: Text('@${p.username}'),
              subtitle: Text(p.level.fromSnakeCaseToTitle),
              onTap: () => context.push(RouteNames.otherProfilePath(p.id)),
            ),
          ),
        ],
        if (results.moves.isNotEmpty) ...[
          const _SectionLabel(label: 'Moves'),
          ...results.moves.map(
            (v) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceLight,
                child: Icon(Icons.bolt, color: AppColors.primary),
              ),
              title: Text(v.moveName ?? 'Move'),
              subtitle: Text(
                '{n} reproductions'.trArgs({'n': v.reproductionsCount}),
              ),
              onTap: () => context.push(RouteNames.moveDetailPath(v.id)),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1),
      ),
    );
  }
}
