-- =========================================================================
-- Grand livre : corriger une source de dérive réelle, et ajouter une
-- requête de contrôle pour en détecter d'autres proactivement.
--
-- "Elle insère dans transactions et met à jour le solde, dans la même
-- transaction. Aucun autre chemin n'a le droit de toucher coins ou stars."
-- — vrai pour award_coins/spend_coins/join_challenge/create_challenge,
-- vérifié. FAUX pour un cas trouvé en auditant resolve_expired_challenges :
-- le bonus de 100 Stars versé au vainqueur d'un défi
-- (`set stars = stars + 100 ...`) ne générait AUCUNE ligne dans
-- `transactions`, contrairement au prize_pool en Ballons juste au-dessus
-- dans la même fonction, qui lui insère bien sa transaction. Résultat :
-- `profiles.stars` divergeait silencieusement et définitivement de la
-- somme du grand livre à chaque défi résolu, sans qu'aucun bug applicatif
-- ne le déclenche jamais — c'est une omission structurelle, pas une race
-- condition. On la corrige ici, et le Wallet peut désormais aussi
-- afficher "+100 ⭐ Défi remporté" dans l'historique, ce qu'il ne pouvait
-- pas faire avant faute de transaction.
-- =========================================================================

create or replace function resolve_expired_challenges()
returns integer as $$
declare
  v_challenge record;
  v_winner_user_id uuid;
  v_new_balance integer;
  v_new_stars integer;
  v_resolved_count integer := 0;
  v_rank integer;
  v_participation record;
begin
  for v_challenge in
    select * from challenges
    where status = 'active' and end_date < now()
  loop
    v_winner_user_id := null;

    if v_challenge.type = 'king' then
      v_winner_user_id := v_challenge.record_holder_id;
    else
      select user_id into v_winner_user_id
      from challenge_participations
      where challenge_id = v_challenge.id
      order by votes_count desc, created_at asc
      limit 1;

      v_rank := 1;
      for v_participation in
        select id from challenge_participations
        where challenge_id = v_challenge.id
        order by votes_count desc, created_at asc
      loop
        update challenge_participations set rank = v_rank where id = v_participation.id;
        v_rank := v_rank + 1;
      end loop;
    end if;

    if v_winner_user_id is not null then
      if v_challenge.prize_pool > 0 and v_challenge.prize_currency = 'coins' then
        update profiles set coins = coins + v_challenge.prize_pool
        where id = v_winner_user_id
        returning coins into v_new_balance;

        insert into transactions (
          user_id, type, amount, currency, balance_after, reason,
          reference_type, reference_id
        ) values (
          v_winner_user_id, 'earn', v_challenge.prize_pool, 'coins', v_new_balance,
          'win_challenge', 'challenge', v_challenge.id
        );
      end if;

      update profiles
      set stars = stars + 100, challenges_won_count = challenges_won_count + 1
      where id = v_winner_user_id
      returning stars into v_new_stars;

      insert into transactions (
        user_id, type, amount, currency, balance_after, reason,
        reference_type, reference_id
      ) values (
        v_winner_user_id, 'earn', 100, 'stars', v_new_stars,
        'win_challenge', 'challenge', v_challenge.id
      );

      insert into notifications (user_id, type, title, body, reference_type, reference_id)
      values (
        v_winner_user_id, 'challenge_won', 'Défi remporté !',
        'Tu as remporté "' || v_challenge.title || '" 🏆',
        'challenge', v_challenge.id
      );
    end if;

    update challenges
    set status = 'completed', winner_id = v_winner_user_id
    where id = v_challenge.id;

    v_resolved_count := v_resolved_count + 1;
  end loop;

  return v_resolved_count;
end;
$$ language plpgsql security definer set search_path = public;

-- =========================================================================
-- find_ledger_drift — compare le solde stocké (profiles.coins/stars) à la
-- somme du grand livre (transactions) pour chaque utilisateur et chaque
-- devise, et ne retourne QUE les lignes qui divergent. Réservée aux
-- administrateurs (expose le solde de tout le monde) : à exécuter
-- périodiquement (cron externe, ou manuellement dans le SQL Editor) pour
-- détecter au plus tôt tout futur chemin qui modifierait coins/stars sans
-- passer par une transaction.
--
-- `user_id is not null` exclut volontairement les transactions dont
-- l'auteur a supprimé son compte (transactions.user_id passe à null via
-- ON DELETE SET NULL, voir 20260101000015_hardening.sql) : ces lignes ne
-- peuvent plus être rapprochées d'un profil, ce n'est pas une dérive.
-- =========================================================================
create or replace function find_ledger_drift()
returns table (
  user_id uuid,
  currency text,
  stored_balance integer,
  ledger_sum bigint,
  drift bigint
) as $$
begin
  if not exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Réservé aux administrateurs.' using errcode = '42501';
  end if;

  return query
  select p.id, 'coins'::text, p.coins, coalesce(t.ledger_sum, 0::bigint),
         p.coins::bigint - coalesce(t.ledger_sum, 0::bigint)
  from profiles p
  left join (
    select transactions.user_id, sum(amount) as ledger_sum
    from transactions
    where currency = 'coins' and user_id is not null
    group by transactions.user_id
  ) t on t.user_id = p.id
  where p.coins != coalesce(t.ledger_sum, 0)

  union all

  select p.id, 'stars'::text, p.stars, coalesce(t.ledger_sum, 0::bigint),
         p.stars::bigint - coalesce(t.ledger_sum, 0::bigint)
  from profiles p
  left join (
    select transactions.user_id, sum(amount) as ledger_sum
    from transactions
    where currency = 'stars' and user_id is not null
    group by transactions.user_id
  ) t on t.user_id = p.id
  where p.stars != coalesce(t.ledger_sum, 0);
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function find_ledger_drift() to authenticated;
