# Audit de sécurité — octobre 2026

Audit complet du backend Supabase (21 migrations) et des appels faits par
l'app Flutter. Méthode : la base a été **réellement installée** (Supabase
local, `supabase start`), puis attaquée par des appels HTTP directs, comme
le ferait n'importe qui avec la clé anonyme publique de l'app. Chaque
problème ci-dessous a été **reproduit avant correction**, puis vérifié
corrigé par `supabase/tests/security_checks.py` (38/38 vérifications OK).

## Résultat en une phrase

La base ne s'installait pas, les actions de base (suivre, liker, commenter,
publier) étaient cassées, et plusieurs failles permettaient de fabriquer des
Ballons à l'infini ou d'exposer des mineurs. Tout est corrigé dans
`supabase/migrations/20260101000021_security_audit_fixes.sql` (+ quelques
lignes côté app).

## Bloquants (l'app ne marchait pas)

| # | Problème | Correctif |
|---|---|---|
| 1 | La migration `…0013` plantait (`position` est un mot réservé SQL) : **aucune base ne pouvait être installée**. | Nom de colonne entre guillemets. |
| 2 | Suivre, liker, commenter, publier une vidéo : **toutes échouaient** (`permission denied for table profiles`). Les triggers de compteurs tournaient avec les droits du joueur, retirés par la migration `…0009`. | Triggers passés en `SECURITY DEFINER`. |
| 3 | Basculer un like en Masterclass échouait (aucune règle UPDATE sur `likes`). | Règle ajoutée (colonne `type` seulement). |
| 4 | Supprimer son compte échouait toujours (Supabase interdit le `DELETE` direct dans `storage.objects`). | Les fichiers sont supprimés par l'app via l'API Storage, puis le compte. |
| 5 | `find_ledger_drift` (contrôle comptable admin) plantait à chaque appel. | Colonnes qualifiées. |
| 6 | Modération : « Agir » sur un signalement ne retirait pas le contenu. | RPC `admin_resolve_report` qui retire vraiment la vidéo / le commentaire. |
| 7 | Aucun bucket Storage n'aurait existé en production (déclarés seulement dans `config.toml`, local). | Buckets + limites de taille/type créés par migration. |

## Failles de sécurité

| Gravité | Faille reproduite | Correctif |
|---|---|---|
| 🔴 Critique | **Ballons à l'infini** : `award_coins` acceptait n'importe quelle date « locale ». 10 dates inventées = +550 Ballons en une seconde, sans limite. | Date bornée à aujourd'hui ±1 jour (fuseaux réels), et toujours postérieure à la dernière réclamée. |
| 🔴 Critique | **Cagnotte gratuite** : `create_challenge(p_prize_pool => 1000000)` créait un défi doté d'1 million de Ballons sans rien payer ; le créateur pouvait le gagner seul. | Cagnotte toujours à 0 au départ, alimentée uniquement par les droits d'entrée. |
| 🔴 Critique | **Protection des mineurs contournée** : un recruteur lisait le jeton d'approbation du tuteur dans ses conversations et **s'auto-approuvait** le contact avec un mineur. | Colonne du jeton illisible via l'API ; seul le joueur l'obtient par la RPC dédiée. |
| 🟠 Élevée | **Date de naissance exacte de tous les joueurs (mineurs compris) lisible par n'importe qui**, même sans compte. | Colonne retirée de la lecture publique ; le joueur lit la sienne via `get_my_profile()`. |
| 🟠 Élevée | **Stars truquées** : 100 appels à `increment_video_views` depuis un même compte = 1 Star au créateur. | Une vue max par spectateur, par vidéo et par jour ; jamais sur sa propre vidéo. |
| 🟠 Élevée | Publier une vidéo avec `views_count`, `talent_score`, `is_boosted`… choisis par le client (fausse Pépite du jour, boost gratuit). | Droits d'insertion limités aux champs éditoriaux. |
| 🟠 Élevée | Vidéo pointant vers n'importe quel site externe (hameçonnage, contenu non modéré). | L'URL doit pointer vers le dossier Storage de l'auteur. |
| 🟡 Moyenne | Récompense « publicité regardée » réclamable sans aucune pub (150 Ballons/jour/compte). | Désactivée tant qu'aucune régie n'est branchée. |
| 🟡 Moyenne | Récompense « vidéo publiée » réclamable sans vidéo. | Doit désigner une vraie vidéo récente du joueur, une seule fois. |
| 🟡 Moyenne | Un ami pouvait publier 1 000 « reproductions » d'un Move pour créditer 1 000 Ballons à l'inventeur. | Une récompense par couple (joueur, Move), et seulement si l'original est un Move. |
| 🟡 Moyenne | Modification libre des notifications (texte), commentaires (likes, statut de modération), messages reçus (contenu), organisations (`is_verified`). | Droits colonne par colonne. |
| 🟡 Moyenne | `resolve_expired_challenges` exécutable par n'importe qui (droit par défaut de Postgres). | Droit retiré : réservé à `pg_cron` / admin. |
| 🟢 Faible | Aucune limite de longueur (bio, légendes, commentaires, messages). | Contraintes ajoutées. |
| 🟢 Faible | Netlify compilait avec la dernière version de Flutter (non testée) et sans en-têtes de sécurité. | Version figée (3.44.7) + en-têtes anti-clickjacking/HSTS. |

## Corrigé aussi (bugs visibles)

- Écran d'un défi : les pseudos des participants s'affichaient une lettre
  par ligne (bouton de vote trop large).
- Classements : recruteurs et marques apparaissaient parmi les joueurs.
- Compteurs de commentaires/vidéos qui ne baissaient jamais à la suppression.

## Ce qui reste à surveiller (non bloquant pour un lancement test)

- **Pas de limitation de débit** (rate limiting) sur likes/commentaires :
  Supabase n'en fournit pas par défaut pour l'API REST. À ajouter si du
  spam apparaît (Edge Function ou Cloudflare devant).
- **Votes multi-comptes** : un joueur peut créer plusieurs comptes pour
  voter pour lui. Le bonus de bienvenue exige déjà un e-mail confirmé ;
  pour aller plus loin, limiter le vote aux comptes de plus de N jours.
- **Défis King** : aucun code ne fixe le détenteur du record, donc ces
  défis se terminent toujours sans gagnant. Fonctionnalité à finir.
- Les buckets sont publics (toute vidéo est visible par URL directe) :
  normal pour un réseau social, mais une vidéo « retirée » par la
  modération reste accessible par son URL tant que le fichier n'est pas
  supprimé dans Storage.
- Activer la **protection contre les mots de passe divulgués** et le
  **CAPTCHA** à l'inscription dans le dashboard Supabase (Authentication →
  Settings) avant d'ouvrir au public.
