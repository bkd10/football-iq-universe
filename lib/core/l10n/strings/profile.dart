// Traductions : profil, édition du profil et messagerie (recruteur / tuteur).
const profileTranslations = <String, Map<String, String>>{
  'en': {
    // Messagerie — approbation tuteur
    'Renseigne le code reçu du joueur.': 'Enter the code the player gave you.',
    'Contact approuvé — le joueur peut désormais échanger avec ce recruteur.':
        'Contact approved — the player can now chat with this scout.',
    'Contact refusé.': 'Contact declined.',
    'Une erreur est survenue.': 'Something went wrong.',
    'Approbation tuteur': 'Guardian approval',
    'Un recruteur vérifié souhaite contacter un joueur mineur.':
        'A verified scout wants to contact an underage player.',
    'Football IQ Universe médie systématiquement tout contact '
            'avec un joueur mineur : ce contact ne sera possible que si '
            'tu l\'approuves ici, en tant que tuteur.':
        'Football IQ Universe always mediates any contact with an underage '
            'player: this contact will only be possible if you approve it '
            'here, as their guardian.',
    'Code reçu du joueur': 'Code from the player',
    'Approuver le contact': 'Approve contact',
    'Refuser le contact': 'Decline contact',

    // Messagerie — conversation
    'Échec de l\'envoi.': 'Couldn\'t send.',
    'Impossible de générer le lien.': 'Couldn\'t generate the link.',
    'ce joueur': 'this player',
    'Un recruteur vérifié souhaite contacter {username} sur '
            'Football IQ Universe. Pour approuver ou refuser ce contact, ouvre '
            'l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce '
            'code : {token}':
        'A verified scout wants to contact {username} on Football IQ '
            'Universe. To approve or decline this contact, open the app, go '
            'to Settings > "I have a guardian code" and enter this code: '
            '{token}',
    'Message copié — colle-le dans SMS/WhatsApp pour ton tuteur.':
        'Message copied — paste it into SMS/WhatsApp for your guardian.',
    'inconnu': 'unknown',
    'En attente d\'approbation d\'un tuteur avant de pouvoir échanger.':
        'Waiting for a guardian\'s approval before you can chat.',
    'En attente d\'approbation du tuteur du joueur.':
        'Waiting for the player\'s guardian to approve.',
    'Copier le lien pour ton tuteur': 'Copy the link for your guardian',
    'Ce contact a été refusé.': 'This contact was declined.',
    'Erreur de chargement.': 'Loading error.',
    'Aucun message pour l\'instant.': 'No messages yet.',
    'Message...': 'Message...',

    // Messagerie — boîte de réception
    'Aucune conversation pour l\'instant.': 'No conversations yet.',
    'En attente d\'approbation du tuteur': 'Waiting for guardian approval',
    'Contact refusé': 'Contact declined',
    'Discussion active': 'Active chat',

    // Messagerie — erreurs (data)
    'Aucune session active.': 'No active session.',

    // Profil
    'Mon Profil': 'My Profile',
    'Missions du jour': 'Daily Missions',
    'Réglages': 'Settings',
    'Signaler ce profil': 'Report this profile',
    'Ce joueur est introuvable.': 'This player can\'t be found.',
    'Ballons': 'Balls',
    'Abonnés': 'Followers',
    'Abonnements': 'Following',
    'Vidéos': 'Videos',
    'Technique': 'Technique',
    'Créativité': 'Creativity',
    'Popularité': 'Popularity',
    'Régularité': 'Consistency',
    'Tactique': 'Tactics',
    'Aucun Move créé pour l\'instant.': 'No Moves created yet.',
    'Aucune vidéo pour l\'instant.': 'No videos yet.',
    'Aucun badge débloqué pour l\'instant.': 'No badges unlocked yet.',
    'Abonné ✓': 'Following ✓',
    'Suivre': 'Follow',
    'Réservé aux recruteurs vérifiés · contact médié pour les mineurs.':
        'Verified scouts only · contact is mediated for minors.',
    'Échec de la demande de contact.': 'Contact request failed.',
    'Ce joueur est mineur : demande envoyée, en attente d\'approbation de son tuteur.':
        'This player is a minor: request sent, waiting for their guardian\'s approval.',
    'Demande de contact envoyée.': 'Contact request sent.',
    'Demander le contact': 'Request contact',
    'Contacter ce joueur': 'Contact this player',

    // Profil — erreurs (data)
    'Connecte-toi pour suivre ce joueur.': 'Log in to follow this player.',

    // Modifier le profil
    'Échec de la mise à jour.': 'Update failed.',
    'Profil mis à jour, mais échec de l\'enregistrement du contact tuteur.':
        'Profile updated, but saving the guardian contact failed.',
    'Profil mis à jour.': 'Profile updated.',
    'Modifier le profil': 'Edit profile',
    'Nom affiché': 'Display name',
    'Pays': 'Country',
    'Ville': 'City',
    'Poste': 'Position',
    'Attaquant': 'Forward',
    'Milieu': 'Midfielder',
    'Defenseur': 'Defender',
    'Gardien': 'Goalkeeper',
    'Pied fort': 'Strong foot',
    'Gauche': 'Left',
    'Droit': 'Right',
    'Les Deux': 'Both',
    'CONTACT D\'UN TUTEUR': 'GUARDIAN CONTACT',
    'Un recruteur vérifié ne peut te contacter qu\'après '
            'approbation d\'un tuteur — renseigne son contact pour '
            'pouvoir être approché.':
        'A verified scout can only contact you after a guardian approves — '
            'add their contact so you can be approached.',
    'Nom du tuteur (optionnel)': 'Guardian name (optional)',
    'Email du tuteur': 'Guardian email',
    'Enregistrer': 'Save',
  },
};
