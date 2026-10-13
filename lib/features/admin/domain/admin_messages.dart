/// Messages pré-écrits proposés à l'admin quand il traite un signalement.
/// Chaque message reste modifiable avant l'envoi.
class AdminMessages {
  const AdminMessages._();

  /// À l'auteur, quand sa vidéo est retirée.
  static const authorRemovedVideo = [
    'Ta vidéo a été retirée : elle ne respecte pas les règles de Football IQ Universe. '
        'Le respect fait partie du jeu.',
    'Ta vidéo a été retirée : elle ne montre pas de geste de football. '
        'Montre-nous ton talent balle au pied !',
    'Ta vidéo a été retirée : elle reprend le contenu de quelqu\'un d\'autre. '
        'Ici, seul ton propre talent compte.',
    'Ta vidéo a été retirée pour spam.',
  ];

  /// À l'auteur, quand son commentaire est retiré.
  static const authorRemovedComment = [
    'Ton commentaire a été retiré : on reste respectueux entre joueurs.',
    'Ton commentaire a été retiré pour spam.',
  ];

  /// À l'auteur, quand son contenu est gardé (désactivé par défaut).
  static const authorKept = [
    'Ta vidéo a été signalée, mais après vérification elle respecte les règles. '
        'Elle reste en ligne, continue comme ça !',
  ];

  /// Aux joueurs qui ont signalé, contenu retiré.
  static const reporterRemoved = [
    'Merci pour ton signalement. Le contenu a été retiré.',
    'Merci d\'aider à garder Football IQ Universe propre. Le contenu a été retiré.',
  ];

  /// Aux joueurs qui ont signalé, contenu gardé.
  static const reporterKept = [
    'Merci pour ton signalement. Après vérification, ce contenu respecte nos règles '
        'et reste en ligne.',
  ];

  /// Raisons de bannissement.
  static const banReasons = [
    'Triche (faux comptes, votes truqués)',
    'Harcèlement ou insultes',
    'Contenu inapproprié répété',
    'Spam',
    'Usurpation d\'identité',
  ];
}
