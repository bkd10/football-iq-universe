import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_iq_universe/core/l10n/l10n.dart';
import 'package:football_iq_universe/core/l10n/strings/sponsored.dart';
import 'package:football_iq_universe/features/safety/domain/safety_models.dart';
import 'package:football_iq_universe/features/safety/presentation/providers/safety_providers.dart';
import 'package:football_iq_universe/features/sponsored/domain/sponsored_models.dart';
import 'package:football_iq_universe/features/sponsored/presentation/providers/sponsored_providers.dart';
import 'package:football_iq_universe/features/sponsored/presentation/widgets/challenge_vote_button.dart';
import 'package:football_iq_universe/features/sponsored/presentation/widgets/sponsored_challenge_card.dart';

final _now = DateTime(2026, 11, 20, 12);

VideoChallengeEntry _entry({
  String participant = 'p1',
  DateTime? start,
  DateTime? end,
  String? myVote,
  bool mine = false,
  bool battleReady = true,
  bool battlePlayer = false,
}) =>
    VideoChallengeEntry(
      videoId: 'v1',
      challengeId: 'c1',
      challengeTitle: 'Défi Passe D',
      challengeType: 'sponsored',
      isSponsored: true,
      participantId: participant,
      votesCount: 7,
      startDate: start ?? _now.subtract(const Duration(days: 1)),
      endDate: end ?? _now.add(const Duration(days: 3)),
      myVoteParticipantId: myVote,
      isMine: mine,
      battleReady: battleReady,
      iAmBattlePlayer: battlePlayer,
    );

