import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../domain/entities/challenge.dart';

const challengeTypeLabels = {
  'battle': '⚔️ Battle',
  'challenge': '🎯 Challenge',
  'king': '👑 King',
  'world': '🌍 Défi Monde',
  'sponsored': '💼 Sponsorisé',
};

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({required this.challenge, this.onTap, super.key});

  final Challenge challenge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isKing = challenge.type == 'king';
    final isSponsored = challenge.type == 'sponsored';
    final isCompleted = challenge.status == 'completed' || challenge.status == 'cancelled';

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                challengeTypeLabels[challenge.type]?.tr ?? challenge.type,
                style: const TextStyle(
                  color: AppColors.diamond,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isCompleted)
                Text(
                  'TERMINÉ'.tr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  challenge.hasStarted
                      ? Formatters.countdown(challenge.timeRemaining)
                      : 'Dans {time}'.trArgs({'time': Formatters.countdown(challenge.timeUntilStart)}),
                  style: AppTypography.stat(fontSize: 12, color: AppColors.gold),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            challenge.title,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (isSponsored && challenge.sponsorName != null) ...[
            Text(
              'Par {sponsor}'.trArgs({'sponsor': challenge.sponsorName}),
              style: const TextStyle(color: AppColors.diamond, fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (challenge.isBattle)
            Text(
              '@{creator} VS {opponent} · mise {stake} Ballons'.trArgs({
                'creator': challenge.creator?.username ?? '?',
                'opponent': challenge.opponent != null
                    ? '@${challenge.opponent!.username}'
                    : 'adversaire à trouver'.tr,
                'stake': challenge.entryCost,
              }),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else if (isKing)
            Text(
              challenge.currentRecord != null
                  ? 'Record : {record} {unit} — @{holder}'.trArgs({
                      'record': challenge.currentRecord,
                      'unit': challenge.recordUnit ?? '',
                      'holder': challenge.recordHolder?.username ?? '?',
                    })
                  : 'Aucun record établi — sois le premier !'.tr,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (isSponsored)
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '{n} participants · gratuit'.trArgs({'n': challenge.participantsCount}),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (challenge.prizeDescription != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.card_giftcard, size: 14, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      challenge.prizeDescription!,
                      style: const TextStyle(color: AppColors.gold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '{n} participants'.trArgs({
                    'n': '${challenge.participantsCount}'
                        '${challenge.maxParticipants != null ? '/${challenge.maxParticipants}' : ''}',
                  }),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (challenge.entryCost > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '· {n} Ballons pour participer'.trArgs({'n': challenge.entryCost}),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (challenge.prizePool > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.paid_outlined, size: 14, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    'Cagnotte : {n} Ballons'.trArgs({'n': challenge.prizePool}),
                    style: const TextStyle(color: AppColors.gold, fontSize: 12),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
