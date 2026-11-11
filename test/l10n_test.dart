import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_iq_universe/core/l10n/l10n.dart';

void main() {
  tearDown(() => L10n.setLanguage('fr'));

  test('langue du téléphone non prise en charge : anglais', () {
    L10n.init(const [Locale('ja')]);
    expect(L10n.language, 'en');
    expect('Vérifie ta connexion internet.'.tr, isNot('Vérifie ta connexion internet.'));
  });

  test('téléphone en français : texte source', () {
    L10n.init(const [Locale('fr', 'FR')]);
    expect('Vérifie ta connexion internet.'.tr, 'Vérifie ta connexion internet.');
  });

  test('texte serveur avec un pseudo', () {
    L10n.setLanguage('en');
    final text = '@jibril a aimé ta vidéo.'.trServer;
    expect(text, contains('jibril'));
    expect(text, isNot(contains('aimé')));
  });

  test('notification « Nouveau challenge » traduite dans chaque langue', () {
    for (final lang in L10n.supportedLanguages.where((l) => l != 'fr')) {
      L10n.setLanguage(lang);
      expect('Nouveau challenge ! 🏆'.trServer, isNot('Nouveau challenge ! 🏆'), reason: lang);
      final body = '« Défi du 10 novembre » est lancé : à toi de jouer !'.trServer;
      expect(body, contains('Défi du 10 novembre'), reason: lang);
      expect(body, isNot(contains('à toi de jouer')), reason: lang);
    }
  });

  test('participation sans vidéo : textes traduits dans chaque langue', () {
    for (final lang in L10n.supportedLanguages.where((l) => l != 'fr')) {
      L10n.setLanguage(lang);
      expect('Envoyer ma vidéo'.tr, isNot('Envoyer ma vidéo'), reason: lang);
      expect('Participation validée ✅'.trServer, isNot('Participation validée ✅'), reason: lang);
      final body =
          'Envoie ta vidéo pour « But contre Metz » avant la date limite (48 h maximum).'.trServer;
      expect(body, contains('But contre Metz'), reason: lang);
      expect(body, isNot(contains('Envoie ta vidéo')), reason: lang);
      expect(
        "Ce joueur n'a pas encore envoyé sa vidéo.".trServer,
        isNot("Ce joueur n'a pas encore envoyé sa vidéo."),
        reason: lang,
      );
    }
  });

  test('chaque langue traduit les textes', () {
    for (final lang in L10n.supportedLanguages.where((l) => l != 'fr')) {
      L10n.setLanguage(lang);
      expect(
        'Vérifie ta connexion internet.'.tr,
        isNot('Vérifie ta connexion internet.'),
        reason: lang,
      );
      expect('@jibril a aimé ta vidéo.'.trServer, contains('jibril'), reason: lang);
      expect('@jibril a aimé ta vidéo.'.trServer, isNot(contains('aimé')), reason: lang);
    }
  });

  test('téléphone en arabe : arabe', () {
    L10n.init(const [Locale('ar', 'MA')]);
    expect(L10n.language, 'ar');
  });
}
