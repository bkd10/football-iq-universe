import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_iq_universe/core/l10n/l10n.dart';
import 'package:football_iq_universe/core/l10n/strings/registry.dart';
import 'package:football_iq_universe/features/safety/domain/safety_models.dart';

void main() {
  tearDown(() => L10n.setLanguage('fr'));

  group('âge à l\'inscription (mêmes règles que le serveur)', () {
    const rules = AgeRules(
      minAge: 13,
      countryRules: {
        'france': {'min_age': 15},
      },
    );

    test('âge calculé au jour près', () {
      final today = DateTime(2026, 11, 19);
      expect(AgeRules.ageOn(DateTime(2013, 11, 19), today), 13);
      expect(AgeRules.ageOn(DateTime(2013, 11, 20), today), 12);
    });

    test('inscription refusée sous l\'âge minimum, avec le bon âge dans le message', () {
      final p = rules.check(age: 12, accountType: 'player', parentalAttestation: true);
      expect(p, isNotNull);
      expect(p!.text, 'Il faut avoir au moins {n} ans pour s\'inscrire.');
      expect(p.args['n'], 13);
    });

    test('âge minimum réglable par pays', () {
      final fr = rules.forCountry('France');
      expect(fr.minAge, 15);
      expect(fr.check(age: 14, accountType: 'player', parentalAttestation: true), isNotNull);
      expect(rules.check(age: 14, accountType: 'player', parentalAttestation: true), isNull);
    });

    test('mineur : accord parental obligatoire, comptes pro réservés aux majeurs', () {
      expect(rules.check(age: 16, accountType: 'player', parentalAttestation: false), isNotNull);
      expect(rules.check(age: 16, accountType: 'player', parentalAttestation: true), isNull);
      expect(rules.check(age: 17, accountType: 'scout', parentalAttestation: true), isNotNull);
      expect(rules.check(age: 18, accountType: 'brand', parentalAttestation: false), isNull);
      expect(rules.check(age: null, accountType: 'player', parentalAttestation: true), isNotNull);
    });

    test('règles lues depuis le serveur', () {
      final r = AgeRules.fromJson({
        'min_age': 16,
        'adult_age': 18,
        'country_rules': {
          'GB': {'min_age': 13},
        },
      });
      expect(r.minAge, 16);
      expect(r.forCountry('gb').minAge, 13);
    });
  });

  group('réglages par défaut', () {
    test('serveur injoignable : réglages les plus protecteurs', () {
      const s = MySafety.fallback;
      expect(s.isMinor, isTrue);
      expect(s.dmFrom, 'mutual');
      expect(s.profileVisibility, 'limited');
      expect(s.allowRandomBattles, isFalse);
      expect(s.showLocation, isFalse);
      expect(s.hideShop, isTrue);
    });

    test('mineur sans accord : boutique cachée ; majeur : boutique visible', () {
      expect(MySafety.fromJson({'is_minor': true, 'can_purchase': false}).hideShop, isTrue);
      expect(MySafety.fromJson({'is_minor': true, 'can_purchase': true}).hideShop, isFalse);
      expect(MySafety.fromJson({'is_minor': false, 'can_purchase': true}).hideShop, isFalse);
    });
  });

  test('les nouveaux textes « mineurs » sont traduits dans les 9 langues', () {
    // Toutes les clés de la table anglaise doivent exister partout.
    final en = translationTable('en');
    const samples = [
      'Sécurité et confidentialité',
      'Bloquer ce joueur',
      'Les achats de Ballons sont désactivés pour les moins de 18 ans.',
      'Messages privés seulement entre abonnés mutuels.',
      'Confirme que tu as le droit de publier cette vidéo.',
      'Et si tu faisais une pause ?',
    ];
    for (final s in samples) {
      expect(en.containsKey(s), isTrue, reason: s);
    }
    for (final lang in L10n.supportedLanguages.where((l) => l != 'fr')) {
      L10n.setLanguage(lang);
      expect('Bloquer ce joueur'.tr, isNot('Bloquer ce joueur'), reason: lang);
      expect('Il faut avoir au moins 15 ans pour s\'inscrire.'.trServer, contains('15'), reason: lang);
      expect('Il faut avoir au moins 15 ans pour s\'inscrire.'.trServer, isNot(contains('inscrire')), reason: lang);
    }
  });

  test('chaque texte serveur des mineurs a une traduction', () {
    final sql = File('supabase/migrations/20260101000037_minor_safety.sql').readAsStringSync();
    final en = translationTable('en');
    final texts = RegExp(r"return '([^']*(?:''[^']*)*)';").allMatches(sql).map((m) => m.group(1)!.replaceAll("''", "'"));
    for (final t in texts.where((t) => t.endsWith('.'))) {
      expect(en.containsKey(t), isTrue, reason: t);
    }
  });
}
