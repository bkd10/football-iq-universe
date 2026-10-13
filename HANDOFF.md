# Football IQ Universe — Document de passation

> **Mise à jour octobre 2026 — audit de sécurité.** La base installée pour
> de vrai (Supabase local) a révélé des bloquants (migration `…0013` qui ne
> s'appliquait pas, follow/like/commentaire/publication cassés) et des
> failles (Ballons à l'infini, cagnotte gratuite, jeton tuteur lisible par
> le recruteur, date de naissance publique). Tout est corrigé et testé :
> voir `SECURITY_AUDIT.md`. Le parcours a aussi été ouvert dans un vrai
> navigateur (Chromium) avec des données de démo : connexion, feed vidéo,
> défis, vote, classements, profil, missions, wallet, notifications.
> Le dépôt est désormais `bkd10/football-iq-universe`, app à la racine.


Ce document s'adresse au développeur qui reprend le projet. Il répond à
trois questions : qu'est-ce qui est fait et fonctionnel, qu'est-ce qui
reste à faire, et dans quel ordre s'y attaquer. Pour la documentation
technique détaillée (architecture, migrations, comment lancer l'app), voir
`README.md` — ce document-ci est un plan d'action, pas une doc technique.

## 1. Ce qui est fait (fonctionnel, testé, vérifié)

Tout ce qui suit compile (`flutter analyze` : 0 issue) et passe les tests
(`flutter test` : 6/6) au dernier commit. C'est une vraie app Flutter +
Supabase avec RLS complet, pas un prototype.

- **Compte joueur** : inscription/connexion/mot de passe oublié, profil
  (Football Passport), édition de profil, badges.
- **Feed vidéo** : scroll plein écran façon réseau social, like/Masterclass,
  commentaires, follow, partage, publication de vidéo (caméra/galerie,
  compression, upload).
- **Économie (Ballons/Stars)** : gains (connexion, publication, missions,
  Moves reproduits, défis gagnés) — tous expliqués en clair dans l'écran
  "Comment gagner des Ballons". Boutique visible mais achat désactivé (voir
  section 2).
- **Défis** : Battle/Challenge/King créables par un joueur avec une vraie
  cagnotte (les droits d'entrée des participants, reversée au gagnant) ;
  Défis Sponsorisés créables par un compte marque vérifié (prix réel décrit
  en texte, gratuit à créer/rejoindre) ; vote, résolution automatique
  (nécessite `pg_cron`, voir section 2).
- **Classements** (5 catégories, filtre région), **Moves** (fiche dédiée,
  reproduction, Moves du moment), **Pépite du Jour** (sélection anti-biais
  quotidienne).
- **Recherche**, **notifications** (nouvel abonné, like, commentaire, Move
  reproduit, badge, défi gagné, contact recruteur).
- **Messagerie recruteur ↔ joueur** avec médiation tuteur obligatoire pour
  les mineurs (lien d'approbation à usage unique).
- **Comptes Recruteur (scout)** et **Marque (brand)** : inscription
  dédiée, tableaux de bord autonomes, essai gratuit recruteur.
- **Modération** : bouton "Signaler" sur une vidéo et sur un profil,
  écran d'admin (`/admin/moderation`, réservé à `role = 'admin'` par RLS,
  attribué à la main dans Supabase) pour ignorer/agir sur un signalement.
- **Web** : compile et build (`flutter build web`) avec succès, cible
  prioritaire avant iOS/Android — voir README, section "Déploiement web
  (Netlify)". Toute l'API caméra/compression passe par
  `VideoSourceService` (implémentation mobile/web séparée), plus aucun
  `dart:io`/`File` dans le code partagé.
- **Suppression de compte réelle** (`delete_my_account`, écran Réglages) :
  supprime vraiment la ligne `auth.users` (cascade), pas un flag.

## 2. Ce qui reste — classé par dépendance, pas par importance

### 2.1 Bloqué sur une décision/ressource EXTERNE (le développeur ne peut
rien y faire seul — il te faudra fournir un compte/une décision)

| Sujet | Ce qu'il faut de ta part | Effort dev une fois débloqué |
|---|---|---|
| Paiement réel (achat de Ballons, abonnement recruteur payant) | Compte Stripe **et/ou** comptes développeur App Store + Play Store (pour les IAP natifs) | 2-4 jours (intégration `in_app_purchase` ou Stripe, Edge Function de validation de reçu) |
| Publication sur les stores | Compte Apple Developer (99 $/an) + Google Play Console (25 $ une fois) | 1-2 jours (fiches store, captures, révision Apple ~1-3 jours) |
| Déploiement Supabase en production | Créer le projet Supabase (gratuit pour démarrer), appliquer les 21 migrations dans l'ordre | 0.5 jour — vérifie aussi que le rôle `postgres` a bien le droit `DELETE` sur `auth.users` (nécessaire pour `delete_my_account`, voir `20260101000020_account_deletion.sql`) ; c'est le cas par défaut sur la plupart des projets Supabase actuels, mais pas testé sur un vrai projet ici |
| Déploiement web Netlify | Connecter le repo GitHub à Netlify + configurer `SUPABASE_URL`/`SUPABASE_ANON_KEY` en variables d'environnement Netlify | 0 (déjà prêt — `netlify.toml`, voir README section "Déploiement web") |
| Email transactionnel (approbation tuteur automatique par email, reset password personnalisé) | Compte Resend/Postmark/SendGrid | 0.5-1 jour (Edge Function d'envoi) |
| Vérification des comptes marque | Décider du process (manuel via dashboard Supabase pour commencer, suffisant au lancement) | 0 (déjà fonctionnel en mode manuel) |
| pg_cron pour la résolution des défis | Activer l'extension dans le dashboard Supabase (Database > Extensions), une checkbox | 0.1 jour |

**Sans ces éléments, le développeur ne peut pas "finir" ces sujets — ce
n'est pas du code manquant, ce sont des comptes/décisions qui t'appartiennent.**

### 2.2 Pur code, aucune dépendance externe — priorité recommandée

1. **Tester dans un vrai navigateur** (le web compile et build avec succès
   ici — `flutter build web`, vérifié — mais jamais ouvert dans un
   navigateur réel : parcours complet signup → confirmation e-mail →
   vidéo → défi → vote pas vérifié en conditions réelles). 0.5-1 jour.
   Ensuite seulement, **tests sur appareils réels** Android/iOS (caméra,
   upload, notifications push, permissions OS) — 1-2 jours. Voir l'ordre
   de construction du projet : web d'abord, mobile une fois le parcours
   web validé.
2. **Notifications push** (Firebase Cloud Messaging ou APNs/FCM via
   `firebase_messaging`) — actuellement les notifications n'existent que
   dans l'app (liste `NotificationsScreen`), rien n'est poussé si l'app est
   fermée. 2-3 jours.
3. **Onglet "Vestiaire"** du feed (abonnements uniquement) — actuellement
   un message "Bientôt disponible". Filtrage simple d'une requête déjà
   existante. 0.5 jour.
4. **Filtres Jour/Semaine/Mois** des classements — nécessite des snapshots
   périodiques des Stars (table + job planifié). 1 jour.
5. **Parrainage** (`invite_friend`) — nécessite une colonne de traçabilité
   "invité par" + un flux de code d'invitation. 1 jour.
6. **Comptes Club/Académie** — tables déjà prêtes
   (`organizations`/`organization_members`), aucune UI. 2-3 jours si tu en
   as besoin pour le lancement (sinon, à repousser).
7. **Analyse vidéo IA** (détection automatique de gestes techniques,
   PARTIE 6 de la spec technique) — gros chantier, nécessite un choix de
   modèle/service IA (Anthropic/OpenAI vision, ou modèle spécialisé sport).
   Pas nécessaire au lancement, à traiter après.
8. **Deep link mobile pour la confirmation d'e-mail** — le retour du lien
   de confirmation fonctionne sur web (`/auth/callback`, voir
   `AuthCallbackScreen`) ; sur mobile, `emailRedirectTo` retombe sur la
   Site URL du projet Supabase faute de custom URL scheme configuré
   (AndroidManifest/Info.plist) — le compte se confirme quand même, mais
   sans retour automatique dans l'app. À faire une fois les cibles mobiles
   activées (voir point 1). 0.5 jour.

### 2.3 Bugs connus / dette technique mineure

- Les fonctions économie/défis sont des fonctions Postgres `SECURITY
  DEFINER` plutôt que des Edge Functions Deno (choix délibéré, documenté
  dans le README) — fonctionnellement équivalent, à migrer seulement si un
  besoin de logique plus riche apparaît (anti-fraude avancée, régie pub).
- Pas de Supabase Realtime sur la messagerie (polling léger à la place) —
  suffisant pour un MVP, à améliorer si le volume de messages augmente.

## 3. Plan conseillé pour les 4 premiers jours

**Jour 1** : mise en place — déployer le projet Supabase (appliquer les 21
migrations dans l'ordre, activer `pg_cron`), connecter Netlify (voir
README, "Déploiement web") et vérifier le parcours complet dans un vrai
navigateur, configurer les 3 environnements (`--dart-define`, voir
README), corriger ce qui casse.

**Jour 2** : premier build sur appareil réel (Android + iOS si possible) —
caméra, upload, permissions — puis notifications push (FCM).

**Jour 3** : selon tes décisions de la section 2.1 — si tu fournis un
compte Stripe/App Store, démarrer l'intégration paiement ; sinon, avancer
sur les points de la section 2.2 (Vestiaire, filtres classement).

**Jour 4** : fiches App Store/Play Store, tests de bout en bout, point
avec toi sur ce qui est prêt à publier vs ce qui doit encore attendre un
paiement/une vérification store.

## 4. Comment démarrer

Voir `README.md`, sections "Prérequis avant de lancer l'app",
"Configuration Supabase" et "Lancer l'app en développement". Le code a été
vérifié avec Flutter 3.44.7 / Dart 3.12.2.

Règles inviolables du projet (voir README, section dédiée) — à ne jamais
enfreindre en ajoutant des fonctionnalités : Ballons/Stars ne sont
JAMAIS modifiables directement par le client, RLS sur toute nouvelle
table, contact avec un mineur toujours médié.
