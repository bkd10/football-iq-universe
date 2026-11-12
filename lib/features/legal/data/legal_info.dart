/// Informations de la société qui édite l'appli, reprises dans les mentions
/// légales, les CGU et la politique de confidentialité. À remplir avant la
/// mise en vente : tant qu'un champ vaut `null`, le texte affiche
/// « [à compléter] ».
class LegalInfo {
  const LegalInfo._();

  static const String? companyName = null; // ex. « Football IQ SAS »
  static const String? legalForm = null; // ex. « SAS au capital de 1 000 € »
  static const String? registration = null; // ex. « RCS Paris 123 456 789 »
  static const String? vatNumber = null; // ex. « FR12 123456789 » (ou « non assujetti »)
  static const String? address = null; // siège social
  static const String? phone = null; // téléphone (obligatoire, loi LCEN)
  static const String? contactEmail = null; // e-mail de contact et RGPD
  static const String? publicationDirector = null; // nom du responsable
  static const String? consumerMediator = null; // médiateur de la consommation

  static const String termsVersion = '2026-11';

  /// Vrai quand tout est rempli : sert au test qui bloque une mise en
  /// vente avec des « [à compléter] ».
  static bool get isComplete => [
        companyName,
        legalForm,
        registration,
        vatNumber,
        address,
        phone,
        contactEmail,
        publicationDirector,
        consumerMediator,
      ].every((v) => v != null && v.isNotEmpty);

  static Map<String, String> get placeholders => {
        'company': companyName ?? '[à compléter]',
        'legal_form': legalForm ?? '[à compléter]',
        'registration': registration ?? '[à compléter]',
        'vat': vatNumber ?? '[à compléter]',
        'address': address ?? '[à compléter]',
        'phone': phone ?? '[à compléter]',
        'email': contactEmail ?? '[à compléter]',
        'director': publicationDirector ?? '[à compléter]',
        'mediator': consumerMediator ?? '[à compléter]',
        'version': termsVersion,
      };
}
