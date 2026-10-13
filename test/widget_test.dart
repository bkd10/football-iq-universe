// Smoke test minimal : le test généré par `flutter create` référence un
// widget `MyApp` qui n'existe pas dans ce projet (notre app s'appelle
// `FootballIqUniverseApp` et nécessite Supabase/ProviderScope au
// démarrage). Remplacé par un test réel sur une fonction pure, en
// attendant une vraie suite de tests d'intégration.

import 'package:flutter_test/flutter_test.dart';

import 'package:football_iq_universe/core/utils/formatters.dart';
import 'package:football_iq_universe/core/utils/validators.dart';

void main() {
  group('Formatters.compactCount', () {
    test('garde les petits nombres tels quels', () {
      expect(Formatters.compactCount(950), '950');
    });

    test('compacte les milliers en K', () {
      expect(Formatters.compactCount(12400), '12.4K');
    });

    test('compacte les millions en M', () {
      expect(Formatters.compactCount(3400000), '3.4M');
    });
  });

  group('Validators.email', () {
    test('rejette un email vide', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejette un email mal formé', () {
      expect(Validators.email('pas-un-email'), isNotNull);
    });

    test('accepte un email valide', () {
      expect(Validators.email('joueur@footballiq.app'), isNull);
    });
  });
}
