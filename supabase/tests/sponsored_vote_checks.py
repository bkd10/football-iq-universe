"""Tests du défi sponsorisé dans le fil et des règles de vote, sur une base de
TEST locale (jamais la production).

    sudo bash supabase/tests/local_db/build_test_db.sh   # base de test neuve
    python3 supabase/tests/sponsored_vote_checks.py

Réutilise les outils de minor_safety_checks.py (mêmes appels « en tant que
joueur », RLS et droits appliqués).
"""

import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from minor_safety_checks import (  # noqa: E402
    RESULTS, accepted, check, new_user, refused, run, val, video_of, years_ago,
)


def admin():
    uid = new_user("admin", years_ago(30))
    val("update profiles set role = 'admin' where id = '%s'" % uid)
    return uid


def challenge(creator, start="now() - interval '1 day'", end="now() + interval '3 days'", ctype="sponsored"):
    return val(
        "insert into challenges (creator_id, title, type, start_date, end_date, status, show_in_feed, "
        "sponsor_name, prize_currency) values ('%s', 'Test %s', '%s', %s, %s, 'active', true, 'Passe D', 'coins') "
        "returning id" % (creator, uuid.uuid4().hex[:4], ctype, start, end)
    ).splitlines()[0]


def raw_video(user):
    """Vidéo de test insérée sans passer par la limite de publication."""
    url = "https://abc.supabase.co/storage/v1/object/public/videos/%s/%s.mp4" % (user, uuid.uuid4().hex)
    return val("insert into videos (user_id, video_url, caption, category, rights_confirmed_at) "
               "values ('%s', '%s', 'test', 'dribble', now()) returning id" % (user, url)).splitlines()[0]


def join(cid, user):
    vid = raw_video(user)
    val("insert into challenge_participations (challenge_id, user_id, video_id) values ('%s', '%s', '%s')"
        % (cid, user, vid))
    val("update challenges set participants_count = participants_count + 1 where id = '%s'" % cid)
    return vid


def vote_sql(cid, target, device=None):
    dev = "null" if device is None else "'%s'" % device
    return "select vote_for_participant('%s', '%s', %s)" % (cid, target, dev)


def old_account(uid):
    val("update profiles set created_at = now() - interval '10 days' where id = '%s'" % uid)


