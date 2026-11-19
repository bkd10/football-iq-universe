/// Protection des mineurs, côté appli. La vérité reste toujours sur le
/// serveur (`20260101000037_minor_safety.sql`) : l'appli ne fait qu'afficher
/// et prévenir avant d'envoyer.
library;

/// Règles d'âge lues dans `app_config.legal` (fonction `get_age_rules`).
/// Les valeurs par défaut ne servent que si le serveur est injoignable.
class AgeRules {
  const AgeRules({
    this.minAge = 13,
    this.adultAge = 18,
    this.parentalConsentUnder = 18,
    this.proMinAge = 18,
    this.countryRules = const {},
  });

  factory AgeRules.fromJson(Map<String, dynamic> j) {
    final raw = j['country_rules'];
    final rules = <String, Map<String, int>>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          rules['$key'.toLowerCase()] = {
            for (final e in value.entries)
              if (e.value is num) '${e.key}': (e.value as num).toInt(),
          };
        }
      });
    }
    int read(String k, int d) => (j[k] as num?)?.toInt() ?? d;
    return AgeRules(
      minAge: read('min_age', 13),
      adultAge: read('adult_age', 18),
      parentalConsentUnder: read('parental_consent_under', 18),
      proMinAge: read('pro_min_age', 18),
      countryRules: rules,
    );
  }

  final int minAge;
  final int adultAge;
  final int parentalConsentUnder;
  final int proMinAge;
  final Map<String, Map<String, int>> countryRules;

  /// Les règles d'un pays (nom ou code, comme sur le serveur).
  AgeRules forCountry(String? country) {
    final rule = countryRules[(country ?? '').trim().toLowerCase()];
    if (rule == null) return this;
    return AgeRules(
      minAge: rule['min_age'] ?? minAge,
      adultAge: rule['adult_age'] ?? adultAge,
      parentalConsentUnder: rule['parental_consent_under'] ?? parentalConsentUnder,
      proMinAge: rule['pro_min_age'] ?? proMinAge,
      countryRules: countryRules,
    );
  }

  static int ageOn(DateTime birth, DateTime today) {
    var age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age;
  }

  bool needsParentalConsent(int age) => age < parentalConsentUnder;

  /// Même contrôle que le serveur (`private.check_age_rules`). Renvoie le
  /// problème (texte source, à traduire avec `.trArgs`) ou `null`.
  AgeProblem? check({required int? age, required String accountType, required bool parentalAttestation}) {
    if (age == null) return const AgeProblem('Indique ta date de naissance.');
    if (age < minAge) {
      return AgeProblem('Il faut avoir au moins {n} ans pour s\'inscrire.', {'n': minAge});
    }
    if (accountType != 'player' && age < proMinAge) {
      return const AgeProblem('Les comptes recruteur et marque sont réservés aux majeurs.');
    }
    if (needsParentalConsent(age) && !parentalAttestation) {
      return const AgeProblem('Coche l\'attestation d\'accord parental pour continuer.');
    }
    return null;
  }
}

class AgeProblem {
  const AgeProblem(this.text, [this.args = const {}]);
  final String text;
  final Map<String, Object?> args;
}

/// Réglages de l'utilisateur connecté (`get_my_safety`).
class MySafety {
  const MySafety({
    this.isMinor = true,
    this.ageKnown = false,
    this.profileVisibility = 'limited',
    this.dmFrom = 'mutual',
    this.allowRandomBattles = false,
    this.showLocation = false,
    this.gentleStreaks = true,
    this.showStreaks = false,
    this.showCountdowns = false,
    this.breakReminderMinutes = 45,
    this.minorPurchases = 'disabled',
    this.canPurchase = false,
    this.purchaseConsentAt,
    this.minorMonthlyLimitCents = 5000,
  });

  factory MySafety.fromJson(Map<String, dynamic> j) => MySafety(
        isMinor: j['is_minor'] as bool? ?? true,
        ageKnown: j['age_known'] as bool? ?? false,
        profileVisibility: j['profile_visibility'] as String? ?? 'limited',
        dmFrom: j['dm_from'] as String? ?? 'mutual',
        allowRandomBattles: j['allow_random_battles'] as bool? ?? false,
        showLocation: j['show_location'] as bool? ?? false,
        gentleStreaks: j['gentle_streaks'] as bool? ?? true,
        showStreaks: j['show_streaks'] as bool? ?? false,
        showCountdowns: j['show_countdowns'] as bool? ?? false,
        breakReminderMinutes: (j['break_reminder_minutes'] as num?)?.toInt() ?? 45,
        minorPurchases: j['minor_purchases'] as String? ?? 'disabled',
        canPurchase: j['can_purchase'] as bool? ?? false,
        purchaseConsentAt: DateTime.tryParse(j['purchase_consent_at'] as String? ?? ''),
        minorMonthlyLimitCents: (j['minor_monthly_limit_cents'] as num?)?.toInt() ?? 5000,
      );

  /// Réglages prudents tant que le serveur n'a pas répondu.
  static const fallback = MySafety();

  final bool isMinor;
  final bool ageKnown;
  final String profileVisibility;
  final String dmFrom;
  final bool allowRandomBattles;
  final bool showLocation;
  final bool gentleStreaks;
  final bool showStreaks;
  final bool showCountdowns;
  final int breakReminderMinutes;
  final String minorPurchases;
  final bool canPurchase;
  final DateTime? purchaseConsentAt;
  final int minorMonthlyLimitCents;

  /// Un mineur ne voit jamais d'incitation à acheter.
  bool get hideShop => isMinor && !canPurchase;
  bool get parentalPurchaseMode => minorPurchases == 'parental_consent';
}

/// Ce que l'appli sait d'un autre profil (`get_public_profile`).
class PublicProfileFlags {
  const PublicProfileFlags({
    this.unavailable = false,
    this.iBlocked = false,
    this.limited = false,
    this.isMutual = false,
    this.canMessage = false,
  });

  factory PublicProfileFlags.fromJson(Map<String, dynamic> j) => PublicProfileFlags(
        unavailable: j['unavailable'] as bool? ?? false,
        iBlocked: j['i_blocked'] as bool? ?? false,
        limited: j['limited'] as bool? ?? false,
        isMutual: j['is_mutual'] as bool? ?? false,
        canMessage: j['can_message'] as bool? ?? false,
      );

  final bool unavailable;
  final bool iBlocked;
  final bool limited;
  final bool isMutual;
  final bool canMessage;
}

class BlockedUser {
  const BlockedUser({required this.userId, required this.username, required this.blockedAt});

  factory BlockedUser.fromJson(Map<String, dynamic> j) => BlockedUser(
        userId: j['user_id'] as String,
        username: j['username'] as String? ?? '',
        blockedAt: DateTime.tryParse(j['blocked_at'] as String? ?? '') ?? DateTime.now(),
      );

  final String userId;
  final String username;
  final DateTime blockedAt;
}
