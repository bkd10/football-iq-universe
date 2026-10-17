// Traductions : textes envoyés par le serveur (erreurs, notifications).
const serverTranslations = <String, Map<String, String>>{
  'en': {
    // --- Erreurs (raise exception) ---
    'Authentification requise.': 'You need to be signed in.',
    'Réservé aux administrateurs.': 'Admins only.',
    'Action invalide.': 'Invalid action.',
    'Statut invalide.': 'Invalid status.',
    'Compte introuvable.': 'Account not found.',
    'Joueur introuvable.': 'Player not found.',
    'Défi introuvable.': 'Challenge not found.',
    'Signalement introuvable.': 'Report not found.',
    'Conversation introuvable.': 'Conversation not found.',
    'Conversation introuvable ou déjà approuvée.':
        'Conversation not found or already approved.',
    'Lien invalide ou déjà utilisé.': 'Invalid or already used link.',
    'Solde de Ballons insuffisant.': 'Not enough Balls.',
    'Montant invalide pour cette action.': 'Invalid amount for this action.',
    'Le titre doit faire entre 3 et 80 caractères.':
        'The title must be between 3 and 80 characters.',
    'La description est trop longue (1000 caractères max).':
        'The description is too long (1000 characters max).',
    'Les règles sont trop longues (1000 caractères max).':
        'The rules are too long (1000 characters max).',
    'Message trop long (500 caractères max).':
        'Message too long (500 characters max).',
    'Le message ne peut pas être vide.': "The message can't be empty.",
    'La date de fin doit être dans le futur.':
        'The end date must be in the future.',
    'La date de fin doit être au moins 1 heure après le début.':
        'The end date must be at least 1 hour after the start.',
    'Un défi officiel ne peut pas durer plus de 90 jours.':
        "An official Challenge can't last more than 90 days.",
    'Un défi doit commencer dans les 30 prochains jours.':
        'A Challenge must start within the next 30 days.',
    'Un défi ne peut pas durer plus de 60 jours.':
        "A Challenge can't last more than 60 days.",
    'Nombre de participants invalide.': 'Invalid number of participants.',
    'Seul un compte marque peut créer un défi sponsorisé.':
        'Only a Brand account can create a Sponsored Challenge.',
    'Ton compte marque doit être vérifié avant de pouvoir publier un défi sponsorisé.':
        'Your Brand account must be verified before you can publish a Sponsored Challenge.',
    'La description du prix est requise pour un défi sponsorisé.':
        'A prize description is required for a Sponsored Challenge.',
    "Une Battle se crée depuis l'écran Battle (1 contre 1).":
        'Battles are created from the Battle screen (1 vs 1).',
    'Les défis Monde sont réservés à Football IQ.':
        'World Challenges are reserved for Football IQ.',
    'Une Battle dure entre 1 heure et 14 jours.':
        'A Battle lasts between 1 hour and 14 days.',
    'Choisis une de tes propres vidéos.': 'Pick one of your own videos.',
    'Aucun adversaire disponible pour le moment.':
        'No opponent available right now.',
    'Tu ne peux pas te défier toi-même.': "You can't challenge yourself.",
    "Ce défi n'accepte plus de participations.":
        'This Challenge is no longer accepting entries.',
    "Ce défi n'a pas encore commencé.": "This Challenge hasn't started yet.",
    'Ce défi est complet.': 'This Challenge is full.',
    'Cette Battle est réservée au joueur défié.':
        'This Battle is only for the challenged Player.',
    "Tu ne peux participer qu'avec l'une de tes propres vidéos.":
        'You can only enter with one of your own videos.',
    'Tu participes déjà à ce défi.': "You're already in this Challenge.",
    'Tu ne peux pas voter pour toi-même.': "You can't vote for yourself.",
    "Ce défi n'accepte plus de votes.":
        'This Challenge is no longer accepting votes.',
    "Les votes ouvrent quand l'adversaire a relevé la Battle.":
        'Voting opens once the opponent has accepted the Battle.',
    'Les joueurs de la Battle ne votent pas.':
        "Battle Players can't vote.",
    "Publie d'abord une vidéo pour pouvoir voter (ou attends 24 h).":
        'Post a video first to be able to vote (or wait 24 h).',
    "Ce participant n'existe pas dans ce défi.":
        "This participant isn't in this Challenge.",
    'Tu as déjà voté dans ce défi.': "You've already voted in this Challenge.",
    "Connexion quotidienne déjà réclamée aujourd'hui.":
        'Daily login reward already claimed today.',
    'Vidéo introuvable pour cette récompense.':
        'Video not found for this reward.',
    'Récompense déjà reçue pour cette vidéo.':
        'Reward already received for this video.',
    'Limite quotidienne de récompenses vidéo atteinte.':
        'Daily video reward limit reached.',
    'Les récompenses publicitaires ne sont pas encore disponibles.':
        "Ad rewards aren't available yet.",
    'URL de vidéo invalide.': 'Invalid video URL.',
    'URL de miniature invalide.': 'Invalid thumbnail URL.',
    "Date de l'appareil invalide. Vérifie la date et l'heure de ton téléphone.":
        "Invalid device date. Check your phone's date and time.",
    'Indique la raison du bannissement.': 'Enter the reason for the ban.',
    'Tu ne peux pas te bannir toi-même.': "You can't ban yourself.",
    'Impossible de bannir un administrateur.': "You can't ban an admin.",
    'Seul un compte recruteur peut contacter un joueur.':
        'Only a Scout account can contact a Player.',
    'Un abonnement actif est requis pour contacter un joueur.':
        'An active subscription is required to contact a Player.',
    "Ce joueur est mineur et n'a pas encore renseigné le contact d'un tuteur : impossible de le contacter pour le moment.":
        "This Player is a minor and hasn't added a guardian contact yet: you can't contact them for now.",
    'Tu as déjà contacté ce joueur.': "You've already contacted this Player.",
    'Réservé aux comptes recruteurs.': 'Scout accounts only.',
    'Tu ne fais pas partie de cette conversation.':
        "You're not part of this conversation.",
    "Cette conversation n'est pas encore active.":
        "This conversation isn't active yet.",
    'Tu as déjà utilisé ton essai gratuit.':
        "You've already used your free trial.",

    // --- Notifications : titres ---
    'Nouveau badge débloqué': 'New badge unlocked',
    'Ton Move a été reproduit !': 'Your Move was reproduced!',
    'Nouveau commentaire': 'New comment',
    'Nouvel abonné': 'New Follower',
    'Nouveau vote Masterclass': 'New Masterclass vote',
    'Nouveau like': 'New like',
    'Ton signalement a été traité': 'Your report has been handled',
    'Message de la modération': 'Message from the moderators',
    'Contact approuvé': 'Contact approved',
    'Un recruteur veut te contacter': 'A Scout wants to contact you',
    'On te défie ! ⚔️': "You've been challenged! ⚔️",
    'Mise remboursée': 'Stake refunded',
    'Battle gagnée ! ⚔️': 'Battle won! ⚔️',
    'Défi remporté !': 'Challenge won!',

    // --- Notifications : textes fixes ---
    'Le contact avec le recruteur a été approuvé — vous pouvez échanger.':
        'Contact with the Scout has been approved — you can now chat.',
    'Le tuteur a approuvé le contact — vous pouvez échanger.':
        'The guardian approved the contact — you can now chat.',
    "L'approbation d'un tuteur est nécessaire avant de pouvoir échanger.":
        "A guardian's approval is needed before you can chat.",
    'Tu peux désormais lui répondre.': 'You can now reply to them.',
    '@un joueur a aimé ta vidéo.': '@a player liked your video.',
    '@un joueur a voté Masterclass pour ta vidéo.':
        '@a player voted Masterclass for your video.',
    '@un joueur a commenté ta vidéo.': '@a player commented on your video.',
    'Un nouveau badge rejoint ton Football Passport 🏅':
        'A new badge joins your Football Passport 🏅',
    'Bienvenue rejoint ton Football Passport 🏅':
        'Welcome joins your Football Passport 🏅',
    'Premier Pas rejoint ton Football Passport 🏅':
        'First Step joins your Football Passport 🏅',
    'Inventeur rejoint ton Football Passport 🏅':
        'Inventor joins your Football Passport 🏅',
    'Régulier rejoint ton Football Passport 🏅':
        'Regular joins your Football Passport 🏅',
    'Discipline de Fer rejoint ton Football Passport 🏅':
        'Iron Discipline joins your Football Passport 🏅',
    'Premier Sacre rejoint ton Football Passport 🏅':
        'First Title joins your Football Passport 🏅',
    'Champion du Monde rejoint ton Football Passport 🏅':
        'World Champion joins your Football Passport 🏅',

    // --- Badges (nom et description, table badges) ---
    'Bienvenue': 'Welcome',
    'Premier Pas': 'First Step',
    'Inventeur': 'Inventor',
    'Régulier': 'Regular',
    'Discipline de Fer': 'Iron Discipline',
    'Premier Sacre': 'First Title',
    'Champion du Monde': 'World Champion',
    'A rejoint Football IQ Universe.': 'Joined Football IQ Universe.',
    'A posté sa première vidéo.': 'Posted their first video.',
    'A créé son premier Move.': 'Created their first Move.',
    'Une vidéo a dépassé 100 000 vues.': 'A video passed 100,000 views.',
    '7 jours de connexion consécutifs.': '7 days of logins in a row.',
    '30 jours de connexion consécutifs.': '30 days of logins in a row.',
    'A remporté son premier défi.': 'Won their first Challenge.',
    'A remporté un Défi Monde hebdomadaire.': 'Won a weekly World Challenge.',
    'Top 10 de la progression hebdomadaire.': 'Top 10 in weekly progress.',
    'A atteint le niveau Rising Star.': 'Reached the Rising Star level.',
    'A atteint le niveau Prodigy.': 'Reached the Prodigy level.',
    'A atteint le niveau Legend.': 'Reached the Legend level.',
  },
};