def main():
    ok, _, err = run("select 1")
    if not ok:
        sys.exit("Base de test injoignable : %s" % err)

    boss = admin()
    a = new_user("alice", years_ago(25))
    b = new_user("bruno", years_ago(25))
    v1 = new_user("voter1", years_ago(25))
    v2 = new_user("voter2", years_ago(25))
    minor = new_user("mineur", years_ago(16), minor=True)
    for u in (a, b, v1, v2, minor):
        old_account(u)

    cid = challenge(boss)
    va = join(cid, a)
    join(cid, b)

    # --- Votes : règles côté serveur
    accepted("vote accepté pendant le défi", vote_sql(cid, a, "device-aaaa-1111"), v1)
    refused("un seul vote par joueur et par défi", vote_sql(cid, b), v1, "déjà voté")
    refused("pas de vote pour sa propre vidéo", vote_sql(cid, a), a, "toi-même")
    n = val("select votes_count from challenge_participations where challenge_id = '%s' and user_id = '%s'" % (cid, a))
    check("le compteur ne compte qu'un vote", n == "1", n)

    future = challenge(boss, start="now() + interval '2 days'", end="now() + interval '9 days'")
    join(future, a)
    refused("vote refusé avant la date de début (message avec la date)", vote_sql(future, a), v1, "Les votes ouvrent le")

    ended = challenge(boss, start="now() - interval '5 days'", end="now() - interval '1 hour'")
    join(ended, a)
    refused("vote refusé après la fin", vote_sql(ended, a), v1, "terminés")

    refused("non connecté refusé", vote_sql(cid, a), anon=True)
    banned = new_user("banni", years_ago(25))
    old_account(banned)
    val("update profiles set is_banned = true where id = '%s'" % banned)
    refused("compte banni refusé", vote_sql(cid, a), banned, "suspendu")

    # Participant sans vidéo active (vidéo retirée par la modération).
    val("update videos set status = 'removed' where id = '%s'" % va)
    refused("vidéo retirée : plus de vote", vote_sql(cid, a), v2, "ne peut pas recevoir")
    val("update videos set status = 'active' where id = '%s'" % va)

    ok_direct, _, _ = run("insert into challenge_votes (challenge_id, voter_id, participant_id) "
                          "values ('%s', '%s', '%s')" % (cid, v2, a), v2)
    check("impossible d'insérer un vote sans passer par les règles", not ok_direct)

    # --- Limite de débit
    val("update app_config set value = value || '{\"per_minute\": 2}'::jsonb where key = 'vote_rules'")
    spam = new_user("spam", years_ago(25))
    old_account(spam)
    refs = []
    for _ in range(3):
        c = challenge(boss)
        join(c, a)
        refs.append(c)
    accepted("limite de débit : 1er vote", vote_sql(refs[0], a), spam)
    accepted("limite de débit : 2e vote", vote_sql(refs[1], a), spam)
    refused("limite de débit : 3e vote dans la minute refusé", vote_sql(refs[2], a), spam, "Trop de votes")
    val("update app_config set value = value || '{\"per_minute\": 10}'::jsonb where key = 'vote_rules'")

    # --- Détection d'abus
    dev = "device-shared-" + uuid.uuid4().hex[:8]
    c2 = challenge(boss)
    join(c2, a)
    for i in range(3):
        u = new_user("multi%d" % i, years_ago(25))
        old_account(u)
        accepted("vote %d depuis le même appareil" % (i + 1), vote_sql(c2, a, dev), u)
    flags = val("select count(*) from vote_abuse_flags where challenge_id = '%s' and reason = 'same_device'" % c2)
    check("même appareil, 3 comptes : alerte dans le panneau admin", flags == "1", flags)

    fresh = new_user("fresh", years_ago(25))
    video_of(fresh)  # a publié une vidéo : a le droit de voter tout de suite
    accepted("compte de quelques minutes avec vidéo : vote accepté", vote_sql(c2, a), fresh)
    flags = val("select count(*) from vote_abuse_flags where voter_id = '%s' and reason = 'new_account'" % fresh)
    check("compte créé il y a quelques minutes : alerte", flags == "1", flags)

    fp = val("select count(*) from private.vote_fingerprints where device_hash is not null and device_hash <> '%s'"
             " and challenge_id = '%s'" % (dev, c2))
    check("l'identifiant d'appareil est stocké haché, jamais en clair", fp == "3", fp)
    ok_read, _, _ = run("select * from private.vote_fingerprints limit 1", v1)
    check("un joueur ne lit pas les empreintes de vote", not ok_read)
    ok_read, out, _ = run("select count(*) from vote_abuse_flags", v1)
    check("un joueur ne lit pas les alertes", not ok_read or out == "0", out)

    lst = accepted("l'admin voit les alertes", "select admin_list_vote_flags('pending', 50)", boss)
    check("alerte avec statut, date et défi", '"status": "pending"' in lst and "created_at" in lst, lst[:200])
    refused("un joueur ne voit pas les alertes admin", "select admin_list_vote_flags()", v1, "administrateurs")

    flag_id = val("select id from vote_abuse_flags where challenge_id = '%s' and reason = 'same_device'" % c2)
    before = int(val("select votes_count from challenge_participations where challenge_id = '%s' and user_id = '%s'" % (c2, a)))
    accepted("l'admin annule un vote suspect", "select admin_resolve_vote_flag('%s', 'remove_vote')" % flag_id, boss)
    after = int(val("select votes_count from challenge_participations where challenge_id = '%s' and user_id = '%s'" % (c2, a)))
    check("vote annulé : compteur corrigé", after == before - 1, (before, after))
    st = val("select status from vote_abuse_flags where id = '%s'" % flag_id)
    check("alerte marquée « vote annulé »", st == "vote_removed", st)

    # --- Infos pour le bouton Voter
    other = raw_video(b)
    rows = val("select count(*) from get_video_challenge_entries(array['%s','%s']::uuid[])" % (va, other), v1)
    check("vidéo de défi : infos de vote ; vidéo hors défi : rien", rows != "0", rows)
    mine = val("select my_vote_participant_id from get_video_challenge_entries(array['%s']::uuid[]) "
               "where challenge_id = '%s'" % (va, cid), v1)
    check("le joueur voit qu'il a déjà voté", mine == a, mine)
    none = val("select count(*) from get_video_challenge_entries(array['%s']::uuid[])" % other, v1)
    check("vidéo hors défi : pas de bouton", none == "0", none)

    # --- Défis dans le fil : pas de ciblage, rien de personnel
    feed_adult = val("select string_agg(id::text, ',' order by id) from get_feed_sponsored_challenges()", v1)
    feed_minor = val("select string_agg(id::text, ',' order by id) from get_feed_sponsored_challenges()", minor)
    check("même liste de défis sponsorisés pour un mineur et un adulte (pas de ciblage)", feed_adult == feed_minor)
    check("le défi sponsorisé actif apparaît dans le fil", cid in (feed_adult or ""))
    check("un défi qui n'a pas commencé apparaît aussi (inscription ouverte)", future in (feed_adult or ""))
    cols = val("select string_agg(column_name, ',') from information_schema.columns "
               "where table_name = 'get_feed_sponsored_challenges'")
    fn = val("select pg_get_function_result('get_feed_sponsored_challenges'::regproc)")
    check("la carte ne contient aucune donnée de joueur", all(k not in fn for k in ("birth", "city", "email", "username")), fn)
    del cols

    # --- Brouillon Passe D : préparé, jamais activé sans tout + sponsor confirmé
    drafts = accepted("l'admin voit le brouillon Passe D", "select admin_list_sponsored_drafts()", boss)
    check("Passe D présent, sponsor non confirmé", '"sponsor_name": "Passe D"' in drafts
          and '"sponsor_confirmed": false' in drafts, drafts[:300])
    did = val("select id from sponsored_challenge_drafts where sponsor_name = 'Passe D' order by created_at limit 1")
    refused("activation refusée tant que tout manque", "select admin_activate_sponsored_draft('%s')" % did, boss,
            "il manque")
    ok_read, out, _ = run("select count(*) from sponsored_challenge_drafts", v1)
    check("un joueur ne voit pas les brouillons", not ok_read or out == "0", out)
    refused("un joueur ne peut pas activer", "select admin_activate_sponsored_draft('%s')" % did, v1, "administrateurs")
    accepted("l'admin remplit le brouillon (sans confirmer le sponsor)",
             "select admin_save_sponsored_draft('%s', jsonb_build_object('title','Défi Passe D test',"
             "'description','Ta plus belle passe décisive','sponsor_logo_url','https://example.com/l.png',"
             "'start_date', (now() + interval '1 day')::text, 'end_date', (now() + interval '8 days')::text,"
             "'entry_cost', 0, 'reward_stars', 300))" % did, boss)
    refused("activation refusée : sponsor non confirmé", "select admin_activate_sponsored_draft('%s')" % did, boss,
            "sponsor confirmé")
    n_feed = val("select count(*) from challenges where title = 'Défi Passe D test'")
    check("Passe D n'est pas dans les défis (pas activé)", n_feed == "0", n_feed)

    # Brouillon de test séparé, activé de bout en bout (pas celui de Passe D).
    t = val("select admin_save_sponsored_draft(null, jsonb_build_object('title','Défi test activé',"
            "'description','Description du défi test','sponsor_name','Marque Test','sponsor_logo_url','https://example.com/t.png',"
            "'sponsor_confirmed', true, 'start_date', (now() + interval '1 hour')::text,"
            "'end_date', (now() + interval '2 days')::text, 'entry_cost', 0, 'reward_stars', 250)) ->> 'id'", boss)
    new_cid = accepted("brouillon complet et sponsor confirmé : activation",
                       "select admin_activate_sponsored_draft('%s') ->> 'challenge_id'" % t, boss)
    kind = val("select type || ',' || show_in_feed || ',' || reward_stars from challenges where id = '%s'" % new_cid)
    check("défi activé : sponsorisé, dans le fil, récompense en Stars", kind == "sponsored,true,250", kind)
    notif = val("select count(*) from notifications where reference_id = '%s' and type = 'challenge_launched'" % new_cid)
    check("activation : notification « Nouveau challenge » envoyée", int(notif) > 0, notif)

    # Récompense en Stars au-delà des 100 habituelles.
    val("update challenges set start_date = now() - interval '3 days', end_date = now() - interval '1 minute' where id = '%s'" % new_cid)
    join(new_cid, a)
    val("insert into challenge_votes (challenge_id, voter_id, participant_id) values ('%s', '%s', '%s')" % (new_cid, v1, a))
    val("update challenge_participations set votes_count = 1 where challenge_id = '%s'" % new_cid)
    s0 = int(val("select stars from profiles where id = '%s'" % a))
    val("select resolve_expired_challenges()")
    s1 = int(val("select stars from profiles where id = '%s'" % a))
    check("le gagnant reçoit la récompense en Stars du défi (250)", s1 - s0 == 250, s1 - s0)

    # --- Fréquence réglable
    accepted("l'admin règle la fréquence (toutes les 4 vidéos)", "select admin_set_sponsored_feed(4, true)", boss)
    nv = val("select value ->> 'every_n' from app_config where key = 'sponsored_feed'")
    check("fréquence enregistrée", nv == "4", nv)
    refused("fréquence hors limites refusée", "select admin_set_sponsored_feed(1, true)", boss, "entre 2 et 50")
    refused("un joueur ne règle pas la fréquence", "select admin_set_sponsored_feed(3, true)", v1, "administrateurs")
    pub = val("select value ->> 'every_n' from app_config where key = 'sponsored_feed'", v1)
    check("le réglage est lisible par l'appli", pub == "4", pub)

    # --- Sponsor et mineurs (mode protégé de la 0037)
    brand = new_user("marque", years_ago(30), role="brand")
    reason = val("select private.can_private_message('%s', '%s')" % (brand, minor))
    check("une marque ne peut pas écrire à un mineur", reason != "", reason)

    print()
    print("%d/%d vérifications OK" % (sum(RESULTS), len(RESULTS)))
    sys.exit(0 if all(RESULTS) else 1)


if __name__ == "__main__":
    main()
