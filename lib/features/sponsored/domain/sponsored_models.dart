/// Défi sponsorisé dans le fil et bouton Voter des vidéos de défi
/// (`20260101000038_sponsored_feed_votes.sql`).
library;

/// Réglage du fil : une carte « Sponsorisé » toutes les [everyN] vidéos.
class SponsoredFeedConfig {
  const SponsoredFeedConfig({this.enabled = true, this.everyN = 6});

  factory SponsoredFeedConfig.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SponsoredFeedConfig();
    final n = (j['every_n'] as num?)?.toInt() ?? 6;
    return SponsoredFeedConfig(
      enabled: j['enabled'] as bool? ?? true,
      everyN: n.clamp(minEveryN, maxEveryN),
    );
  }

  static const minEveryN = 2;
  static const maxEveryN = 50;

  final bool enabled;
  final int everyN;
}

/// Un défi sponsorisé tel que montré dans le fil. Le serveur renvoie la même
/// liste à tout le monde : aucune donnée du joueur ne sert à la choisir.
class SponsoredFeedChallenge {
  const SponsoredFeedChallenge({
    required this.id,
    required this.title,
    required this.sponsorName,
    required this.startDate,
    required this.endDate,
    this.description = '',
    this.sponsorLogoUrl,
    this.participantsCount = 0,
    this.entryCost = 0,
    this.rewardStars = 100,
    this.prizeDescription,
    this.hasJoined = false,
  });

  factory SponsoredFeedChallenge.fromJson(Map<String, dynamic> j) => SponsoredFeedChallenge(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        sponsorName: j['sponsor_name'] as String? ?? '',
        sponsorLogoUrl: j['sponsor_logo_url'] as String?,
        startDate: DateTime.parse(j['start_date'] as String),
        endDate: DateTime.parse(j['end_date'] as String),
        participantsCount: (j['participants_count'] as num?)?.toInt() ?? 0,
        entryCost: (j['entry_cost'] as num?)?.toInt() ?? 0,
        rewardStars: (j['reward_stars'] as num?)?.toInt() ?? 100,
        prizeDescription: j['prize_description'] as String?,
        hasJoined: j['has_joined'] as bool? ?? false,
      );

  final String id;
  final String title;
  final String description;
  final String sponsorName;
  final String? sponsorLogoUrl;
  final DateTime startDate;
  final DateTime endDate;
  final int participantsCount;
  final int entryCost;
  final int rewardStars;
  final String? prizeDescription;
  final bool hasJoined;

  bool hasStartedAt(DateTime now) => !now.isBefore(startDate);
}

/// Un élément du fil : une vidéo (indice dans la liste des vidéos) ou une
/// carte de défi sponsorisé.
sealed class FeedSlot {
  const FeedSlot();
}

class VideoSlot extends FeedSlot {
  const VideoSlot(this.videoIndex);
  final int videoIndex;
}

class SponsoredSlot extends FeedSlot {
  const SponsoredSlot(this.challengeIndex);
  final int challengeIndex;
}

/// Mélange le fil : après chaque groupe de [everyN] vidéos, une carte
/// sponsorisée (les défis tournent s'il y en a plusieurs). Jamais en
/// premier ni deux de suite ; fil plus court que N : une fois, à la fin.
List<FeedSlot> buildFeedSlots({
  required int videoCount,
  required int sponsoredCount,
  required int everyN,
  bool enabled = true,
}) {
  final slots = <FeedSlot>[];
  final n = everyN.clamp(SponsoredFeedConfig.minEveryN, SponsoredFeedConfig.maxEveryN);
  var shown = 0;
  for (var i = 0; i < videoCount; i++) {
    slots.add(VideoSlot(i));
    final placed = i + 1;
    if (enabled && sponsoredCount > 0 && placed % n == 0 && placed < videoCount) {
      slots.add(SponsoredSlot(shown % sponsoredCount));
      shown++;
    }
  }
  // Fil plus court que N vidéos : la carte apparaît une fois, à la fin.
  if (enabled && sponsoredCount > 0 && shown == 0 && videoCount > 0) {
    slots.add(const SponsoredSlot(0));
  }
  return slots;
}