/// Modèles pour les textes serveur avec des valeurs. Chaque entrée :
/// [regex (sans ^ ni $, ajoutés automatiquement), remplacement avec $1, $2...].
const serverTranslationPatterns = <String, List<List<String>>>{
  'en': [
    // --- Erreurs avec valeurs ---
    [r'La mise doit être entre (\d+) et (\d+) Ballons\.', r'The stake must be between $1 and $2 Balls.'],
    [r'Joueur introuvable : (.+)', r'Player not found: $1'],
    [r'Raison de récompense non prise en charge : (.+)', r'Unsupported reward reason: $1'],
    [r'Raison de dépense non prise en charge : (.+)', r'Unsupported spending reason: $1'],

    // --- Notifications ---
    [r'@(.+?) a voté Masterclass pour ta vidéo\.', r'@$1 voted Masterclass for your video.'],
    [r'@(.+?) a aimé ta vidéo\.', r'@$1 liked your video.'],
    [r'@(.+?) a commenté ta vidéo\.', r'@$1 commented on your video.'],
    [r'@(.+?) a commencé à te suivre\.', r'@$1 started following you.'],
    [r'@un joueur a reproduit "ton Move"\.', r'@a player reproduced "your Move".'],
    [r'@un joueur a reproduit "(.+)"\.', r'@a player reproduced "$1".'],
    [r'@(.+?) a reproduit "ton Move"\.', r'@$1 reproduced "your Move".'],
    [r'@(.+?) a reproduit "(.+)"\.', r'@$1 reproduced "$2".'],
    [r'(.+?) rejoint ton Football Passport 🏅', r'$1 joins your Football Passport 🏅'],
    [r'(.+?) te lance une Battle : « (.+) » \(mise : (\d+) Ballons\)\.', r'$1 challenges you to a Battle: "$2" (stake: $3 Balls).'],
    [r'« (.+) » se termine sans vainqueur : tes (\d+) Ballons te sont rendus\.', r'"$1" ended with no winner: your $2 Balls have been refunded.'],
    [r'Tu as remporté « (.+) » 🏆', r'You won "$1" 🏆'],
    [r'Tu as remporté "(.+)" 🏆', r'You won "$1" 🏆'],
  ],
};
