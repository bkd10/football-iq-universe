// Traductions : socle de l'appli (erreurs, validateurs, formats, navigation) et feed.
const coreTranslations = <String, Map<String, String>>{
  'en': {
    // Exceptions et Failures
    'Une erreur serveur est survenue.': 'A server error occurred.',
    'Pas de connexion réseau.': 'No network connection.',
    'Erreur de cache local.': 'Local cache error.',
    'Solde de Ballons insuffisant.': 'Not enough Balls.',
    'Limite quotidienne atteinte pour cette action.': 'Daily limit reached for this action.',
    'Vérifie ta connexion internet.': 'Check your internet connection.',
    'Échec de l\'authentification.': 'Authentication failed.',
    'Confirme ton e-mail avant de te connecter.': 'Confirm your email before logging in.',
    'Une erreur inattendue est survenue.': 'An unexpected error occurred.',

    // Validateurs
    'L\'email est requis.': 'Email is required.',
    'Format d\'email invalide.': 'Invalid email format.',
    'Le mot de passe est requis.': 'Password is required.',
    'Le mot de passe doit contenir au moins 8 caractères.':
        'Password must be at least 8 characters.',
    'Les mots de passe ne correspondent pas.': 'Passwords don\'t match.',
    'Le pseudo est requis.': 'Username is required.',
    '3 à 20 caractères : lettres, chiffres, underscore.':
        '3 to 20 characters: letters, numbers, underscore.',
    'Ce champ': 'This field',
    '{field} est requis.': '{field} is required.',

    // Formats de temps
    'à l\'instant': 'just now',
    '{n}min': '{n}min',
    '{n}h': '{n}h',
    '{n}j': '{n}d',
    '{n}sem': '{n}w',
    '{n}mois': '{n}mo',
    'Terminé': 'Ended',
    '{d}j {h}h': '{d}d {h}h',
    '{h}h {m}min': '{h}h {m}min',

    // Catégories de classement
    'IQ Football': 'Football IQ',
    'Technique': 'Technique',
    'Créativité': 'Creativity',
    'Popularité': 'Popularity',
    'Régularité': 'Consistency',

    // Écran temporaire
    'Cette fonctionnalité arrive bientôt.': 'This feature is coming soon.',

    // Barre de navigation
    'Feed': 'Feed',
    'Défis': 'Challenges',
    'Créer': 'Create',
    'Classement': 'Rankings',
    'Profil': 'Profile',

    // Feed
    'Le Vestiaire arrive bientôt : tu y verras les vidéos des joueurs que tu suis.':
        'The Locker Room is coming soon: you\'ll see videos from the players you follow.',
    'Impossible de charger le feed.': 'Couldn\'t load the feed.',
    'LE TERRAIN EST LIBRE': 'THE PITCH IS OPEN',
    'Publie la première vidéo et prends la première carte.':
        'Post the first video and grab the first card.',
    'Comment ça marche': 'How it works',
    'Messages': 'Messages',
    'Vestiaire': 'Locker Room',
    'Ouverture': 'Discover',
    'Tendances': 'Trending',
    'Les talents à découvrir, peu importe leurs abonnés.':
        'Talent to discover, no matter their follower count.',
    'Les vidéos des joueurs que tu suis.': 'Videos from the players you follow.',
    'Les Moves du moment.': 'The Moves of the moment.',

    // Carte joueur
    'Bronze': 'Bronze',
    'Argent': 'Silver',
    'Or': 'Gold',
    'Platine': 'Platinum',
    'Diamant': 'Diamond',
    'ATT': 'FWD',
    'MIL': 'MID',
    'DÉF': 'DEF',
    'GB': 'GK',
    'JOU': 'PLR',
    'pied droit': 'right foot',
    'pied gauche': 'left foot',
    'deux pieds': 'both feet',
    'attaquant': 'forward',
    'milieu': 'midfielder',
    'defenseur': 'defender',
    'gardien': 'goalkeeper',
    '🎉 +{reward} Ballons : {target} vidéos regardées en entier aujourd’hui !':
        '🎉 +{reward} Balls: {target} videos watched in full today!',
    'Regarde le Move "{name}" sur Football IQ Universe : {url}':
        'Check out the Move "{name}" on Football IQ Universe: {url}',
    'Regarde cette vidéo sur Football IQ Universe : {url}':
        'Check out this video on Football IQ Universe: {url}',
    '🔥 Move : {name}': '🔥 Move: {name}',
    'original': 'original',
    'Reproduit un Move': 'Recreates a Move',
    'Carte {tier}': '{tier} card',
    'Joueur': 'Player',
    'Suivi ✓': 'Following ✓',
    'Suivre': 'Follow',
    'VID': 'VID',
    'RESPECT': 'RESPECT',
    'STARS': 'STARS',
    'DÉFIS': 'WINS',
    'MOVES': 'MOVES',
    'Respect': 'Respect',
    'Masterclass': 'Masterclass',
    'Avis': 'Comments',
    'Partager': 'Share',
    'Vidéo pas encore lisible': 'Video not playable yet',
    'Réessayer': 'Retry',

    // Guide du feed (Comment ça marche)
    'COMMENT ÇA MARCHE': 'HOW IT WORKS',
    'Ici, le talent parle plus que les followers.':
        'Here, talent speaks louder than followers.',
    'Les onglets du feed': 'Feed tabs',
    'Les talents à découvrir, choisis pour leur niveau et pas pour leurs abonnés.':
        'Talent to discover, picked for their level, not their followers.',
    'Les Moves du moment : les gestes que tout le monde essaie de reproduire.':
        'The Moves of the moment: the skills everyone is trying to copy.',
    'La forme': 'Form',
    'Une partie de la note suit tes 30 derniers jours : Respect récents, Battles gagnées ou perdues. Si tu ne publies plus ou que tu perds, ta note baisse. La flèche sous la note montre ta forme (▲ ou ▼).': 'Part of your rating follows your last 30 days: recent Respect, Battles won or lost. If you stop posting or keep losing, your rating drops. The arrow under the rating shows your form (▲ or ▼).',
    'TON VESTIAIRE EST VIDE': 'YOUR LOCKER ROOM IS EMPTY',
    'Suis des joueurs depuis leur carte ou leur profil : leurs nouvelles vidéos arriveront ici.': 'Follow players from their card or profile: their new videos will show up here.',
    'Vestiaire (bientôt)': 'Locker Room (soon)',
    'En bas de l’écran': 'At the bottom of the screen',
    'Les cartes des joueurs, à faire défiler vers le haut.':
        'Player cards, swipe up to scroll.',
    'Lance une Battle ou rejoins un Challenge avec ta vidéo.':
        'Start a Battle or join a Challenge with your video.',
    'Filme ou publie ta vidéo (5 à 60 secondes).':
        'Film or post your video (5 to 60 seconds).',
    'Les meilleurs joueurs du moment.': 'The top players right now.',
    'Ta carte, tes stats et tes badges.': 'Your card, your stats and your badges.',
    'Les couleurs des cartes': 'Card colors',
    'Ta carte change de couleur avec les points de Respect que tu reçois, comme un disque d’or.':
        'Your card changes color with the Respect points you get, like a gold record.',
    'Les boutons': 'The buttons',
    'Tu aimes le geste : +1 point pour le joueur. Astuce : tape deux fois sur la vidéo.':
        'You like the skill: +1 point for the player. Tip: double-tap the video.',
    'Le geste est exceptionnel : +3 points. C’est l’un ou l’autre, Respect ou Masterclass.':
        'The skill is outstanding: +3 points. It\'s one or the other, Respect or Masterclass.',
    'Laisse un commentaire au joueur.': 'Leave the player a comment.',
    'Envoie la vidéo à tes potes.': 'Send the video to your friends.',
    'Les défis': 'Challenges',
    'Battle': 'Battle',
    'Toi contre un autre joueur. Tu fixes les règles (le plus beau but, qui réussit ce geste…) et la mise. Ton adversaire mise autant, les utilisateurs votent, le gagnant prend les deux mises.':
        'You against another player. You set the rules (best goal, who can pull off this skill…) and the stake. Your opponent stakes the same, users vote, and the winner takes both stakes.',
    'Challenge': 'Challenge',
    'Ouvert à tous entre une date de début et une date de fin. 20 Ballons pour entrer, le plus de votes remporte la cagnotte.':
        'Open to everyone between a start and end date. 20 Balls to enter, most votes wins the pot.',
    'Monde': 'World',
    'Les défis officiels Football IQ, gratuits.': 'Official Football IQ challenges, free.',
    'Sponsorisé': 'Sponsored',
    'Proposés par des marques, avec de vrais lots à gagner.':
        'Run by brands, with real prizes to win.',
    'Votes': 'Votes',
    'Un vote par personne. On ne vote pas pour soi, ni dans sa propre Battle. Égalité ou aucun vote : chacun récupère sa mise.':
        'One vote per person. You can\'t vote for yourself or in your own Battle. Tie or no votes: everyone gets their stake back.',
    'Gagner des Ballons': 'Earn Balls',
    'Bienvenue': 'Welcome',
    '100 Ballons à l’inscription.': '100 Balls when you sign up.',
    'Regarder': 'Watch',
    '+30 quand tu regardes 20 vidéos en entier dans la journée.':
        '+30 when you watch 20 videos in full in a day.',
    'Publier': 'Post',
    '+5 par vidéo publiée (3 fois par jour maximum).': '+5 per video posted (3 times a day max).',
    'Gagner': 'Win',
    'Remporte une Battle ou un Challenge et la cagnotte est pour toi.':
        'Win a Battle or a Challenge and the pot is yours.',
    'La note sur 99': 'The rating out of 99',
    'Elle monte avec ce que le joueur accomplit : vidéos publiées, points de Respect, Stars, défis gagnés et Moves inventés. Son nombre d’abonnés ne compte pas.':
        'It goes up with what the player achieves: videos posted, Respect points, Stars, challenges won and Moves invented. Their follower count doesn\'t matter.',
    'C’est parti !': 'Let\'s go!',
    'Au départ': 'To start',
    'Dès {points} points': 'From {points} points',
    'CARTE {tier}': '{tier} CARD',
  },
};
