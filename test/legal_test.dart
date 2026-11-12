import 'package:flutter_test/flutter_test.dart';
import 'package:football_iq_universe/core/l10n/l10n.dart';
import 'package:football_iq_universe/features/legal/presentation/screens/legal_screen.dart';

void main() {
  tearDown(() => L10n.setLanguage('fr'));

  test('chaque document légal a une adresse distincte et un texte complet', () {
    final slugs = LegalDoc.values.map((d) => d.slug).toSet();
    expect(slugs.length, LegalDoc.values.length);
    for (final lang in ['fr', 'en']) {
      L10n.setLanguage(lang);
      for (final doc in LegalDoc.values) {
        expect(doc.body, isNotEmpty, reason: '${doc.slug} $lang');
        // Aucun {champ} oublié dans le texte.
        expect(RegExp(r'\{[a-z_]+\}').hasMatch(doc.body), isFalse, reason: '${doc.slug} $lang');
        expect(LegalDoc.fromSlug(doc.slug), doc);
      }
    }
  });

  test('les documents obligatoires existent', () {
    expect(
      LegalDoc.values.map((d) => d.slug),
      containsAll(['mentions-legales', 'cgu', 'confidentialite', 'cookies', 'regles-ballons']),
    );
  });

  test('titres des documents et textes de conformité traduits partout', () {
    const samples = [
      'Mentions légales',
      'Mes données',
      'Règles des Ballons et remboursements',
      'Progresse, prouve, fais-toi remarquer',
      'Un recruteur souhaite contacter un joueur mineur.',
    ];
    for (final lang in L10n.supportedLanguages.where((l) => l != 'fr')) {
      L10n.setLanguage(lang);
      for (final s in samples) {
        expect(s.tr, isNot(s), reason: '$lang : $s');
      }
    }
  });
}
