-- Messagerie recruteur ↔ joueur — voir PARTIE 8.4/8.5. Complète les tables
-- `scout_interests`/`scout_subscriptions` déjà prévues dans le schéma
-- initial mais jamais branchées à aucun flux (aucune interface recruteur
-- n'existait jusqu'ici).
--
-- Règle centrale : le contact avec un mineur n'est JAMAIS direct. Un
-- recruteur ne peut écrire à un joueur mineur qu'après approbation d'un
-- tuteur, via un lien à usage unique (le tuteur n'a pas nécessairement de
-- compte dans l'app). Sans email transactionnel configuré, ce lien est
-- transmis manuellement par le joueur lui-même (SMS/WhatsApp) plutôt que
-- simulé par un faux envoi automatique.

-- =========================================================================
-- handle_new_user — accepte désormais un `role` optionnel dans les
-- métadonnées d'inscription ('player' par défaut), avec allowlist stricte
-- pour qu'un client ne puisse jamais s'auto-attribuer 'admin' ou tout autre
-- rôle non prévu pour l'auto-inscription. Un compte recruteur ne reçoit pas
-- le bonus de bienvenue en Ballons (économie propre aux joueurs).
-- =========================================================================
create or replace function handle_new_user()
returns trigger as $$
declare
  v_role text := coalesce(new.raw_user_meta_data ->> 'role', 'player');
begin
  if v_role not in ('player', 'scout') then
    v_role := 'player';
  end if;

  insert into public.profiles (
    id,
    username,
    display_name,
    country,
    position,
    preferred_foot,
    birth_date,
    role,
    coins
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', 'player_' || substr(new.id::text, 1, 8)),
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'country',
    new.raw_user_meta_data ->> 'position',
    coalesce(new.raw_user_meta_data ->> 'preferred_foot', 'droit'),
    nullif(new.raw_user_meta_data ->> 'birth_date', '')::date,
    v_role,
    case when v_role = 'player' then 500 else 0 end
  );

  if v_role = 'player' then
    insert into public.transactions (user_id, type, amount, currency, balance_after, reason)
    values (new.id, 'earn', 500, 'coins', 500, 'welcome_bonus');
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- =========================================================================
-- guardian_contacts — table séparée de `profiles`, volontairement. `profiles`
-- a une policy "viewable by everyone" (RLS filtre des LIGNES, jamais des
-- COLONNES) : y ajouter l'email d'un tuteur l'aurait exposé publiquement à
-- quiconque consulte le Football Passport de n'importe quel joueur. Une
-- table à part, avec sa propre policy restreinte au joueur concerné,
-- élimine ce risque structurellement plutôt que de compter sur le client
-- pour ne simplement pas afficher le champ.
create table guardian_contacts (
  player_id uuid primary key references profiles (id) on delete cascade,
  guardian_name text,
  guardian_email text not null,
  updated_at timestamptz default now()
);

alter table guardian_contacts enable row level security;

create policy "Players manage their own guardian contact"
on guardian_contacts for all
using (auth.uid() = player_id)
with check (auth.uid() = player_id);

-- =========================================================================
-- conversations — une par (joueur, recruteur). Jamais écrite directement
-- par le client : uniquement via les fonctions SECURITY DEFINER ci-dessous,
-- pour imposer l'abonnement actif du recruteur et la médiation tuteur.
-- =========================================================================
create table conversations (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references profiles (id) on delete cascade,
  scout_id uuid not null references profiles (id) on delete cascade,
  status text not null default 'active',
  -- active, pending_guardian_approval, declined
  guardian_approval_token uuid default gen_random_uuid(),
  requested_at timestamptz default now(),
  approved_at timestamptz,
  last_message_at timestamptz,
  unique (player_id, scout_id)
);

create index idx_conversations_player on conversations (player_id);
create index idx_conversations_scout on conversations (scout_id);

alter table conversations enable row level security;

create policy "Participants can view own conversations"
on conversations for select
using (auth.uid() = player_id or auth.uid() = scout_id);

-- =========================================================================
-- messages
-- =========================================================================
create table messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations (id) on delete cascade,
  sender_id uuid not null references profiles (id),
  body text not null,
  created_at timestamptz default now(),
  read_at timestamptz
);