void main() {
  tearDown(() => L10n.setLanguage('fr'));

  group('carte du défi insérée dans le fil à la bonne fréquence', () {
    test('une carte après chaque groupe de N vidéos, jamais en premier', () {
      final slots = buildFeedSlots(videoCount: 20, sponsoredCount: 1, everyN: 6);
      final positions = [
        for (var i = 0; i < slots.length; i++)
          if (slots[i] is SponsoredSlot) i,
      ];
      // 6 vidéos, carte, 6 vidéos, carte, 6 vidéos, carte, 2 vidéos.
      expect(positions, [6, 13, 20]);
      expect(slots.whereType<VideoSlot>().length, 20);
      expect(slots.first, isA<VideoSlot>());
    });

    test('N réglable (panneau admin)', () {
      final slots = buildFeedSlots(videoCount: 9, sponsoredCount: 1, everyN: 3);
      final kinds = slots.map((s) => s is SponsoredSlot ? 'S' : 'v').join();
      expect(kinds, 'vvvSvvvSvvv');
    });

    test('jamais deux cartes de suite ; plusieurs défis tournent', () {
      final slots = buildFeedSlots(videoCount: 12, sponsoredCount: 2, everyN: 2);
      for (var i = 1; i < slots.length; i++) {
        expect(slots[i] is SponsoredSlot && slots[i - 1] is SponsoredSlot, isFalse);
      }
      final order = slots.whereType<SponsoredSlot>().map((s) => s.challengeIndex).toList();
      expect(order, [0, 1, 0, 1, 0]);
    });

    test('fil plus court que N : une carte, à la fin', () {
      final slots = buildFeedSlots(videoCount: 4, sponsoredCount: 1, everyN: 6);
      expect(slots.length, 5);
      expect(slots.last, isA<SponsoredSlot>());
    });

    test('aucun défi actif, ou réglage coupé : que des vidéos', () {
      expect(buildFeedSlots(videoCount: 20, sponsoredCount: 0, everyN: 6).whereType<SponsoredSlot>(), isEmpty);
      expect(
        buildFeedSlots(videoCount: 20, sponsoredCount: 1, everyN: 6, enabled: false).whereType<SponsoredSlot>(),
        isEmpty,
      );
    });

    test('N hors limites ramené entre 2 et 50', () {
      expect(SponsoredFeedConfig.fromJson({'every_n': 0}).everyN, 2);
      expect(SponsoredFeedConfig.fromJson({'every_n': 500}).everyN, 50);
      expect(SponsoredFeedConfig.fromJson(null).everyN, 6);
    });
  });

  group('état du bouton Voter (mêmes règles que le serveur)', () {
    test('ouvert pendant le défi', () {
      expect(_entry().stateAt(_now, signedIn: true), VoteButtonState.open);
    });
    test('avant le début : « Votes dès le … »', () {
      final e = _entry(start: _now.add(const Duration(hours: 5)));
      expect(e.stateAt(_now, signedIn: true), VoteButtonState.notStarted);
    });
    test('après la fin : fermé', () {
      final e = _entry(end: _now.subtract(const Duration(minutes: 1)));
      expect(e.stateAt(_now, signedIn: true), VoteButtonState.ended);
    });
    test('pas pour sa propre vidéo', () {
      expect(_entry(mine: true).stateAt(_now, signedIn: true), VoteButtonState.ownVideo);
    });
    test('un seul vote par défi : déjà voté ici, ou pour une autre vidéo', () {
      expect(_entry(myVote: 'p1').stateAt(_now, signedIn: true), VoteButtonState.votedHere);
      expect(_entry(myVote: 'p2').stateAt(_now, signedIn: true), VoteButtonState.votedElsewhere);
      final after = _entry().withMyVote('p1');
      expect(after.votesCount, 8);
      expect(after.stateAt(_now, signedIn: true), VoteButtonState.votedHere);
    });
    test('non connecté', () {
      expect(_entry().stateAt(_now, signedIn: false), VoteButtonState.signIn);
    });
    test('Battle : attente de l\'adversaire, joueurs de la Battle', () {
      expect(_entry(battleReady: false).stateAt(_now, signedIn: true), VoteButtonState.waitingOpponent);
      expect(_entry(battlePlayer: true).stateAt(_now, signedIn: true), VoteButtonState.battlePlayer);
    });
    test('vidéo dans plusieurs défis : celui où l\'on peut voter', () {
      final closed = _entry(end: _now.subtract(const Duration(days: 1)));
      final open = _entry(participant: 'p1');
      expect(pickEntry([closed, open], _now), same(open));
      expect(pickEntry([], _now), isNull);
    });
  });

  group('bouton Voter visible sur chaque vidéo de défi, absent des autres', () {
    Widget app(Map<String, List<VideoChallengeEntry>> entries, {bool signedIn = true}) => ProviderScope(
          overrides: [
            videoChallengeEntriesProvider.overrideWith((ref, id) async => entries[id] ?? const []),
            voteSignedInProvider.overrideWithValue(signedIn),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ChallengeVoteButton(videoId: 'v1'),
                  ChallengeVoteButton(videoId: 'v2'),
                  ChallengeVoteButton(videoId: 'v3', compact: true),
                ],
              ),
            ),
          ),
        );

    testWidgets('vidéo de défi : Voter, nom du défi, votes ; vidéo hors défi : rien', (tester) async {
      final open = VideoChallengeEntry(
        videoId: 'v1',
        challengeId: 'c1',
        challengeTitle: 'Défi Passe D',
        challengeType: 'sponsored',
        isSponsored: true,
        participantId: 'p1',
        votesCount: 12,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
      );
      await tester.pumpWidget(app({'v1': [open]}));
      await tester.pumpAndSettle();
      expect(find.text('Voter'), findsOneWidget);
      expect(find.text('Défi Passe D'), findsOneWidget);
      expect(find.text('12 votes'), findsOneWidget);
      expect(find.text('Sponsorisé'), findsOneWidget);
      // v2 et v3 ne sont dans aucun défi : pas de bouton.
      expect(find.byIcon(Icons.how_to_vote_outlined), findsOneWidget);
    });

    testWidgets('avant le début : « Votes dès le … » à la place de Voter', (tester) async {
      final soon = VideoChallengeEntry(
        videoId: 'v1',
        challengeId: 'c1',
        challengeTitle: 'Défi Passe D',
        challengeType: 'sponsored',
        participantId: 'p1',
        startDate: DateTime(2030, 1, 15, 18),
        endDate: DateTime(2030, 2, 1),
      );
      await tester.pumpWidget(app({'v1': [soon]}));
      await tester.pumpAndSettle();
      expect(find.text('Voter'), findsNothing);
      expect(find.textContaining('Votes dès le 15/01'), findsOneWidget);
    });

    testWidgets('déjà voté : « Ton vote ✓ »', (tester) async {
      final voted = VideoChallengeEntry(
        videoId: 'v1',
        challengeId: 'c1',
        challengeTitle: 'Défi',
        challengeType: 'challenge',
        participantId: 'p1',
        myVoteParticipantId: 'p1',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
      );
      await tester.pumpWidget(app({'v1': [voted]}));
      await tester.pumpAndSettle();
      expect(find.text('Ton vote ✓'), findsOneWidget);
      expect(find.text('Voter'), findsNothing);
    });

    testWidgets('profil (vignette) : petit bouton Voter', (tester) async {
      final open = VideoChallengeEntry(
        videoId: 'v3',
        challengeId: 'c1',
        challengeTitle: 'Défi',
        challengeType: 'challenge',
        participantId: 'p1',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
      );
      await tester.pumpWidget(app({'v3': [open]}));
      await tester.pumpAndSettle();
      expect(find.text('Voter'), findsOneWidget);
    });
  });

  group('carte « Sponsorisé » du fil', () {
    final challenge = SponsoredFeedChallenge(
      id: 'c1',
      title: 'Défi Passe D',
      description: 'Ta plus belle passe décisive.',
      sponsorName: 'Passe D',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 10)),
      participantsCount: 42,
    );

    Widget app({bool countdowns = false}) => ProviderScope(
          overrides: [
            mySafetyNowProvider.overrideWithValue(MySafety(showCountdowns: countdowns)),
          ],
          child: MaterialApp(home: Scaffold(body: SponsoredChallengeCard(challenge: challenge))),
        );

    testWidgets('étiquette Sponsorisé, sponsor, participants, Participer, Voir les vidéos', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Sponsorisé'), findsOneWidget);
      expect(find.text('Proposé par Passe D'), findsOneWidget);
      expect(find.text('DÉFI PASSE D'), findsOneWidget);
      expect(find.text('42 participants'), findsOneWidget);
      expect(find.text('Participer'), findsOneWidget);
      expect(find.text('Voir les vidéos'), findsOneWidget);
      expect(find.text('Gratuit, sans achat'), findsOneWidget);
    });

    testWidgets('mode protégé (comptes à rebours coupés) : date fixe', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.textContaining('Début le'), findsOneWidget);
      await tester.pumpWidget(app(countdowns: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('Votes dans'), findsOneWidget);
    });

    testWidgets('traduite (anglais)', (tester) async {
      L10n.setLanguage('en');
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
      expect(find.text('See the videos'), findsOneWidget);
    });
  });

  group('traductions', () {
    test('chaque texte existe dans les 9 autres langues', () {
      final fr = sponsoredTranslations['en']!.keys.toSet();
      for (final lang in L10n.supportedLanguages.where((l) => l != 'fr')) {
        expect(sponsoredTranslations[lang]?.keys.toSet(), fr, reason: lang);
        expect(sponsoredServerPatterns[lang], hasLength(2), reason: lang);
      }
    });

    test('chaque refus de vote du serveur a un message clair dans chaque langue', () {
      const refusals = [
        'Connecte-toi pour voter.',
        'Ton compte est suspendu : tu ne peux pas voter.',
        'Tu ne peux pas voter pour toi-même.',
        'Tu as déjà voté dans ce défi.',
        'Les votes de ce défi sont terminés.',
        'Cette vidéo ne peut pas recevoir de votes pour l\'instant.',
        'Trop de votes en peu de temps. Réessaie dans une minute.',
        'Limite de votes du jour atteinte. Réessaie demain.',
        'Les votes ouvrent quand l\'adversaire a relevé la Battle.',
        'Les joueurs de la Battle ne votent pas.',
        'Publie d\'abord une vidéo pour pouvoir voter (ou attends 24 h).',
      ];
      for (final lang in L10n.supportedLanguages.where((l) => l != 'fr')) {
        L10n.setLanguage(lang);
        for (final text in refusals) {
          expect(text.trServer, isNot(text), reason: '$lang : $text');
        }
        final opens = 'Les votes ouvrent le 15/01/2030 18:00.'.trServer;
        expect(opens, contains('15/01/2030 18:00'), reason: lang);
        expect(opens, isNot(contains('ouvrent')), reason: lang);
      }
    });
  });
}
