# Football IQ Universe

Plateforme mobile de développement du talent footballistique — Flutter +
Supabase. Voir le prompt maître de développement (spécification technique
complète v2.0) pour la vision produit complète.

> **Audit de sécurité d'octobre 2026** : voir [`SECURITY_AUDIT.md`](SECURITY_AUDIT.md)
> (failles trouvées et corrigées, testées par `supabase/tests/security_checks.py`).

## 🚀 Mettre le jeu en ligne pour l'essayer (sans être développeur)

Il faut deux comptes gratuits : **Supabase** (la base de données) et
**Netlify** (l'hébergement du site). Compte environ 30 minutes.

### 1. Créer la base de données (Supabase)

1. Va sur [supabase.com](https://supabase.com) → *New project*. Choisis une
   région en Europe (Paris ou Francfort) et note bien le mot de passe de la
   base.
2. Installe la base. Le plus simple, depuis un ordinateur avec
   [Node.js](https://nodejs.org) installé, dans le dossier du dépôt :
   ```bash
   npx supabase login
   npx supabase link --project-ref TON_ID_DE_PROJET   # visible dans l'URL du dashboard
   npx supabase db push                               # applique les 22 migrations
   ```
   Sans Node.js (le plus simple) : dans le dashboard, *SQL Editor* →
   *New query*, colle **tout** le contenu de `supabase/install_all.sql`
   (toutes les migrations + la planification des défis) et clique *Run*.
   Une seule fois, sur un projet vide. L'étape 3 ci-dessous est alors déjà
   faite.
3. *Database → Extensions* : active **pg_cron**, puis dans *SQL Editor* :
   ```sql
   select cron.schedule('resolve-expired-challenges', '*/15 * * * *',
     'select resolve_expired_challenges();');
   ```
   (sinon les défis terminés ne désignent jamais de gagnant).
4. *Authentication → Sign In / Providers → Email* : laisse **Confirm email**
   activé (le bonus de 500 Ballons n'est versé qu'après confirmation).
5. *Project Settings → API* : copie l'**URL du projet** et la clé
   **anon / publishable**. (Ne copie jamais la clé `service_role` / secret
   ailleurs que dans Supabase.)

### 2. Mettre le site en ligne (Netlify)

1. Va sur [app.netlify.com](https://app.netlify.com) → *Add new site* →
   *Import an existing project* → GitHub → `bkd10/football-iq-universe`.
   Laisse les réglages proposés (ils viennent de `netlify.toml`).
2. Avant de lancer : *Site configuration → Environment variables*, ajoute
   `SUPABASE_URL` et `SUPABASE_ANON_KEY` (copiées à l'étape 1.5).
3. *Deploy*. Le premier build prend quelques minutes (il installe Flutter).
4. Retourne dans Supabase, *Authentication → URL Configuration* : mets
   l'adresse Netlify (ex. `https://football-iq.netlify.app`) en **Site URL**
   et ajoute `https://football-iq.netlify.app/**` dans **Redirect URLs**,
   pour que le lien de confirmation d'e-mail ramène dans l'app.

### 3. Jouer

Ouvre l'adresse du site sur ton téléphone, crée un compte, confirme
l'e-mail, publie une vidéo. Pour te donner l'accès administrateur, dans
*SQL Editor* :
```sql
update profiles set role = 'admin' where username = 'TON_PSEUDO';
```
puis ferme et rouvre le jeu : **Réglages → Administration** (statistiques,
signalements avec messages pré-écrits, joueurs et bannissement, défis
officiels).

### Mettre à jour une base déjà installée

Quand une nouvelle migration arrive dans `supabase/migrations/`, colle
seulement ce fichier-là dans *SQL Editor* puis *Run*. Exemple : le panneau
admin a besoin de `20260101000022_admin_panel.sql`.

## État actuel (Phase 0 + Semaines 1-8 du planning — MVP fonctionnellement complet)

Ce qui est en place :

- Structure Flutter en Clean Architecture (`core/` + `features/*/data|domain|presentation`)
- Design System (couleurs, typographie Montserrat/Inter/Space Mono via
  `google_fonts`, thème dark mode, espacements, widgets réutilisables)
- Configuration multi-environnement (dev/staging/prod) par `--dart-define`
- Feature flags chargés depuis Supabase (`app_config`)
- Schéma Supabase complet (18 tables), RLS sur toutes les tables, triggers
  (niveau automatique, compteurs dénormalisés, provisioning de profil),
  policies `storage.objects`, RPC économie/vues/missions (voir plus bas)
- Authentification complète : inscription, connexion, mot de passe oublié,
  déconnexion (Clean Architecture : entités Freezed, repository, usecases,
  providers Riverpod)
- Navigation GoRouter avec redirect automatique selon l'état de session,
  onboarding (3 écrans), shell principal à 5 onglets
- **Feed vidéo réel** : scroll vertical plein écran, lecture/pause,
  double-tap pour liker, like/Masterclass (mutuellement exclusifs, comme le
  définit le schéma), commentaires (bottom sheet), follow/unfollow, mise à
  jour optimiste de l'UI, pagination infinie, comptage de vues anti-triche
- **Publication vidéo** : caméra ou galerie, validation de durée (15-60s),
  formulaire caption/catégorie/Move, upload Supabase Storage — toute l'API
  native (`image_picker`, compression `video_compress`, lecture d'un
  fichier local) passe par `VideoSourceService`
  (`lib/core/services/video_source/`), jamais appelée directement depuis
  un écran. Deux implémentations sélectionnées à la compilation (import
  conditionnel Dart) : mobile (caméra + compression réelle) et web
  (sélecteur de fichiers du navigateur, sans compression côté client —
  `video_compress` n'a pas d'équivalent web). C'est ce qui permet au même
  écran `CreateScreen` de compiler et fonctionner sur les deux cibles.
- **Économie (Ballons)** : RPC `award_coins`/`spend_coins` (connexion
  quotidienne avec streak, récompense de publication, pub — dépenses
  prêtes pour les défis à venir), Wallet (solde + historique), profil
  toujours à jour après une transaction (`currentProfileProvider`)
- **Missions quotidiennes** : connexion, publication, 3 vidéos regardées,
  streak, écran dédié avec barre de progression
- **Football Passport** : Ballons/Stars/Football IQ, 5 dimensions IQ,
  onglets Vidéos / Moves créés / Badges
- **Moves** : fiche dédiée (créateur crédité, stats, meilleures
  reproductions), reproduction depuis la fiche (pré-remplit l'écran de
  création), +1 Ballon à l'inventeur à chaque reproduction, Moves du moment
- **Défis** : Battle/Challenge/King créables par les joueurs (Monde et
  Sponsorisé restent officiels), liste filtrable par type, participation
  avec une vidéo existante, vote (un par défi et par joueur), King Challenge
  avec record en vedette, résolution automatique (`resolve_expired_challenges`
  — gagnant par votes ou par record, distribution du prize_pool, +100
  Stars, notification)
- **Classements** : 5 catégories (IQ Football, Technique, Créativité,
  Popularité, Régularité), filtre région (Mondial / mon pays / ma ville),
  ligne personnelle mise en évidence
- Écrans : Splash, Onboarding, Login, Register, Forgot Password, Profil,
  Feed, Créer, Wallet, Missions du jour, Fiche Move, Moves du moment,
  Défis (liste/détail/création), Classements

Ce qui reste au-delà du MVP initial (PARTIE 20) : notifications, Ballon
d'Or hebdomadaire / Next Football Star, Pépite du Jour, comptes
Scout/Club/Académie (Phase 2/3, désactivés par feature flags dès la
conception), analyse vidéo IA.

### Correctif de sécurité important de cette passe

Les policies RLS `USING (auth.uid() = id/user_id)` sur `profiles` et
`videos` (Phase 0) autorisaient un `UPDATE` client direct sur
**n'importe quelle colonne** de sa propre ligne — y compris `coins`,
`stars`, `iq_*`, `talent_score`, `status`, etc. RLS ne filtre que les
lignes, pas les colonnes. La migration
`20260101000009_protect_profile_columns.sql` révoque le privilège
`UPDATE` et le regrant uniquement sur les colonnes réellement éditables
par l'utilisateur (nom, bio, avatar... / caption, catégorie, Move). Les
fonctions `SECURITY DEFINER` ne sont pas affectées : elles s'exécutent
avec les privilèges du propriétaire de la fonction, pas ceux de
l'appelant. **Cette migration doit être appliquée dès que possible sur
tout environnement où les migrations précédentes ont déjà tourné.**

### Limites connues

- `increment_video_views`, `award_coins`, `spend_coins`,
  `increment_videos_watched`, `join_challenge`, `create_challenge`,
  `vote_for_participant` et `resolve_expired_challenges` sont implémentées
  comme des fonctions Postgres `SECURITY DEFINER` plutôt que comme les
  Edge Functions TypeScript/Deno décrites en PARTIE 4.2 — même garantie
  anti-triche (`auth.uid()` lu depuis le JWT vérifié par PostgREST, jamais
  fourni par le client), sans dépendre d'un runtime Deno impossible à
  exécuter ou tester dans cet environnement. À migrer vers de vraies Edge
  Functions si une logique plus riche devient nécessaire (régie pub
  externe, rate limiting applicatif, anti-fraude avancée).
- `resolve_expired_challenges` n'est PAS planifiée automatiquement :
  l'extension `pg_cron` doit être activée depuis le dashboard Supabase
  (Database > Extensions) puis la ligne `cron.schedule(...)` en commentaire
  en bas du fichier `20260101000008_challenges_rpc.sql` doit être exécutée
  manuellement.
- Depuis `20260101000012_challenge_prize_pool.sql`, les défis créés par des
  joueurs ONT une vraie cagnotte : chaque droit d'entrée payé via
  `join_challenge` s'ajoute à `prize_pool`, reversé en entier au vainqueur
  par `resolve_expired_challenges`. Le créateur ne fixe jamais la cagnotte
  lui-même (pas de champ dans l'écran de création) — seule la somme des
  entrées réelles la constitue, pour ne jamais émettre de Ballons non
  adossés à une dépense réelle.
- La Boutique (`ShopScreen`, accessible depuis le Wallet) affiche des packs
  de Ballons à titre indicatif avec un bouton d'achat désactivé : aucun
  moyen de paiement réel (App Store/Play Store/Stripe) n'est branché. Le
  flag `paymentsEnabled` dans `feature_flags.dart` reste à `false` tant que
  ça n'est pas le cas.
- `invite_friend` (parrainage) n'est pas implémenté : la table `profiles`
  n'a pas de colonne de traçabilité "qui a invité qui", indispensable pour
  valider la récompense sans risque de triche.
- Les classements ne supportent que "Tout temps" : les filtres Jour/
  Semaine/Mois nécessiteraient un historique des Stars (snapshots
  périodiques) que le schéma MVP ne conserve pas encore.
- Les onglets "Vestiaire" et "Tendances" du feed (PARTIE 8.1, renommés
  depuis "Suivis"/"Pour toi" pour s'éloigner du vocabulaire TikTok) affichent
  un message "Bientôt disponible" pour "Vestiaire" — seul "Ouverture"
  (algorithme Talent First) est branché ; "Tendances" renvoie déjà vers
  l'écran dédié "Trending Moves", qui lui est pleinement fonctionnel.
- Les comptes club/académie (`clubAccountsEnabled`/`academyAccountsEnabled`)
  restent désactivés — aucune UI, contrairement à scout/brand (voir la
  section messagerie/scouting/marque ci-dessous pour ce qui EST branché).
- L'essai recruteur (`start_scout_trial`) est à usage unique et gratuit
  (14 jours) : aucun vrai paiement Stripe n'est branché derrière
  `scout_subscriptions.stripe_subscription_id`, resté `null`.
- La vérification d'un compte marque (`profiles.is_verified`) reste
  manuelle (mise à jour directe en base par un admin) — aucun flux de
  vérification automatique (documents, validation e-mail pro...) n'existe.

### Ajouté depuis la dernière revue complète

En comparant le code au prototype visuel + à la checklist de build fournis
par l'équipe produit, plusieurs écrans prévus par la spec (PARTIE 9.2)
manquaient entièrement. Ajoutés :

- **Pépite du Jour** (écran 6, PARTIE 8.9) : sélection anti-biais (RPC
  `get_pepite_of_the_day`, migration `20260101000010`) parmi les vidéos
  récentes à fort `talent_score` de profils encore peu suivis, tirage
  déterministe par jour. S'affiche désormais à chaque entrée dans l'app
  authentifiée (voir le `redirect` de `AppRouter`), avant le feed.
- **Video Detail** (écran 8) : les vignettes du profil, de la fiche Move et
  de "Trending Moves" ouvrent maintenant un vrai lecteur plein écran
  (like/Masterclass/commentaires/partage) au lieu d'un message "à venir".
- **Other Profile** (écran 23) : Football Passport public en lecture seule
  d'un autre joueur, avec bouton Suivre — accessible en tapant un nom
  d'utilisateur dans le feed, une ligne de classement, ou une notification.
  `ProfileScreen` sert maintenant les deux cas (mon profil / profil d'un
  autre) selon qu'un `userId` est fourni.
- **Edit Profile** (écran 24) : formulaire de modification (nom affiché,
  bio, pays, ville, poste, pied fort) — n'écrit que les colonnes autorisées
  par `protect_profile_columns` (jamais `coins`/`stars`/`level`/`iq_*`).
- **Notifications** (écran 31) : nouvel abonné, like, Masterclass,
  commentaire, Move reproduit, badge débloqué, défi gagné. La table
  existait déjà dans le schéma mais rien n'y écrivait jamais (seul
  `challenge_won` était émis, depuis `resolve_expired_challenges`) — cinq
  triggers ajoutés (migration `20260101000011`) la peuplent réellement.
  Icône cloche avec pastille de compteur non lu sur l'écran Feed.
- **Search** (écran 34) : recherche de joueurs (par username) et de Moves
  (par nom), icône loupe sur l'écran Feed.
- **Settings** (écran 33) : compte, lien vers Edit Profile, rappel
  protection des mineurs, déconnexion — volontairement minimal (pas de
  CGU/confidentialité placeholder qui n'existeraient pas réellement).
- Bouton "Partager" du feed (et de Video Detail) : ouvrait le partage
  natif de rien du tout (`onTap: () {}`) — branché sur `share_plus`.
- Ligne de classement : ne menait nulle part au tap — ouvre maintenant le
  Football Passport du joueur concerné.
- **Économie des Ballons rendue claire** : gagner des Ballons était possible
  mais éclaté entre plusieurs écrans sans jamais être expliqué — nouvel
  écran **"Comment gagner des Ballons"** (`EarnBallonsScreen`) qui liste
  chaque méthode réellement fonctionnelle avec son montant exact, et sépare
  clairement celles annoncées mais pas encore actives (pub, parrainage).
  Nouvel écran **Boutique** (`ShopScreen`) montrant les packs de Ballons
  prévus avec achat désactivé ("Bientôt disponible"), en attendant un vrai
  moyen de paiement — les deux accessibles depuis le Wallet.
- **Cagnotte des Battles/Défis rendue réelle et expliquée** : les défis
  créés par un joueur n'avaient jamais de vraie cagnotte (les Ballons des
  perdants étaient simplement perdus, sans le dire) — `join_challenge`
  alimente maintenant `prize_pool` avec chaque droit d'entrée (migration
  `20260101000012`), intégralement reversé au vainqueur. Un bug était aussi
  présent : la raison de transaction restait `join_challenge` même pour une
  Battle, empêchant le libellé "Participation à une Battle" de jamais
  s'afficher dans l'historique — corrigé dans la même migration. Les règles
  (coût d'entrée, constitution de la cagnotte, désignation du vainqueur par
  votes) sont maintenant écrites en clair sur l'écran de détail et de
  création du défi, plus l'écran de création qui affiche l'entrée réelle
  correspondant au type choisi.
- **Messagerie recruteur ↔ joueur** (PARTIE 8.4/8.5, comptes Scout — jusque
  là uniquement des tables SQL prévues mais jamais branchées à aucun flux) :
  - Inscription recruteur (case à cocher "Je suis recruteur / scout" sur
    l'écran d'inscription) : le rôle vient d'un allowlist strict côté
    serveur (`handle_new_user`), un client ne peut jamais s'auto-attribuer
    `admin` ou un autre rôle.
  - Tableau de bord recruteur autonome (`ScoutHomeScreen`, coquille de
    navigation à part de `MainShell` — 3 onglets : Recherche/Messages/
    Compte) : recherche de joueurs par pseudo/poste/pays
    (`scout_search_players`, qui ne renvoie jamais de date de naissance
    exacte — seulement `is_minor`), essai gratuit de 14 jours
    (`start_scout_trial`, aucun paiement réel branché — même principe que
    la Boutique), bouton "Demander le contact" sur le Football Passport
    public (remplace l'ancien message informatif pour un visiteur recruteur
    avec abonnement actif).
  - **Le contact avec un mineur n'est jamais direct** : `request_scout_contact`
    exige le contact d'un tuteur (`guardian_contacts`, table séparée de
    `profiles` — `profiles` étant publiquement lisible, y mettre l'email
    d'un tuteur l'aurait exposé à quiconque consulte un Football Passport)
    et démarre la conversation en `pending_guardian_approval`. Le tuteur
    (qui n'a pas forcément de compte) approuve/refuse via un lien à usage
    unique (`GuardianApprovalScreen`, accessible sans connexion à
    `/guardian-approval` ou `/guardian-approval/:token`) ; sans service
    d'email transactionnel configuré, ce lien est transmis manuellement par
    le joueur (bouton "Copier le lien pour ton tuteur" dans la conversation
    en attente, qui prépare un message prêt à coller dans SMS/WhatsApp)
    plutôt que simulé par un faux envoi automatique.
  - Boîte de réception commune (`InboxScreen`) et fil de discussion
    (`ConversationScreen`, rafraîchissement par polling léger — pas de
    Supabase Realtime branché pour ce MVP) partagés entre joueur et
    recruteur ; icône messages sur l'écran Feed et dans Réglages.
  - Migration `20260101000013_scouting_messaging.sql` : tables
    `conversations`/`messages`/`guardian_contacts` (RLS complète), fonctions
    `request_scout_contact`/`approve_guardian_contact`/
    `decline_guardian_contact`/`send_message`/`start_scout_trial`/
    `scout_search_players`/`get_guardian_approval_token`.
- **Défis Sponsorisés en libre-service pour les marques** (PARTIE 8.3,
  `role='brand'`) : jusque-là un type théorique que `create_challenge`
  rejetait explicitement (aucune UI, aucun compte marque).
  - Inscription marque (même case à cocher que recruteur, désormais un
    choix à 3 : Joueur/Recruteur/Marque), tableau de bord autonome
    (`BrandHomeScreen` : liste de mes défis + création, compte/vérification).
  - Un défi sponsorisé est gratuit à créer ET à rejoindre (aucun Ballon
    débité ni distribué, `prize_currency = 'real'`) : le prix est un texte
    libre (`prize_description`, ex. "une paire de crampons") que la marque
    remet elle-même au vainqueur, hors de l'app — aucune dépendance à un
    moyen de paiement in-app. Réservé à un compte marque **vérifié**
    (`profiles.is_verified`, activé manuellement par un admin, même
    principe que `organizations.is_verified`).
  - `CreateChallengeScreen` s'adapte selon le rôle du compte connecté
    (champ prix textuel + aucun coût de création pour une marque) plutôt
    que de dupliquer un second écran de création.
  - Migration `20260101000014_sponsored_challenges.sql` : colonne
    `challenges.prize_description`, `handle_new_user` accepte `role='brand'`,
    `create_challenge` accepte `type='sponsored'` sous condition de rôle et
    de vérification.

## ⚠️ Prérequis avant de lancer l'app

Le code a été vérifié avec le SDK Flutter 3.44.7 / Dart 3.12.2 :
`flutter analyze` ne remonte **aucune erreur ni avertissement** et
`flutter test` passe. Il manque en revanche les dossiers de plateforme
natifs (android/, ios/, etc.), absents du repo et non générables sans SDK
Android/Xcode. Avant de lancer l'app localement :

```bash
# 1. Génère les dossiers de plateforme (android/, ios/, etc.) — absents du repo
flutter create . --project-name football_iq_universe --org com.footballiquniverse --platforms android,ios

# 2. Installe les dépendances
flutter pub get

# 3. Génère les fichiers Freezed / json_serializable (*.freezed.dart, *.g.dart)
dart run build_runner build --delete-conflicting-outputs

# 4. Vérifie que tout compile toujours après `flutter create .`
flutter analyze
flutter test
```

Après `flutter create .`, il faudra probablement configurer les **flavors**
natifs (productFlavors Gradle côté Android, schemes Xcode côté iOS) pour
`dev`/`staging`/`prod` — la structure Dart (`main_dev.dart`,
`main_staging.dart`, `main_prod.dart`, `AppConfig`) est déjà prête à les
recevoir.

## Configuration Supabase

1. Crée un projet Supabase (ou utilise la CLI en local : `supabase start`
   depuis la racine du dépôt, qui lira `supabase/config.toml`).
2. Applique les migrations :
   ```bash
   supabase db push
   # ou en local : supabase migration up
   ```
   Les migrations sont dans `supabase/migrations/`, dans l'ordre :
   - `20260101000000_initial_schema.sql` — 18 tables
   - `20260101000001_rls_policies.sql` — Row Level Security
   - `20260101000002_triggers.sql` — niveaux, compteurs, provisioning profil
   - `20260101000003_seed_data.sql` — feature flags, économie, badges
   - `20260101000004_storage_and_reactions.sql` — policies Storage, trigger
     de changement de type de réaction, RPC `increment_video_views`
   - `20260101000005_economy_rpc.sql` — RPC `award_coins`/`spend_coins`
   - `20260101000006_daily_missions_rpc.sql` — RPC `increment_videos_watched`
   - `20260101000007_move_reproduction_reward.sql` — +1 Ballon à l'inventeur
     d'un Move reproduit
   - `20260101000008_challenges_rpc.sql` — RPC défis (join/create/vote/
     resolve) + durcissement RLS `challenges`/`challenge_participations`
   - `20260101000009_protect_profile_columns.sql` — **correctif de
     sécurité**, voir plus haut — à appliquer en priorité
   - `…0010` à `…0020` — voir l'en-tête de chaque fichier
   - `20260101000021_security_audit_fixes.sql` — corrections de l'audit
     d'octobre 2026, voir `SECURITY_AUDIT.md`
3. Les buckets Storage `videos`, `avatars`, `thumbnails` et leurs limites
   sont créés par la migration `…0021` (et par `supabase/config.toml` en
   local).
4. Copie `env/dev.json.example` vers `env/dev.json` (et de même pour
   staging/prod) en renseignant `SUPABASE_URL` et `SUPABASE_ANON_KEY`. Ces
   fichiers `env/*.json` sont ignorés par git — ne jamais committer de clé.

## Lancer l'app en développement

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
```

## Déploiement web (Netlify)

Le web est la cible prioritaire : à valider entièrement avant tout passage
à iOS/Android (même code Dart, mêmes services/repositories — seule
`VideoSourceService`, voir plus bas, a une implémentation par plateforme).
`netlify.toml`, à la racine, configure tout le nécessaire — Netlify n'a pas
Flutter préinstallé, la commande de build clone le SDK (version 3.44.7,
figée) avant de compiler.

**Pour publier l'adresse réelle**, il ne reste que des actions côté
tableau de bord Netlify (aucune clé secrète n'est commitée, volontairement) :

1. Sur [app.netlify.com](https://app.netlify.com), "Add new site" →
   "Import an existing project" → connecte le repo GitHub
   `bkd10/football-iq-universe` (l'app est à la racine du dépôt, aucun
   "Base directory" à renseigner).
2. Netlify détecte `netlify.toml` automatiquement (build command +
   `publish = "build/web"`).
3. Site configuration → Environment variables, renseigne `SUPABASE_URL`,
   `SUPABASE_ANON_KEY` (celles du projet Supabase de PRODUCTION, pas dev) et
   `SENTRY_DSN` (optionnel).
4. "Deploy site" — chaque push sur la branche connectée redéploie
   automatiquement ensuite.

Vérifié dans cet environnement : `flutter build web --release
--dart-define=ENVIRONMENT=prod --dart-define=SUPABASE_URL=... \
--dart-define=SUPABASE_ANON_KEY=...` compile avec succès (`✓ Built
build/web`) — c'est la même commande que `netlify.toml` exécute. Non
vérifié : le déploiement Netlify lui-même (ce bac à sable n'a pas accès à
netlify.com), et le fonctionnement réel dans un navigateur (jamais ouvert
sur un vrai poste — voir HANDOFF.md).

## Règles inviolables du projet (rappel)

- Les **Stars** (Football IQ) ne sont **jamais** achetables — aucun paiement
  ne peut les augmenter.
- L'économie (**Ballons**/Stars) ne se modifie que via des Edge Functions
  (`service_role`) — jamais par un `UPDATE` client direct sur `coins`/`stars`.
- RLS activée sur **toutes** les tables.
- Gratuit à l'entrée, monétisation après engagement.
- Protection des mineurs dès le MVP (consentement parental < 16 ans, contact
  scout → joueur toujours médié).

## Architecture

```
lib/
├── core/           # config, thème, constantes, erreurs, utils, widgets partagés, router
├── features/
│   ├── auth/       # data/domain/presentation — complet
│   ├── videos/     # feed/likes/commentaires/upload/Moves — complet
│   ├── feed/       # presentation — consomme le domain de videos/
│   ├── economy/    # RPC award/spend-coins, Wallet — complet
│   ├── missions/   # missions quotidiennes, streak — complet
│   ├── moves/      # fiche Move, Moves du moment — complet (presentation ; domain dans videos/)
│   ├── profile/    # follow/unfollow, badges, Football Passport — complet
│   ├── challenges/ # Battle/Challenge/King, votes, résolution — complet
│   ├── rankings/   # 5 catégories, filtre région — complet
└── shared/         # providers et modèles transverses
supabase/
├── migrations/     # schéma, RLS, triggers, seed
└── config.toml     # config Supabase CLI (dev local)
```

Chaque feature suit `data/domain/presentation` (Clean Architecture) : le
domain ne dépend de rien, la data implémente les interfaces du domain, la
presentation consomme le domain via Riverpod.