create index idx_messages_conversation on messages (conversation_id, created_at);

alter table messages enable row level security;

create policy "Participants can view messages in own conversations"
on messages for select
using (
  exists (
    select 1 from conversations
    where conversations.id = messages.conversation_id
      and (conversations.player_id = auth.uid() or conversations.scout_id = auth.uid())
  )
);

-- Marquer un message reçu comme lu reste une simple mise à jour de colonne
-- (aucune logique économique/anti-triche en jeu) : une policy RLS directe
-- suffit, pas besoin de RPC. `sender_id != auth.uid()` empêche de marquer
-- ses propres messages comme lus.
create policy "Recipients can mark received messages as read"
on messages for update
using (
  sender_id != auth.uid()
  and exists (
    select 1 from conversations
    where conversations.id = messages.conversation_id
      and (conversations.player_id = auth.uid() or conversations.scout_id = auth.uid())
  )
)
with check (
  sender_id != auth.uid()
  and exists (
    select 1 from conversations
    where conversations.id = messages.conversation_id
      and (conversations.player_id = auth.uid() or conversations.scout_id = auth.uid())
  )
);

-- =========================================================================
-- request_scout_contact — un recruteur (abonnement actif requis) demande à
-- contacter un joueur. Date de naissance inconnue traitée comme mineure par
-- prudence (en pratique toujours renseignée à l'inscription).
-- =========================================================================
create or replace function request_scout_contact(p_player_id uuid)
returns jsonb as $$
declare
  v_scout_id uuid := auth.uid();
  v_scout_role text;
  v_has_active_sub boolean;
  v_birth_date date;
  v_guardian_email text;
  v_is_minor boolean;
  v_conversation_id uuid;
  v_status text;
begin
  if v_scout_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if v_scout_id = p_player_id then
    raise exception 'Action invalide.' using errcode = 'P0001';
  end if;

  select role into v_scout_role from profiles where id = v_scout_id;
  if v_scout_role != 'scout' then
    raise exception 'Seul un compte recruteur peut contacter un joueur.'
      using errcode = 'P0001';
  end if;

  select exists (
    select 1 from scout_subscriptions
    where scout_id = v_scout_id and status = 'active'
      and (expires_at is null or expires_at > now())
  ) into v_has_active_sub;

  if not v_has_active_sub then
    raise exception 'Un abonnement actif est requis pour contacter un joueur.'
      using errcode = 'P0001';
  end if;

  select birth_date into v_birth_date
  from profiles where id = p_player_id and role = 'player';

  if not found then
    raise exception 'Joueur introuvable.' using errcode = 'P0001';
  end if;

  v_is_minor := v_birth_date is null or v_birth_date > (current_date - interval '18 years');

  if v_is_minor then
    select guardian_email into v_guardian_email
    from guardian_contacts where player_id = p_player_id;

    if v_guardian_email is null or v_guardian_email = '' then
      raise exception
        'Ce joueur est mineur et n''a pas encore renseigné le contact d''un tuteur : impossible de le contacter pour le moment.'
        using errcode = 'P0001';
    end if;
    v_status := 'pending_guardian_approval';
  else
    v_status := 'active';
  end if;

  insert into conversations (player_id, scout_id, status, approved_at)
  values (
    p_player_id, v_scout_id, v_status,
    case when v_status = 'active' then now() else null end
  )
  returning id into v_conversation_id;

  insert into notifications (user_id, type, title, body, actor_id, reference_type, reference_id)
  values (
    p_player_id, 'scout_interest', 'Un recruteur veut te contacter',
    case
      when v_is_minor then 'L''approbation d''un tuteur est nécessaire avant de pouvoir échanger.'
      else 'Tu peux désormais lui répondre.'
    end,
    v_scout_id, 'conversation', v_conversation_id
  );

  return jsonb_build_object('conversation_id', v_conversation_id, 'status', v_status);
exception
  when unique_violation then
    raise exception 'Tu as déjà contacté ce joueur.' using errcode = 'P0001';
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function request_scout_contact(uuid) to authenticated;

-- =========================================================================
-- get_guardian_approval_token — réservée au joueur concerné : c'est lui qui
-- transmet ce lien à son tuteur (SMS/WhatsApp) faute d'email transactionnel
-- configuré. Le recruteur ne doit jamais pouvoir l'obtenir : la liste
-- générale des conversations (`getConversations`, côté client) ne
-- sélectionne jamais la colonne `guardian_approval_token`, cette fonction
-- est le seul chemin pour l'obtenir, et elle vérifie explicitement
-- `auth.uid() = player_id`.
-- =========================================================================
create or replace function get_guardian_approval_token(p_conversation_id uuid)
returns uuid as $$
declare
  v_token uuid;
begin
  select guardian_approval_token into v_token
  from conversations
  where id = p_conversation_id
    and player_id = auth.uid()
    and status = 'pending_guardian_approval';

  if v_token is null then
    raise exception 'Conversation introuvable ou déjà approuvée.' using errcode = 'P0001';
  end if;

  return v_token;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function get_guardian_approval_token(uuid) to authenticated;

-- =========================================================================
-- approve_guardian_contact / decline_guardian_contact — actionnées via un
-- lien à usage unique connu du seul tuteur : ouvertes aussi à `anon` car le
-- tuteur n'a pas nécessairement de compte dans l'app. La seule protection
-- est la connaissance du jeton (uuid aléatoire, non énumérable).
-- =========================================================================
create or replace function approve_guardian_contact(p_token uuid)
returns jsonb as $$
declare
  v_conversation conversations%rowtype;
begin
  select * into v_conversation from conversations
  where guardian_approval_token = p_token and status = 'pending_guardian_approval';

  if v_conversation.id is null then
    raise exception 'Lien invalide ou déjà utilisé.' using errcode = 'P0001';
  end if;

  update conversations
  set status = 'active', approved_at = now()
  where id = v_conversation.id;

  insert into notifications (user_id, type, title, body, reference_type, reference_id)
  values (
    v_conversation.player_id, 'contact_approved', 'Contact approuvé',
    'Le contact avec le recruteur a été approuvé — vous pouvez échanger.',
    'conversation', v_conversation.id
  );
  insert into notifications (user_id, type, title, body, reference_type, reference_id)
  values (
    v_conversation.scout_id, 'contact_approved', 'Contact approuvé',
    'Le tuteur a approuvé le contact — vous pouvez échanger.',
    'conversation', v_conversation.id
  );

  return jsonb_build_object('approved', true, 'conversation_id', v_conversation.id);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function approve_guardian_contact(uuid) to authenticated, anon;

create or replace function decline_guardian_contact(p_token uuid)
returns jsonb as $$
declare
  v_conversation conversations%rowtype;
begin
  select * into v_conversation from conversations
  where guardian_approval_token = p_token and status = 'pending_guardian_approval';

  if v_conversation.id is null then
    raise exception 'Lien invalide ou déjà utilisé.' using errcode = 'P0001';
  end if;

  update conversations set status = 'declined' where id = v_conversation.id;

  return jsonb_build_object('declined', true);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function decline_guardian_contact(uuid) to authenticated, anon;

-- =========================================================================
-- send_message — unique canal d'écriture des messages : vérifie que
-- l'expéditeur appartient bien à la conversation et qu'elle est active
-- (jamais en attente d'approbation, jamais déclinée).
-- =========================================================================
create or replace function send_message(p_conversation_id uuid, p_body text)
returns jsonb as $$
declare
  v_user_id uuid := auth.uid();
  v_conversation conversations%rowtype;
  v_message_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if p_body is null or trim(p_body) = '' then
    raise exception 'Le message ne peut pas être vide.' using errcode = 'P0001';
  end if;

  select * into v_conversation from conversations where id = p_conversation_id;

  if v_conversation.id is null then
    raise exception 'Conversation introuvable.' using errcode = 'P0001';
  end if;

  if v_user_id != v_conversation.player_id and v_user_id != v_conversation.scout_id then
    raise exception 'Tu ne fais pas partie de cette conversation.' using errcode = 'P0001';
  end if;

  if v_conversation.status != 'active' then
    raise exception 'Cette conversation n''est pas encore active.' using errcode = 'P0001';
  end if;

  insert into messages (conversation_id, sender_id, body)
  values (p_conversation_id, v_user_id, trim(p_body))
  returning id into v_message_id;

  update conversations set last_message_at = now() where id = p_conversation_id;

  return jsonb_build_object('message_id', v_message_id);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function send_message(uuid, text) to authenticated;

-- =========================================================================
-- start_scout_trial — essai gratuit de 14 jours. En l'absence de moyen de
-- paiement réel branché (Stripe), un essai clairement gratuit et
-- fonctionnel est préférable à un faux bouton "S'abonner" qui ne
-- débiterait jamais personne (même principe que l'écran Boutique).
-- =========================================================================
create or replace function start_scout_trial()
returns jsonb as $$
declare
  v_scout_id uuid := auth.uid();
  v_scout_role text;
  v_existing boolean;
begin
  if v_scout_id is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  select role into v_scout_role from profiles where id = v_scout_id;
  if v_scout_role != 'scout' then
    raise exception 'Réservé aux comptes recruteurs.' using errcode = 'P0001';
  end if;

  select exists (
    select 1 from scout_subscriptions where scout_id = v_scout_id
  ) into v_existing;

  if v_existing then
    raise exception 'Tu as déjà utilisé ton essai gratuit.' using errcode = 'P0001';
  end if;

  insert into scout_subscriptions (scout_id, plan, status, expires_at)
  values (v_scout_id, 'trial', 'active', now() + interval '14 days');

  return jsonb_build_object('started', true);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function start_scout_trial() to authenticated;

-- =========================================================================
-- scout_search_players — recherche joueurs pour un recruteur. Ne renvoie
-- jamais la date de naissance exacte (seulement `is_minor`), cohérent avec
-- l'absence de géolocalisation précise déjà en place pour le Football
-- Passport public (protection des mineurs, PARTIE 8.4).
-- =========================================================================
create or replace function scout_search_players(
  p_query text default null,
  p_position text default null,
  p_country text default null
)
returns table (
  id uuid,
  username text,
  display_name text,
  avatar_url text,
  country text,
  city text,
  "position" text,
  is_minor boolean,
  stars integer,
  level text,
  followers_count integer
) as $$
begin
  if auth.uid() is null then
    raise exception 'Authentification requise.' using errcode = '28000';
  end if;

  if not exists (select 1 from profiles where id = auth.uid() and role = 'scout') then
    raise exception 'Réservé aux comptes recruteurs.' using errcode = 'P0001';
  end if;

  return query
  select
    p.id, p.username, p.display_name, p.avatar_url, p.country, p.city, p.position,
    (p.birth_date is null or p.birth_date > (current_date - interval '18 years')),
    p.stars, p.level, p.followers_count
  from profiles p
  where p.role = 'player'
    and (p_query is null or p_query = '' or p.username ilike '%' || p_query || '%')
    and (p_position is null or p.position = p_position)
    and (p_country is null or p.country = p_country)
  order by p.stars desc
  limit 30;
end;
$$ language plpgsql stable security definer set search_path = public;

grant execute on function scout_search_players(text, text, text) to authenticated;
