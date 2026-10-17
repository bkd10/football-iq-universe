// Traductions : connexion, inscription, onboarding, réglages et recherche.
const authTranslations = <String, Map<String, String>>{
  'en': {
    // Erreurs de la couche données (traduites via Failure.message).
    'Connexion impossible.': 'Couldn\'t sign in.',
    'Confirme ton e-mail avant de te connecter — vérifie ta boîte de réception.':
        'Confirm your email before signing in — check your inbox.',
    'Inscription impossible.': 'Couldn\'t sign up.',
    'Aucune session active.': 'No active session.',
    'Profil introuvable.': 'Profile not found.',

    // Retour du lien de confirmation.
    'Lien invalide ou expiré': 'Invalid or expired link',
    'Retour à la connexion': 'Back to sign in',
    'Confirmation en cours…': 'Confirming…',

    // Confirmation d'e-mail.
    'E-mail renvoyé — vérifie ta boîte de réception.':
        'Email resent — check your inbox.',
    'Confirme ton e-mail': 'Confirm your email',
    'On a envoyé un lien de confirmation à {email}. '
            'Clique dessus pour activer ton compte — cette page passera '
            'automatiquement à l\'app une fois confirmé.':
        'We sent a confirmation link to {email}. '
            'Tap it to activate your account — this page will switch to the '
            'app automatically once you\'re confirmed.',
    'Renvoyer l\'e-mail': 'Resend email',

    // Mot de passe oublié.
    'Erreur inconnue.': 'Unknown error.',
    'Mot de passe oublié ?': 'Forgot password?',
    'Indique ton email, on t\'envoie un lien de réinitialisation.':
        'Enter your email and we\'ll send you a reset link.',
    'Email': 'Email',
    'Envoyer le lien': 'Send link',
    'Email envoyé !': 'Email sent!',
    'Vérifie ta boîte mail ({email}) pour réinitialiser ton mot de passe.':
        'Check your inbox ({email}) to reset your password.',

    // Connexion.
    'Content de te revoir': 'Good to see you again',
    'Connecte-toi pour continuer ta progression sur {app}.':
        'Sign in to keep progressing on {app}.',
    'Mot de passe': 'Password',
    'Se connecter': 'Sign in',
    'Pas encore de compte ?': 'No account yet?',
    'Inscris-toi': 'Sign up',
    'Tu es le tuteur d\'un joueur ? Approuver un contact':
        'Are you a player\'s guardian? Approve a contact',

    // Onboarding.
    'Passer': 'Skip',
    'Ici, un inconnu peut devenir une star':
        'Here, a nobody can become a star',
    'Le talent parle, pas les followers. Poste tes gestes techniques et '
            'laisse notre algorithme Talent First te découvrir, où que tu sois.':
        'Talent talks, not followers. Post your skills and let our '
            'Talent First algorithm discover you, wherever you are.',
    'Invente ton Move': 'Invent your Move',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le '
            'reproduire. Chaque reproduction te crédite — à vie.':
        'Create a skill, name it after yourself, and watch the community '
            'copy it. Every copy credits you — for life.',
    'Progresse, prouve, sois recruté': 'Improve, prove it, get scouted',
    'Ton Football IQ n\'est jamais achetable. Ton Football Passport '
            'certifie ton niveau réel — c\'est ce que voient les recruteurs.':
        'Your Football IQ can never be bought. Your Football Passport '
            'certifies your real level — it\'s what scouts see.',
    'Rejoindre l\'aventure': 'Join the adventure',
    'Suivant': 'Next',

    // Inscription.
    'Bienvenue sur {app} !': 'Welcome to {app}!',
    'Crée ton profil': 'Create your profile',
    'Gratuit, sans engagement. Le talent parle, pas les followers.':
        'Free, no commitment. Talent talks, not followers.',
    'Pseudo': 'Username',
    'Confirme le mot de passe': 'Confirm password',
    'Pays (optionnel)': 'Country (optional)',
    'Poste': 'Position',
    'Attaquant': 'Forward',
    'Milieu': 'Midfielder',
    'Defenseur': 'Defender',
    'Gardien': 'Goalkeeper',
    'Pied fort': 'Strong foot',
    'Gauche': 'Left',
    'Droit': 'Right',
    'Les Deux': 'Both',
    'Type de compte': 'Account type',
    'Joueur': 'Player',
    'Recruteur': 'Scout',
    'Marque': 'Brand',
    'Compte pro pour repérer des joueurs et les contacter (abonnement requis).':
        'Pro account to spot players and contact them (subscription required).',
    'Compte marque pour publier des Défis Sponsorisés avec un vrai prix '
            '(vérification manuelle requise avant publication).':
        'Brand account to post Sponsored Challenges with a real prize '
            '(manual review required before publishing).',
    'Compte joueur classique : vidéos, défis, classement.':
        'Standard player account: videos, challenges, rankings.',
    'Créer mon compte recruteur': 'Create my scout account',
    'Créer mon compte marque': 'Create my brand account',
    'Créer mon compte': 'Create my account',

    // Réglages.
    'Réglages': 'Settings',
    'COMPTE': 'ACCOUNT',
    'Nom d\'utilisateur': 'Username',
    'Modifier le profil': 'Edit profile',
    'Messages': 'Messages',
    'PROTECTION': 'PROTECTION',
    'Protection des mineurs': 'Protection of minors',
    'Aucune géolocalisation précise publique. Le contact par un '
            'recruteur vérifié est toujours médié pour les moins de 18 ans.':
        'No precise location is ever public. Contact from a verified scout '
            'is always mediated for under-18s.',
    'J\'ai un code tuteur': 'I have a guardian code',
    'Pour approuver ou refuser un contact recruteur.':
        'To approve or decline a scout contact.',
    'Administration': 'Admin',
    'Statistiques, signalements, joueurs, défis officiels.':
        'Stats, reports, players, official challenges.',
    'Se déconnecter': 'Sign out',
    'Supprimer mon compte': 'Delete my account',
    'Supprimer ton compte ?': 'Delete your account?',
    'Cette action est définitive. Ton profil, tes vidéos, tes défis et '
            'ton historique seront supprimés pour de bon — impossible de '
            'revenir en arrière.':
        'This can\'t be undone. Your profile, videos, challenges and '
            'history will be deleted for good — there\'s no going back.',
    'Annuler': 'Cancel',
    'Supprimer': 'Delete',
    'La suppression a échoué. Réessaie plus tard.':
        'Deletion failed. Try again later.',

    // Recherche.
    'Chercher un joueur ou un Move…': 'Search for a player or a Move…',
    'Tape au moins 2 caractères pour chercher un joueur ou un Move.':
        'Type at least 2 characters to search for a player or a Move.',
    'Erreur de recherche.': 'Search error.',
    'Aucun résultat.': 'No results.',
    'Joueurs': 'Players',
    '{n} reproductions': '{n} copies',
  },
};
