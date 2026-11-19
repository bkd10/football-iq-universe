import '../../../core/l10n/l10n.dart';

/// Informations de la société qui édite l'appli, reprises dans les mentions
/// légales, les CGU, la politique de confidentialité et la page Sécurité.
/// Société britannique : Bkd sport Ltd, Londres. Tant qu'un champ vaut
/// `null`, le texte affiche « [à compléter] » (« [to be completed] » en
/// anglais). À faire valider par un avocat britannique.
class LegalInfo {
  const LegalInfo._();

  static const String companyName = 'Bkd sport Ltd';
  static const String city = 'Londres';
  static const String cityEn = 'London';

  /// Numéro d'immatriculation à Companies House (8 caractères).
  static const String? companyNumber = null;

  /// Lieu d'immatriculation, ex. « Angleterre et pays de Galles ».
  static const String? placeOfRegistration = null;

  /// Adresse complète du siège (registered office), à Londres.
  static const String? registeredOffice = null;

  /// Numéro de TVA britannique (ou « non assujetti »).
  static const String? vatNumber = null;

  /// Numéro d'enregistrement auprès de l'ICO (data protection fee).
  static const String? icoRegistration = null;

  /// E-mail de contact, données personnelles et signalements.
  static const String? contactEmail = null;

  /// E-mail dédié à la sécurité des jeunes (peut être le même).
  static const String? safetyEmail = null;

  /// Représentant dans l'Union européenne (art. 27 RGPD) si l'appli vise
  /// des joueurs de l'UE (France notamment) : nom et adresse.
  static const String? euRepresentative = null;

  /// Organisme de règlement des litiges (ADR) choisi, s'il y en a un.
  static const String? disputeResolution = null;

  static const String termsVersion = '2026-11';

  static const List<String?> _required = [
    companyNumber,
    placeOfRegistration,
    registeredOffice,
    vatNumber,
    icoRegistration,
    contactEmail,
  ];

  /// Vrai quand tous les champs obligatoires sont remplis.
  static bool get isComplete => _required.every((v) => v != null && v.isNotEmpty);

  /// Champs encore à remplir (pour le rapport et les tests).
  static List<String> get missingFields => [
        if (companyNumber == null) 'companyNumber (Companies House)',
        if (placeOfRegistration == null) 'placeOfRegistration',
        if (registeredOffice == null) 'registeredOffice',
        if (vatNumber == null) 'vatNumber',
        if (icoRegistration == null) 'icoRegistration (ICO)',
        if (contactEmail == null) 'contactEmail',
        if (safetyEmail == null) 'safetyEmail',
        if (euRepresentative == null) 'euRepresentative',
        if (disputeResolution == null) 'disputeResolution',
      ];

  static Map<String, String> get placeholders {
    final todo = L10n.language == 'fr' ? '[à compléter]' : '[to be completed]';
    final email = contactEmail ?? todo;
    return {
      'company': companyName,
      'city': L10n.language == 'fr' ? city : cityEn,
      'company_number': companyNumber ?? todo,
      'place_of_registration': placeOfRegistration ?? todo,
      'address': registeredOffice ?? todo,
      'vat': vatNumber ?? todo,
      'ico': icoRegistration ?? todo,
      'email': email,
      'safety_email': safetyEmail ?? email,
      'eu_rep': euRepresentative ?? todo,
      'adr': disputeResolution ?? todo,
      'version': termsVersion,
    };
  }
}
