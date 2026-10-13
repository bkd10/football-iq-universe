import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../../shared/widgets/video_thumbnail_tile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../videos/presentation/providers/video_providers.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_participation.dart';
import '../providers/challenge_providers.dart';
import '../widgets/challenge_card.dart';

/// Détail d'un défi — voir PARTIE 8.3/9.2 (écrans "Challenge Detail" et
/// "Challenge Voting" fusionnés). Le vote et la participation partagent
/// cet écran plutôt que d'être séparés, pour éviter la navigation
/// supplémentaire une fois qu'on a déjà rejoint.
class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({required this.challengeId, super.key});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeByIdProvider(challengeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Défi')),
      body: challengeAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Text(error is Failure ? error.message : 'Erreur de chargement.'),
        ),
        data: (challenge) {
          if (challenge == null) {
            return Center(
              child: Text('Ce défi est introuvable.', style: context.textTheme.bodyLarge),
            );
          }
          return _ChallengeBody(challenge: challenge);
        },
      ),
    );
  }
}

class _ChallengeBody extends ConsumerWidget {
  const _ChallengeBody({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participationsAsync = ref.watch(participationsProvider(challenge.id));
    final myProfile = ref.watch(currentProfileProvider).valueOrNull;
    final myParticipation = participationsAsync.valueOrNull
        ?.where((p) => p.userId == myProfile?.id)
        .toList();
    final hasJoined = myParticipation != null && myParticipation.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              challengeTypeLabels[challenge.type] ?? challenge.type,
              style: const TextStyle(
                color: AppColors.diamond,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              challenge.status == 'completed'
                  ? 'Terminé'
                  : Formatters.countdown(challenge.timeRemaining),
              style: AppTypography.stat(color: AppColors.gold),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(challenge.title, style: context.textTheme.displaySmall),
        if (challenge.type == 'sponsored' && challenge.sponsorName != null) ...[
          const SizedBox(height: 2),
          Text(
            'Par ${challenge.sponsorName}',
            style: const TextStyle(color: AppColors.diamond, fontWeight: FontWeight.w600),
          ),
        ],
        if (challenge.description != null && challenge.description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(challenge.description!, style: context.textTheme.bodyLarge),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (challenge.type == 'sponsored')
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const _InfoStat(label: 'Entrée', value: 'Gratuit'),
              _InfoStat(label: 'Prix', value: challenge.prizeDescription ?? '—'),
              _InfoStat(
                label: 'Participants',
                value: '${challenge.participantsCount}'
                    '${challenge.maxParticipants != null ? '/${challenge.maxParticipants}' : ''}',
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoStat(label: 'Entrée', value: '${challenge.entryCost} Ballons'),
              _InfoStat(label: 'Cagnotte', value: '${challenge.prizePool} Ballons'),
              _InfoStat(
                label: 'Participants',
                value: '${challenge.participantsCount}'
                    '${challenge.maxParticipants != null ? '/${challenge.maxParticipants}' : ''}',
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        _RulesBanner(challenge: challenge),
        const SizedBox(height: AppSpacing.xl),
        if (challenge.type == 'king')
          _KingRecordBanner(challenge: challenge)
        else if (challenge.status != 'completed' && !hasJoined)
          AppPrimaryButton(
            label: challenge.type == 'sponsored'
                ? 'Participer gratuitement'
                : 'Participer (${challenge.entryCost} Ballons)',
            icon: Icons.videocam,
            onPressed: challenge.isFull
                ? null
                : () => _openParticipateSheet(context, ref, challenge),
          )
        else if (hasJoined)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text('Tu participes déjà à ce défi.'),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        Text('Participants', style: context.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        participationsAsync.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => Text(
            error is Failure ? error.message : 'Erreur de chargement.',
          ),
          data: (participations) {
            if (participations.isEmpty) {
              return Text(
                'Aucun participant pour l\'instant.',
                style: context.textTheme.bodyMedium,
              );
            }
            return Column(
              children: participations
                  .map(
                    (p) => _ParticipationTile(
                      participation: p,
                      challenge: challenge,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openParticipateSheet(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) async {
    final myProfile = ref.read(currentProfileProvider).valueOrNull;
    if (myProfile == null) return;

    final videoId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _VideoPickerSheet(userId: myProfile.id),
    );
    if (videoId == null || !context.mounted) return;

    final success = await ref
        .read(challengeActionsControllerProvider.notifier)
        .join(challengeId: challenge.id, videoId: videoId);

    if (!context.mounted) return;
    if (success) {
      context.showSnackBar('Tu participes au défi !');
    } else {
      final failure = ref.read(challengeActionsControllerProvider).error;
      context.showSnackBar(
        failure is Failure ? failure.message : 'Échec de la participation.',
        isError: true,
      );
    }
  }
}

class _KingRecordBanner extends StatelessWidget {
  const _KingRecordBanner({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.gold, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            challenge.currentRecord != null
                ? '${challenge.currentRecord} ${challenge.recordUnit ?? ''}'
                : 'Aucun record',
            style: AppTypography.stat(fontSize: 24, color: AppColors.gold),
          ),
          Text(
            challenge.recordHolder != null
                ? 'par @${challenge.recordHolder!.username}'
                : 'Sois le premier à établir un record !',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Explique en clair, dans l'écran lui-même, ce que les chiffres "Entrée"/
/// "Cagnotte" veulent dire — sans ça, les joueurs n'ont aucun moyen de
/// savoir comment la cagnotte se constitue ni comment le vainqueur est
/// désigné (ces règles n'existaient auparavant que dans les commentaires
/// du code SQL, invisibles côté app).
class _RulesBanner extends StatelessWidget {
  const _RulesBanner({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (challenge.type == 'sponsored') {
      text = 'Défi gratuit proposé par une marque partenaire : aucun Ballon '
          'n\'est débité ni distribué. Le vainqueur (le plus de votes, '
          'égalité départagée par ordre d\'inscription) reçoit le prix '
          'décrit ci-dessus, remis directement par la marque.';
    } else if (challenge.type == 'king') {
      text = 'Le Roi en titre remporte la cagnotte s\'il n\'est pas '
          'détrôné avant la fin du défi. Chaque tentative pour le '
          'détrôner coûte ${challenge.entryCost} Ballons, qui rejoignent '
          'la cagnotte.';
    } else {
      text = 'Chaque droit d\'entrée (${challenge.entryCost} Ballons) '
          'rejoint la cagnotte, versée en intégralité au vainqueur. Le '
          'vainqueur est le participant avec le plus de votes (égalité '
          'départagée par ordre d\'inscription) — un seul vote par '
          'joueur.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.stat(fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ParticipationTile extends ConsumerWidget {
  const _ParticipationTile({required this.participation, required this.challenge});

  final ChallengeParticipation participation;
  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            child: SizedBox(
              width: 56,
              height: 74,
              child: participation.videoThumbnailUrl != null
                  ? Image.network(participation.videoThumbnailUrl!, fit: BoxFit.cover)
                  : const ColoredBox(
                      color: AppColors.surface,
                      child: Icon(Icons.videocam_outlined, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${participation.participant?.username ?? 'inconnu'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (participation.rank != null)
                  Text(
                    'Rang #${participation.rank}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (challenge.status != 'completed')
            OutlinedButton.icon(
              // Le thème impose une largeur infinie aux boutons (pleine
              // largeur par défaut) : dans une Row, ça écrasait le pseudo
              // du participant à 0 px de large (une lettre par ligne).
              style: OutlinedButton.styleFrom(minimumSize: const Size(72, 40)),
              onPressed: participation.hasVoted
                  ? null
                  : () => ref
                      .read(challengeActionsControllerProvider.notifier)
                      .vote(
                        challengeId: challenge.id,
                        participantUserId: participation.userId,
                      ),
              icon: Icon(
                participation.hasVoted ? Icons.how_to_vote : Icons.how_to_vote_outlined,
                size: 16,
              ),
              label: Text('${participation.votesCount}'),
            )
          else
            Text(
              '${participation.votesCount} votes',
              style: AppTypography.stat(fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _VideoPickerSheet extends ConsumerWidget {
  const _VideoPickerSheet({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(userVideosProvider(userId));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Choisis ta vidéo', style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: videosAsync.when(
                loading: () => const Center(child: AppLoader()),
                error: (error, _) => Center(
                  child: Text(error is Failure ? error.message : 'Erreur.'),
                ),
                data: (videos) {
                  if (videos.isEmpty) {
                    return Center(
                      child: Text(
                        'Publie d\'abord une vidéo pour pouvoir participer.',
                        style: context.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return VideoThumbnailTile(
                        video: video,
                        onTap: () => Navigator.of(context).pop(video.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
