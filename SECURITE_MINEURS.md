# Protection des mineurs : Football IQ (Bkd sport Ltd, Londres)

> **Ce document n'est pas un avis juridique.** Ce sont des mesures mises en place, à faire valider par un avocat britannique. Nulle part dans l'appli ni dans ce document il n'est écrit que l'appli est « conforme ».

Cadre pris en compte :
- UK Online Safety Act 2023 ;
- UK GDPR et Children's Code de l'ICO (Age Appropriate Design Code) ;
- règles Apple App Store et Google Play (applis pour ados, achats, contenus générés par les utilisateurs) ;
- Consumer Rights Act 2015 et Consumer Contracts Regulations 2013 ;
- droit à l'image ;
- CAP Code, qui impose de signaler la publicité.

Le principe suivi est de faire au moins ce que TikTok, Instagram et Twitch font pour les ados.

Le modèle du jeu ne change pas : défis, Battles, jetons (Ballons), Stars, carte, réputation et sponsors restent les mêmes. Seuls les réglages et les contrôles qui protègent les mineurs changent.

## Où se règlent les valeurs légales

Tout se règle dans `app_config`, clé `legal`. Rien n'est figé dans le code.

| Réglage | Valeur de départ | Effet |
|---|---|---|
| `min_age` | 13 | Âge minimum pour s'inscrire |
| `adult_age` | 18 | Âge à partir duquel le compte n'est plus mineur |
| `parental_consent_under` | 18 | En dessous, l'accord parental est obligatoire à l'inscription |
| `pro_min_age` | 18 | Âge minimum des comptes recruteur et marque |
| `country_rules` | `{}` | Règles par pays, ex. `{"france": {"min_age": 15}, "fr": {"min_age": 15}}` |
| `minor_purchases` | `disabled` | `disabled` : aucun achat avant 18 ans ; `parental_consent` : achat possible après l'accord d'un parent |
| `minor_monthly_limit_cents` | 5000 | Plafond mensuel des achats d'un mineur, en centimes |
| `parent_link_valid_days` | 7 | Durée de validité du lien envoyé au parent |
| `report_auto_hide_threshold` | 3 | Nombre de signalements distincts avant qu'une vidéo soit masquée |
| `strict_mode` | false, puis true à la publication | Date de naissance, CGU et droit à l'image obligatoires pour toutes les inscriptions et publications |
| `minor_defaults` / `adult_defaults` | voir la migration | Réglages de départ |

Exemple, pour passer l'âge minimum à 15 ans en France :

```sql
update app_config
set value = jsonb_set(value, '{country_rules}', '{"france": {"min_age": 15}, "fr": {"min_age": 15}}')
where key = 'legal';
```

## Mesures, emplacement dans le code et test

Code serveur : `supabase/migrations/20260101000037_minor_safety.sql`, désigné ci-dessous par « 0037 » suivi du numéro de section.

Deux suites de tests :
- **DB** : `supabase/tests/minor_safety_checks.py`, 77 vérifications sur une base de test locale, jamais sur la production ;
- **Flutter** : `test/minor_safety_test.dart` et `test/legal_test.dart`.

