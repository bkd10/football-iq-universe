-- Correctif de sécurité : la policy RLS "Users can update own profile"
-- (USING auth.uid() = id) autorise un UPDATE sur N'IMPORTE QUELLE colonne
-- de la ligne — y compris coins/stars/iq_*/level, que tout ce projet est
-- censé ne modifier que via les fonctions SECURITY DEFINER (award_coins,
-- spend_coins, join_challenge, resolve_expired_challenges, triggers de
-- compteurs...). RLS ne fait que filtrer les LIGNES, pas les colonnes : il
-- faut un privilège Postgres au niveau colonne pour fermer ce trou.
--
-- Les fonctions SECURITY DEFINER restent non affectées : elles s'exécutent
-- avec les privilèges du propriétaire de la fonction, pas ceux du rôle
-- `authenticated` de l'appelant.

revoke update on profiles from authenticated;

grant update (
  username, display_name, avatar_url, bio, country, city, birth_date,
  position, preferred_foot, height_cm, weight_kg
) on profiles to authenticated;

-- Même trou sur `videos` : "Users can update own videos" (auth.uid() =
-- user_id) autoriserait sinon un client à s'auto-attribuer des vues, des
-- likes, un talent_score, ou à se retirer lui-même de modération
-- (status/is_boosted). Seuls caption/category/is_move/move_name restent
-- éditables par le créateur ; le reste est écrit uniquement par les
-- triggers/RPC SECURITY DEFINER.
revoke update on videos from authenticated;

grant update (caption, category, is_move, move_name) on videos to authenticated;
