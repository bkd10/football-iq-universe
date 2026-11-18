import 'package:flutter/foundation.dart' show kIsWeb;

/// Achats de Ballons (Stripe) autorisés seulement sur le site web.
///
/// Google Play (et l'App Store) interdisent d'encaisser des achats virtuels
/// avec un autre moyen de paiement que le leur. Dans les applis mobiles, la
/// boutique est donc masquée : les Ballons se gagnent en jouant.
bool get inAppPurchasesAllowed => kIsWeb;