| # | Mesure | Où dans le code | Testé ? |
|---|---|---|---|
| 1 | Date de naissance obligatoire, âge minimum réglable (par pays), message clair dans les 10 langues | 0037 §1 (`private.check_age_rules`, `handle_new_user`, `get_age_rules`) ; `register_screen.dart` ; `AgeRules` dans `safety/domain/safety_models.dart` ; traductions dans `l10n/strings/minors.dart` | Oui : DB (refus à 12 ans, règle pays, mode compatible) et Flutter (`AgeRules`, traduction du message serveur) |
| 2 | Compte mineur marqué en base, mis à jour chaque nuit | 0037 §1 (`private.is_minor`, `refresh_minor_flags`, tâche cron `refresh-minor-flags`) | Oui : DB |
| 3 | Réglages par défaut des moins de 18 ans : profil limité, messages privés entre abonnés mutuels, pas de Battle aléatoire, ville cachée | 0037 §2 (`user_safety_settings`, `apply_default_safety_settings`) ; écran `safety_settings_screen.dart` | Oui : DB |
| 4 | Un mineur ne peut pas ouvrir ses messages privés à tout le monde | 0037 §2 (`update_my_safety_settings`) ; option masquée à l'écran | Oui : DB |
| 5 | Un adulte ne peut pas écrire en privé à un mineur sans abonnement mutuel | 0037 §5 (`private.can_private_message`, `request_scout_contact`, `send_message`) | Oui : DB |
| 6 | Une marque ne peut jamais écrire en privé à un mineur | 0037 §5 | Oui : DB |
| 7 | Profil limité : les inconnus ne voient ni la bio, ni la taille, ni le poids, ni les abonnés ; la ville n'apparaît que si le joueur le choisit | 0037 §4 (`get_public_profile`), §8 (`get_rankings`), §13 (`scout_search_players`) ; `profile_screen.dart` | Oui : DB |
| 8 | Bloquer depuis un profil, une vidéo, un commentaire ou un message. Un joueur bloqué ne voit plus, ne commente plus, ne suit plus et n'écrit plus | 0037 §3 (`user_blocks`, `block_user`, règles RLS, déclencheurs) ; `safety_menu.dart`, `feed_video_tile.dart`, `video_detail_screen.dart`, `comments_sheet.dart`, `conversation_screen.dart`, `profile_screen.dart` | Oui pour le serveur (DB). Les boutons n'ont été vérifiés que par l'analyse du code |
| 9 | Signaler une vidéo, un commentaire, un profil ou un message, avec un champ de précisions | 0037 §6 (`report_content`) ; `report_content_sheet.dart` | Oui : DB |
| 10 | File de modération : statut, date et auteur du traitement, mineurs affichés en premier, onglets « En attente » et « Traités » | 0037 §6 (`admin_moderation_queue`, `admin_resolve_report`) ; `admin_moderation_screen.dart` | Oui pour le serveur (DB). L'écran n'a pas été testé |
| 11 | Une vidéo signalée par 3 personnes est masquée tout de suite, en attendant la décision | 0037 §6 (`private.auto_hide_reported`) | Oui : DB |
| 12 | Achats de Ballons désactivés pour les mineurs, ou possibles avec l'accord d'un parent (lien à usage unique, plafond mensuel) | 0037 §9 (`can_purchase`, `prepare_purchase`, `request_parent_purchase_consent`, `answer_parent_consent`) ; `shop_screen.dart`, `wallet_screen.dart`, `parent_consent_screen.dart` | Oui pour le serveur (DB, refus de l'achat à un mineur et lien parent). Les écrans n'ont pas été testés |
| 13 | Aucun prix ni pack montré à un mineur qui ne peut pas acheter, pas de bouton Boutique, prix réel toujours affiché pour les autres | `shop_screen.dart` (`_MinorShopNotice`), `wallet_screen.dart` | Test Flutter sur la règle `hideShop`, pas sur l'écran |
| 14 | Séries sans perte pour les mineurs : un jour manqué ne remet pas la série à zéro | 0037 §10 (`private.gentle_streak`) | Oui : DB |
| 15 | Séries et comptes à rebours masquables, masqués par défaut chez les moins de 18 ans | `daily_missions_screen.dart`, `challenge_card.dart`, `challenge_detail_screen.dart`, `Formatters.challengeTime` | Analyse du code seulement |
| 16 | Rappel de pause après 45 minutes (réglable de 0 à 90), sans récompense ni pénalité | `break_reminder.dart`, branché dans `main_shell.dart` | Analyse du code seulement |
| 17 | Défi sponsorisé marqué « Sponsorisé », avec une explication sur la page du défi | `challenge_card.dart` (déjà en place), `challenge_detail_screen.dart` | Analyse du code seulement |
| 18 | Aucune coordonnée d'un mineur visible : pas de GPS, ville cachée, e-mail du parent jamais lisible | 0037 §4, §8 et §13 ; table `guardian_contacts` (fermée) | Oui : DB |
| 19 | Droit à l'image : case obligatoire avant publication, avec un texte sur la propriété de la vidéo et ce qu'un sponsor peut en faire | `create_screen.dart` ; `video_remote_datasource.dart` (`rights_confirmed_at`) ; 0037 §11 | Oui pour le serveur (DB, refus en mode strict). La case n'a pas été testée |
| 20 | Battles aléatoires seulement si le joueur accepte, et jamais contre un joueur bloqué | 0037 §7 (`create_battle`, `battle_opponent_suggestions`) | Oui : DB |
| 21 | Pages : confidentialité avec un résumé pour les jeunes, CGU, Sécurité et aide (999, 112, Childline), mentions légales Bkd sport Ltd | `legal/data/legal_texts.dart`, `legal_info.dart`, `legal_screen.dart` (`securite`) | Oui : Flutter (aucun champ oublié, société et ville présentes, aucun « conforme ») |
| 22 | La suppression de compte efface le profil, les réglages, les blocages, les consentements et l'e-mail du parent | fonction existante `delete_my_account`, plus les clés étrangères en cascade de 0037 | Oui : DB |

### Lancer les tests

```bash
sudo bash supabase/tests/local_db/build_test_db.sh   # base de TEST locale (PostgreSQL)
python3 supabase/tests/minor_safety_checks.py         # 77 vérifications
flutter analyze && flutter test                        # 26 tests
```

Résultat au 2026-11-19 :
- base de test : 77/77 OK ;
- `flutter analyze` : aucun problème ;
- `flutter test` : 26/26 OK.

Ce qui n'est **pas testé automatiquement** :
- les écrans eux-mêmes (boutons, case, rappel de pause, bandeaux) : à vérifier à la main sur la version test ;
- le parcours Stripe réel ;
- l'envoi du lien au parent, qui est aujourd'hui copié et partagé par le joueur et n'est pas envoyé par e-mail.

## Fichiers SQL à lancer (Supabase, SQL Editor), dans l'ordre

Les fichiers sont dans `mineurs/`, dans les fichiers du projet.

1. **`mise_a_jour_mineurs_1_maintenant.sql`**, à lancer **avant de tester la version test**.
   - Il installe tout le côté serveur avec `strict_mode = false`, donc le site en ligne continue de fonctionner comme aujourd'hui.
   - Il peut être relancé sans risque.
2. **`verifier_mineurs.sql`** : lecture seule, chaque ligne doit afficher OK, et `strict_mode` doit valoir false.
3. **`mise_a_jour_mineurs_2_publication.sql`**, à lancer **seulement après la publication de la nouvelle appli** :
   - il active les contrôles stricts ;
   - il ferme la lecture directe de la bio, de la ville, de la taille et du poids ;
   - il remplace le relâchement des CGU de `a_lancer_maintenant.sql`.

Ces trois fichiers ont été essayés sur une copie de test qui imite la production : toutes les migrations précédentes, puis `a_lancer_maintenant.sql`. Résultats :
- l'ancienne appli peut toujours inscrire des joueurs après le fichier 1 ;
- le fichier 1 peut être relancé ;
- après le fichier 2, une inscription sans CGU est refusée et la bio n'est plus lisible.

## Ce qui dépend de Tom

- **Informations de la société**, à remplir dans `lib/features/legal/data/legal_info.dart`. Tant qu'un champ est vide, les pages affichent « [à compléter] ». Champs concernés :
  - numéro Companies House ;
  - lieu d'immatriculation ;
  - adresse du siège ;
  - numéro de TVA (ou « non assujetti ») ;
  - numéro d'enregistrement ICO ;
  - e-mail de contact ;
  - e-mail sécurité ;
  - représentant dans l'UE, si l'appli vise la France ;
  - organisme de règlement des litiges (ADR).
- **Enregistrement auprès de l'ICO** (data protection fee) : une démarche faite par la société.
- **Stripe** : les prix en livres sterling pour le Royaume-Uni, et la page de paiement qui affiche la renonciation au délai de rétractation.
- **E-mails aux parents** : aujourd'hui, le lien d'accord parental est copié par le joueur. Un envoi automatique demande un service d'e-mail (Resend, Postmark…).
- **Avocat britannique** : relecture des CGU, de la politique de confidentialité, des mentions légales et de la page Sécurité.

## Questions pour l'avocat

1. **Vidéos des mineurs visibles dans le fil et les défis.** Le profil limité cache les détails, mais les vidéos restent publiques, car c'est le cœur du jeu. Est-ce acceptable au regard du Children's Code ? Faut-il plutôt rendre les vidéos des moins de 16 ans privées par défaut, comme TikTok le fait pour les 13-15 ans ?
2. **Âge minimum.** Il est fixé à 13 ans au Royaume-Uni. Faut-il 15 ans pour la France (majorité numérique) ? Le réglage par pays existe déjà.
3. **Accord parental.** Aujourd'hui il repose sur une case cochée et l'e-mail d'un parent. Ce niveau de vérification suffit-il pour l'inscription et pour les achats ?
4. **Représentant dans l'UE** (article 27 du RGPD) : est-il nécessaire si des joueurs français sont visés ?
5. **Online Safety Act.** Il faut faire les évaluations demandées par l'Ofcom : illegal content risk assessment et children's access assessment, puis children's risk assessment. Faut-il aussi une vérification d'âge plus forte que la date déclarée ?
6. **Achats par des mineurs.** Faut-il garder `disabled` ou passer en `parental_consent` ? Le plafond de 50 € par mois est-il adapté ?
7. **Droit à l'image et sponsors.** Le texte du point 19 suffit-il ? Faut-il un contrat séparé, signé par le parent, avant toute réutilisation par un sponsor ?
