// Traductions : défis (Battle, Challenge, King, Monde, Sponsorisé) et compte marque.
const challengesTranslations = <String, Map<String, String>>{
  'en': {
    // Liste des défis
    'Tous': 'All',
    '⚔️ Battle': '⚔️ Battle',
    '🎯 Challenge': '🎯 Challenge',
    '🌍 Monde': '🌍 World',
    '💼 Sponsorisé': '💼 Sponsored',
    '👑 King': '👑 King',
    '🌍 Défi Monde': '🌍 World Challenge',
    'Battle': 'Battle',
    'Challenge': 'Challenge',
    'Toi contre un joueur. Tu fixes les règles et la mise.':
        'You vs. a player. You set the rules and the stake.',
    'Ouvert à tous, avec une date de début et de fin.':
        'Open to everyone, with a start and end date.',
    'Défis': 'Challenges',
    'Créer un défi': 'Create a challenge',
    'Erreur de chargement.': 'Loading error.',
    'Aucun défi pour l\'instant — lance le premier !':
        'No challenges yet — start the first one!',

    // Compte marque
    'Mes Défis Sponsorisés': 'My Sponsored Challenges',
    'Nouveau défi': 'New challenge',
    'Aucun défi publié pour l\'instant. Crée ton premier Défi '
            'Sponsorisé avec le bouton ci-dessous.':
        'No challenges published yet. Create your first Sponsored '
            'Challenge with the button below.',
    'Compte marque': 'Brand account',
    'Compte vérifié — tu peux publier des Défis Sponsorisés.':
        'Verified account — you can publish Sponsored Challenges.',
    'Compte en attente de vérification manuelle avant de '
            'pouvoir publier un Défi Sponsorisé. Contacte '
            'l\'équipe Football IQ Universe pour la demander.':
        'Your account is awaiting manual verification before you can '
            'publish a Sponsored Challenge. Contact the Football IQ '
            'Universe team to request it.',
    'Se déconnecter': 'Log out',
    'Mes défis': 'My challenges',
    'Compte': 'Account',

    // Création d'une Battle
    'Choisis ta vidéo pour la Battle.': 'Pick your video for the Battle.',
    'Choisis ton adversaire.': 'Pick your opponent.',
    'Battle lancée ! ⚔️': 'Battle launched! ⚔️',
    'Impossible de lancer la Battle.': 'Couldn\'t launch the Battle.',
    'Lancer une Battle': 'Launch a Battle',
    '⚔️ Toi contre un autre joueur. Tu fixes les règles et la mise. '
            'Ton adversaire mise la même somme pour relever le défi, puis '
            'les utilisateurs votent. Le gagnant remporte les deux mises. '
            'Égalité ou personne en face : chacun récupère sa mise.':
        '⚔️ You vs. another player. You set the rules and the stake. '
            'Your opponent stakes the same amount to take on the challenge, then '
            'users vote. The winner takes both stakes. '
            'Tie or no opponent: everyone gets their stake back.',
    'Titre': 'Title',
    'Ex : le plus beau but': 'E.g. the best goal',
    'Donne un titre (3 caractères minimum).':
        'Give it a title (3 characters minimum).',
    'Règles': 'Rules',
    'Ex : qui fait ce geste ? Le plus beau geste gagne.':
        'E.g. who can pull off this skill? The best one wins.',
    'Mise (Ballons)': 'Stake (Balls)',
    'Tu as {coins} Ballons': 'You have {coins} Balls',
    'Entre {min} et {max} Ballons.': 'Between {min} and {max} Balls.',
    'Tu n\'as que {coins} Ballons.': 'You only have {coins} Balls.',
    'Adversaire': 'Opponent',
    'Ouvert': 'Open',
    'Choisir': 'Choose',
    'Aléatoire': 'Random',
    'Le premier joueur qui relève la Battle sera ton adversaire.':
        'The first player to take on the Battle will be your opponent.',
    'Un joueur tiré au hasard sera défié et prévenu.':
        'A random player will be challenged and notified.',
    'Choisir parmi tes abonnés et abonnements':
        'Choose from your followers and following',
    'Changer': 'Change',
    'Ta vidéo': 'Your video',
    'Choisir ma vidéo': 'Choose my video',
    'La vidéo avec laquelle tu affrontes ton adversaire':
        'The video you\'ll face your opponent with',
    'Fin des votes': 'Voting ends',
    'Lancer la Battle': 'Launch the Battle',

    // Création d'un Challenge / Défi Sponsorisé
    'La fin doit être au moins 1 heure après le début.':
        'The end must be at least 1 hour after the start.',
    'Défi créé !': 'Challenge created!',
    'Échec de la création du défi.': 'Couldn\'t create the challenge.',
    'Créer un Défi Sponsorisé': 'Create a Sponsored Challenge',
    'Créer un Challenge': 'Create a Challenge',
    'Gratuit à créer et à rejoindre : aucun Ballon n\'est '
            'débité ni distribué. Le prix que tu décris ci-dessous '
            'est un prix réel que tu remets toi-même au vainqueur, '
            'hors de l\'app.':
        'Free to create and join: no Balls are charged or handed out. '
            'The prize you describe below is a real prize you give the '
            'winner yourself, outside the app.',
    '🎯 Un Challenge est ouvert à tous les joueurs entre la date de '
            'début et la date de fin. Créer coûte '
            '{createCost} Ballons ; chaque '
            'participant paie {joinCost} Ballons, '
            'qui forment la cagnotte. Le joueur avec le plus de votes la '
            'remporte.':
        '🎯 A Challenge is open to all players between the start and end '
            'date. Creating one costs {createCost} Balls; each participant '
            'pays {joinCost} Balls, which make up the prize pool. The player '
            'with the most votes wins it.',
    'Le titre est requis.': 'A title is required.',
    'Description': 'Description',
    'Description du prix (ex : une paire de crampons)':
        'Prize description (e.g. a pair of boots)',
    'La description du prix est requise.': 'A prize description is required.',
    'Participants max (optionnel)': 'Max participants (optional)',
    'Début': 'Start',
    'Fin': 'End',
    'Publier le défi': 'Publish the challenge',
    'Créer le défi': 'Create the challenge',

    // Détail d'un défi
    'Défi': 'Challenge',
    'Ce défi est introuvable.': 'This challenge can\'t be found.',
    'Terminé': 'Finished',
    'Annulé': 'Cancelled',
    'Commence dans {time}': 'Starts in {time}',
    'Par {sponsor}': 'By {sponsor}',
    'Entrée': 'Entry',
    'Gratuit': 'Free',
    'Prix': 'Prize',
    'Participants': 'Participants',
    'Mise': 'Stake',
    '{n} Ballons': '{n} Balls',
    'À gagner': 'To win',
    'Joueurs': 'Players',
    'Cagnotte': 'Prize pool',
    'Ouvre le {date}': 'Opens on {date}',
    'Relever la Battle ({n} Ballons)': 'Take on the Battle ({n} Balls)',
    'Participer gratuitement': 'Join for free',
    'Participer ({n} Ballons)': 'Join ({n} Balls)',
    'Tu participes à ce défi.': 'You\'re in this challenge.',
    'Les vidéos — vote pour la meilleure': 'The videos — vote for the best one',
    'Aucun participant pour l\'instant.': 'No participants yet.',
    'Battle relevée ! ⚔️': 'Battle accepted! ⚔️',
    'Tu participes au défi !': 'You\'re in the challenge!',
    'Échec de la participation.': 'Couldn\'t join.',
    'Aucun record': 'No record',
    'par @{user}': 'by @{user}',
    'Sois le premier à établir un record !': 'Be the first to set a record!',
    'Défi gratuit proposé par une marque partenaire : aucun Ballon '
            'n\'est débité ni distribué. Le vainqueur (le plus de votes, '
            'égalité départagée par ordre d\'inscription) reçoit le prix '
            'décrit ci-dessus, remis directement par la marque.':
        'Free challenge from a partner brand: no Balls are charged or '
            'handed out. The winner (most votes, ties broken by sign-up order) '
            'gets the prize described above, given directly by the brand.',
    'Battle 1 contre 1 : chaque joueur mise {stake} Ballons. '
            'Les autres utilisateurs regardent les deux vidéos et votent (un vote '
            'par personne, les deux joueurs ne votent pas). Le gagnant remporte les '
            '{prize} Ballons et +100 Stars. Égalité, aucun vote ou '
            'personne en face : chacun récupère sa mise.':
        '1v1 Battle: each player stakes {stake} Balls. Other users watch both '
            'videos and vote (one vote per person, the two players don\'t vote). '
            'The winner takes the {prize} Balls and +100 Stars. Tie, no votes or '
            'no opponent: everyone gets their stake back.',
    'Le Roi en titre remporte la cagnotte s\'il n\'est pas '
            'détrôné avant la fin du défi. Chaque tentative pour le '
            'détrôner coûte {cost} Ballons, qui rejoignent '
            'la cagnotte.':
        'The reigning King wins the prize pool if nobody dethrones them '
            'before the challenge ends. Each attempt to dethrone them costs '
            '{cost} Balls, which go into the prize pool.',
    'Ouvert à tous du {start} '
            'au {end}. Chaque droit '
            'd\'entrée ({cost} Ballons) rejoint la cagnotte. Le '
            'participant avec le plus de votes la remporte en entier (égalité : '
            'le premier inscrit). Aucun vote : chacun est remboursé.':
        'Open to everyone from {start} to {end}. Each entry fee ({cost} Balls) '
            'goes into the prize pool. The participant with the most votes wins '
            'all of it (tie: first to sign up). No votes: everyone gets refunded.',
    'inconnu': 'unknown',
    'Rang #{rank}': 'Rank #{rank}',
    'En attente': 'Waiting',
    '{n} votes': '{n} votes',
    'Vote enregistré 🗳️': 'Vote saved 🗳️',
    'Vote impossible.': 'Couldn\'t vote.',
    'Adversaire à trouver': 'Opponent wanted',

    // Carte de défi
    'TERMINÉ': 'FINISHED',
    'Dans {time}': 'In {time}',
    '@{creator} VS {opponent} · mise {stake} Ballons':
        '@{creator} VS {opponent} · stake {stake} Balls',
    'adversaire à trouver': 'opponent wanted',
    'Record : {record} {unit} — @{holder}': 'Record: {record} {unit} — @{holder}',
    'Aucun record établi — sois le premier !': 'No record set — be the first!',
    '{n} participants · gratuit': '{n} participants · free',
    '{n} participants': '{n} participants',
    '· {n} Ballons pour participer': '· {n} Balls to join',
    'Cagnotte : {n} Ballons': 'Prize pool: {n} Balls',

    // Date
    '{date} à {time}': '{date} at {time}',

    // Choix de l'adversaire
    'Choisis ton adversaire': 'Pick your opponent',
    'Rechercher un @pseudo': 'Search for a @username',
    'Erreur.': 'Error.',
    'Défier @{user}': 'Challenge @{user}',
    'Joueur hors de tes abonnés': 'Player outside your followers',
    'Tu ne suis encore personne et personne ne te suit. '
            'Tape le @pseudo d\'un joueur, ou choisis « Aléatoire ».':
        'You don\'t follow anyone yet and nobody follows you. '
            'Type a player\'s @username, or choose "Random".',
    'Vous vous suivez': 'You follow each other',
    'Te suit': 'Follows you',
    'Tu le suis': 'You follow them',

    // Choix d'une vidéo
    'Choisis ta vidéo': 'Pick your video',
    'Publie d\'abord une vidéo pour pouvoir participer.':
        'Post a video first so you can join.',
    'Vidéo sans légende': 'Video with no caption',
    'Publiée {age}': 'Posted {age}',
    'Publiée il y a {age}': 'Posted {age} ago',
    '{published} · {views} vues': '{published} · {views} views',

    // Erreurs serveur (data layer)
    'Défi créé mais introuvable.': 'Challenge created but not found.',
    'Battle créée mais introuvable.': 'Battle created but not found.',
  },
};