/// La place d'une vidéo dans un défi en cours, pour le bouton Voter.
class VideoChallengeEntry {
  const VideoChallengeEntry({
    required this.videoId,
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeType,
    required this.participantId,
    required this.startDate,
    required this.endDate,
    this.isSponsored = false,
    this.votesCount = 0,
    this.battleReady = true,
    this.myVoteParticipantId,
    this.isMine = false,
    this.iAmBattlePlayer = false,
  });

  factory VideoChallengeEntry.fromJson(Map<String, dynamic> j) => VideoChallengeEntry(
        videoId: j['video_id'] as String,
        challengeId: j['challenge_id'] as String,
        challengeTitle: j['challenge_title'] as String? ?? '',
        challengeType: j['challenge_type'] as String? ?? 'challenge',
        isSponsored: j['is_sponsored'] as bool? ?? false,
        participantId: j['participant_id'] as String,
        votesCount: (j['votes_count'] as num?)?.toInt() ?? 0,
        startDate: DateTime.parse(j['start_date'] as String),
        endDate: DateTime.parse(j['end_date'] as String),
        battleReady: j['battle_ready'] as bool? ?? true,
        myVoteParticipantId: j['my_vote_participant_id'] as String?,
        isMine: j['is_mine'] as bool? ?? false,
        iAmBattlePlayer: j['i_am_battle_player'] as bool? ?? false,
      );

  final String videoId;
  final String challengeId;
  final String challengeTitle;
  final String challengeType;
  final bool isSponsored;
  final String participantId;
  final int votesCount;
  final DateTime startDate;
  final DateTime endDate;
  final bool battleReady;
  final String? myVoteParticipantId;
  final bool isMine;
  final bool iAmBattlePlayer;

  VoteButtonState stateAt(DateTime now, {required bool signedIn}) {
    if (!signedIn) return VoteButtonState.signIn;
    if (myVoteParticipantId == participantId) return VoteButtonState.votedHere;
    if (myVoteParticipantId != null) return VoteButtonState.votedElsewhere;
    if (isMine) return VoteButtonState.ownVideo;
    if (now.isBefore(startDate)) return VoteButtonState.notStarted;
    if (now.isAfter(endDate)) return VoteButtonState.ended;
    if (!battleReady) return VoteButtonState.waitingOpponent;
    if (iAmBattlePlayer) return VoteButtonState.battlePlayer;
    return VoteButtonState.open;
  }

  VideoChallengeEntry withMyVote(String participantId) => VideoChallengeEntry(
        videoId: videoId,
        challengeId: challengeId,
        challengeTitle: challengeTitle,
        challengeType: challengeType,
        isSponsored: isSponsored,
        participantId: this.participantId,
        votesCount: participantId == this.participantId ? votesCount + 1 : votesCount,
        startDate: startDate,
        endDate: endDate,
        battleReady: battleReady,
        myVoteParticipantId: participantId,
        isMine: isMine,
        iAmBattlePlayer: iAmBattlePlayer,
      );
}

/// Ce que montre le bouton Voter. Seul [open] permet de voter ; les autres
/// états affichent la raison (le serveur refuse de toute façon).
enum VoteButtonState {
  open,
  votedHere,
  votedElsewhere,
  ownVideo,
  notStarted,
  ended,
  waitingOpponent,
  battlePlayer,
  signIn,
}

/// Entrée la plus utile pour une vidéo dans plusieurs défis : celui où l'on
/// peut voter, sinon le premier qui se termine.
VideoChallengeEntry? pickEntry(List<VideoChallengeEntry> entries, DateTime now) {
  if (entries.isEmpty) return null;
  for (final e in entries) {
    if (e.stateAt(now, signedIn: true) == VoteButtonState.open) return e;
  }
  return entries.first;
}
