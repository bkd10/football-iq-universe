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
