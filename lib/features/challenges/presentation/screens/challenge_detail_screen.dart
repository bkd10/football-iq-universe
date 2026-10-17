import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/challenge_participation.dart';
import '../providers/challenge_providers.dart';
import '../widgets/challenge_card.dart';
import '../widgets/date_time_field.dart';
import '../widgets/my_video_picker_sheet.dart';

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
      appBar: AppBar(title: Text('Défi'.tr)),
      body: challengeAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Text(error is Failure ? error.message : 'Erreur de chargement.'.tr),
        ),
        data: (challenge) {
          if (challenge == null) {
            return Center(
              child: Text('Ce défi est introuvable.'.tr, style: context.textTheme.bodyLarge),
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
              challengeTypeLabels[challenge.type]?.tr ?? challenge.type,
              style: const TextStyle(
                color: AppColors.diamond,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              switch (challenge.status) {
                'completed' => 'Terminé'.tr,
                'cancelled' => 'Annulé'.tr,
                _ => challenge.hasStarted
                    ? Formatters.countdown(challenge.timeRemaining)
                    : 'Commence dans {time}'.trArgs({'time': Formatters.countdown(challenge.timeUntilStart)}),
              },
              style: AppTypography.stat(color: AppColors.gold),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(challenge.title, style: context.textTheme.displaySmall),
        if (challenge.type == 'sponsored' && challenge.sponsorName != null) ...[
          const SizedBox(height: 2),
          Text(
            'Par {sponsor}'.trArgs({'sponsor': challenge.sponsorName}),
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
              _InfoStat(label: 'Entrée'.tr, value: 'Gratuit'.tr),
              _InfoStat(label: 'Prix'.tr, value: challenge.prizeDescription ?? '—'),
              _InfoStat(
                label: 'Participants'.tr,
                value: '${challenge.participantsCount}'
                    '${challenge.maxParticipants != null ? '/${challenge.maxParticipants}' : ''}',
              ),
            ],
          )
        else if (challenge.isBattle) ...[
          _BattleVersus(challenge: challenge),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoStat(
                label: 'Mise'.tr,
                value: '{n} Ballons'.trArgs({'n': challenge.entryCost}),
              ),
              _InfoStat(
                label: 'À gagner'.tr,
                value: '{n} Ballons'.trArgs({'n': challenge.entryCost * 2}),
              ),
              _InfoStat(label: 'Joueurs'.tr, value: '${challenge.participantsCount}/2'),
            ],
          ),
        ] else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoStat(
                label: 'Entrée'.tr,
                value: '{n} Ballons'.trArgs({'n': challenge.entryCost}),
              ),
              _InfoStat(
                label: 'Cagnotte'.tr,
                value: '{n} Ballons'.trArgs({'n': challenge.prizePool}),
              ),
              _InfoStat(
                label: 'Participants'.tr,
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
        else if (challenge.status == 'active' && !hasJoined && !challenge.hasEnded)
          if (!challenge.hasStarted)
            AppPrimaryButton(
              label: 'Ouvre le {date}'.trArgs({'date': DateTimeField.format(challenge.startDate.toLocal())}),
              icon: Icons.schedule,
              onPressed: null,
            )
          else if (challenge.isBattle)
            if (challenge.isFull ||
                (challenge.opponentId != null && challenge.opponentId != myProfile?.id))
              const SizedBox.shrink()
            else
              AppPrimaryButton(
                label: 'Relever la Battle ({n} Ballons)'.trArgs({'n': challenge.entryCost}),
                icon: Icons.sports_mma,
                onPressed: () => _openParticipateSheet(context, ref, challenge),
              )
          else
            AppPrimaryButton(
              label: challenge.type == 'sponsored' || challenge.entryCost == 0
                  ? 'Participer gratuitement'.tr
                  : 'Participer ({n} Ballons)'.trArgs({'n': challenge.entryCost}),
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
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Tu participes à ce défi.'.tr),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          challenge.isBattle ? 'Les vidéos — vote pour la meilleure'.tr : 'Participants'.tr,
          style: context.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        participationsAsync.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => Text(
            error is Failure ? error.message : 'Erreur de chargement.'.tr,
          ),
          data: (participations) {
            if (participations.isEmpty) {
              return Text(
                'Aucun participant pour l\'instant.'.tr,
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

    final video = await MyVideoPickerSheet.show(context, myProfile.id);
    if (video == null || !context.mounted) return;
    final videoId = video.id;

    final success = await ref
        .read(challengeActionsControllerProvider.notifier)
        .join(challengeId: challenge.id, videoId: videoId);

    if (!context.mounted) return;
    if (success) {
      context.showSnackBar(
        challenge.isBattle ? 'Battle relevée ! ⚔️'.tr : 'Tu participes au défi !'.tr,
      );
    } else {
      final failure = ref.read(challengeActionsControllerProvider).error;
      context.showSnackBar(
        failure is Failure ? failure.message : 'Échec de la participation.'.tr,
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
                : 'Aucun record'.tr,
            style: AppTypography.stat(fontSize: 24, color: AppColors.gold),
          ),
          Text(
            challenge.recordHolder != null
                ? 'par @{user}'.trArgs({'user': challenge.recordHolder!.username})
                : 'Sois le premier à établir un record !'.tr,
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
      text = ('Défi gratuit proposé par une marque partenaire : aucun Ballon '
              'n\'est débité ni distribué. Le vainqueur (le plus de votes, '
              'égalité départagée par ordre d\'inscription) reçoit le prix '
              'décrit ci-dessus, remis directement par la marque.')
          .tr;
    } else if (challenge.isBattle) {
      text = ('Battle 1 contre 1 : chaque joueur mise {stake} Ballons. '
              'Les autres utilisateurs regardent les deux vidéos et votent (un vote '
              'par personne, les deux joueurs ne votent pas). Le gagnant remporte les '
              '{prize} Ballons et +100 Stars. Égalité, aucun vote ou '
              'personne en face : chacun récupère sa mise.')
          .trArgs({'stake': challenge.entryCost, 'prize': challenge.entryCost * 2});
    } else if (challenge.type == 'king') {
      text = ('Le Roi en titre remporte la cagnotte s\'il n\'est pas '
              'détrôné avant la fin du défi. Chaque tentative pour le '
              'détrôner coûte {cost} Ballons, qui rejoignent '
              'la cagnotte.')
          .trArgs({'cost': challenge.entryCost});
    } else {
      text = ('Ouvert à tous du {start} '
              'au {end}. Chaque droit '
              'd\'entrée ({cost} Ballons) rejoint la cagnotte. Le '
              'participant avec le plus de votes la remporte en entier (égalité : '
              'le premier inscrit). Aucun vote : chacun est remboursé.')
          .trArgs({
        'start': DateTimeField.format(challenge.startDate.toLocal()),
        'end': DateTimeField.format(challenge.endDate.toLocal()),
        'cost': challenge.entryCost,
      });
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
          // Toucher la miniature ouvre la vidéo : on vote après l'avoir vue.
          GestureDetector(
            onTap: () => context.push(RouteNames.videoDetailPath(participation.videoId)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              child: SizedBox(
                width: 56,
                height: 74,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (participation.videoThumbnailUrl != null)
                      Image.network(participation.videoThumbnailUrl!, fit: BoxFit.cover)
                    else
                      const ColoredBox(color: AppColors.surface),
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 26),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${participation.participant?.username ?? 'inconnu'.tr}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (participation.rank != null)
                  Text(
                    'Rang #{rank}'.trArgs({'rank': participation.rank}),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (challenge.status == 'active' &&
              !(challenge.isBattle && challenge.participantsCount < 2))
            OutlinedButton.icon(
              // Le thème impose une largeur infinie aux boutons (pleine
              // largeur par défaut) : dans une Row, ça écrasait le pseudo
              // du participant à 0 px de large (une lettre par ligne).
              style: OutlinedButton.styleFrom(minimumSize: const Size(72, 40)),
              onPressed: participation.hasVoted ? null : () => _vote(context, ref),
              icon: Icon(
                participation.hasVoted ? Icons.how_to_vote : Icons.how_to_vote_outlined,
                size: 16,
              ),
              label: Text('${participation.votesCount}'),
            )
          else if (challenge.status == 'active')
            Text('En attente'.tr, style: Theme.of(context).textTheme.bodySmall)
          else
            Text(
              '{n} votes'.trArgs({'n': participation.votesCount}),
              style: AppTypography.stat(fontSize: 13),
            ),
        ],
      ),
    );
  }

  Future<void> _vote(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(challengeActionsControllerProvider.notifier).vote(
          challengeId: challenge.id,
          participantUserId: participation.userId,
        );
    if (!context.mounted) return;
    if (ok) {
      context.showSnackBar('Vote enregistré 🗳️'.tr);
    } else {
      final failure = ref.read(challengeActionsControllerProvider).error;
      context.showSnackBar(
        failure is Failure ? failure.message : 'Vote impossible.'.tr,
        isError: true,
      );
    }
  }
}

/// « @joueur1 VS @joueur2 » en haut d'une Battle.
class _BattleVersus extends StatelessWidget {
  const _BattleVersus({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final creator = challenge.creator?.username;
    final opponent = challenge.opponent?.username;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '@${creator ?? '?'}',
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('VS', style: AppTypography.stat(fontSize: 22, color: AppColors.gold)),
          Expanded(
            child: Text(
              opponent != null ? '@$opponent' : 'Adversaire à trouver'.tr,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: opponent != null ? null : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
