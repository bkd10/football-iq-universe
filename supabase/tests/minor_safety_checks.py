"""Tests de la protection des mineurs, sur une base de TEST locale.

Jamais la production : le script crée des comptes, des vidéos et des
signalements de test, et change des réglages. Il refuse toute adresse qui
n'est pas locale.

    sudo bash supabase/tests/local_db/build_test_db.sh   # base de test neuve
    python3 supabase/tests/minor_safety_checks.py

Chaque vérification affiche OK ou ÉCHEC ; le code de sortie est 1 au moindre
échec. Les appels « en tant que joueur » passent par le rôle `authenticated`
avec son identifiant dans `request.jwt.claims`, exactement comme l'API
Supabase : les règles RLS et les droits s'appliquent.
"""

import datetime
import json
import os
import subprocess
import sys
import uuid

DB_URL = os.environ.get("MINOR_TEST_DB_URL", "postgresql://postgres:postgres@127.0.0.1:5432/fiq_test")
if "127.0.0.1" not in DB_URL and "localhost" not in DB_URL:
    sys.exit("Refusé : ce script ne vise qu'une base locale de test.")

RESULTS = []


def run(sql, user=None, anon=False):
    """Exécute du SQL ; renvoie (ok, sortie, erreur)."""
    head = ""
    if user or anon:
        claims = {"role": "anon"} if anon else {"sub": user, "role": "authenticated"}
        head = (
            "do $$ begin perform set_config('request.jwt.claims', '%s', true); end $$;\n"
            "set local role %s;\n" % (json.dumps(claims), "anon" if anon else "authenticated")
        )
    script = "begin;\n" + head + sql.rstrip().rstrip(";") + ";\ncommit;\n"
    p = subprocess.run(
        ["psql", DB_URL, "-X", "-q", "-A", "-t", "-v", "ON_ERROR_STOP=1"],
        input=script, capture_output=True, text=True,
    )
    return p.returncode == 0, p.stdout.strip(), p.stderr.strip()


def val(sql, user=None, anon=False):
    ok, out, err = run(sql, user, anon)
    if not ok:
        raise RuntimeError(err)
    return out


def check(name, cond, detail=""):
    RESULTS.append(bool(cond))
    print(("OK     " if cond else "ÉCHEC  ") + name + ("" if cond else "  → " + str(detail)[:300]))


def refused(name, sql, user=None, contains=None, anon=False):
    ok, out, err = run(sql, user, anon)
    cond = (not ok) and (contains is None or contains in err)
    check(name, cond, err or out)


def accepted(name, sql, user=None, anon=False):
    ok, out, err = run(sql, user, anon)
    check(name, ok, err)
    return out


def years_ago(n, days=0):
    d = datetime.date.today()
    try:
        d = d.replace(year=d.year - n)
    except ValueError:
        d = d.replace(year=d.year - n, day=28)
    return (d - datetime.timedelta(days=days)).isoformat()


def meta(name, birth, role=None, guardian=None, country=None, terms=True):
    m = {"username": name}
    if birth:
        m["birth_date"] = birth
    if role:
        m["role"] = role
    if guardian:
        m["guardian_email"] = guardian
        m["parental_attestation"] = True
    if country:
        m["country"] = country
    if terms:
        m["terms_accepted"] = True
    return m


def signup_sql(m, email):
    return (
        "insert into auth.users (email, raw_user_meta_data, email_confirmed_at) values "
        "('%s', '%s'::jsonb, now()) returning id" % (email, json.dumps(m).replace("'", "''"))
    )


def new_user(prefix, birth, role=None, minor=False, country=None):
    name = (prefix + "_" + uuid.uuid4().hex[:6])[:20]
    m = meta(name, birth, role, guardian=("parent_" + name + "@test.dev") if minor else None, country=country)
    return val(signup_sql(m, name + "@test.dev")).splitlines()[0]


def set_legal(patch):
    val("update app_config set value = value || '%s'::jsonb where key = 'legal'" % json.dumps(patch))


def follow(a, b):
    val("insert into follows (follower_id, following_id) values ('%s', '%s') on conflict do nothing" % (a, b))


def video_of(user):
    url = "https://abc.supabase.co/storage/v1/object/public/videos/%s/%s.mp4" % (user, uuid.uuid4().hex)
    return val(
        "insert into videos (user_id, video_url, caption, category, rights_confirmed_at) "
        "values ('%s', '%s', 'test', 'dribble', now()) returning id" % (user, url),
        user,
    ).splitlines()[0]


def main():
    ok, _, err = run("select 1")
    if not ok:
        sys.exit("Base de test injoignable : %s" % err)
    original = val("select value from app_config where key = 'legal'")
    try:
        tests()
    finally:
        val("update app_config set value = '%s'::jsonb where key = 'legal'" % original.replace("'", "''"))
    failed = RESULTS.count(False)
    print("\n%d/%d vérifications OK" % (len(RESULTS) - failed, len(RESULTS)))
    sys.exit(1 if failed else 0)


def tests():
    set_legal({"strict_mode": True, "min_age": 13, "country_rules": {}, "minor_purchases": "disabled"})

    print("— 1. Âge à l'inscription")
    n = "kid_" + uuid.uuid4().hex[:6]
    refused("inscription refusée sous l'âge minimum (12 ans)",
            signup_sql(meta(n, years_ago(12), guardian="p_" + n + "@x.dev"), n + "@test.dev"),
            contains="au moins 13 ans")
    n = "nob_" + uuid.uuid4().hex[:6]
    refused("inscription refusée sans date de naissance", signup_sql(meta(n, None), n + "@test.dev"),
            contains="Date de naissance requise")
    n = "par_" + uuid.uuid4().hex[:6]
    refused("mineur sans accord parental refusé", signup_sql(meta(n, years_ago(16)), n + "@test.dev"),
            contains="Accord parental requis")
    set_legal({"min_age": 15})
    n = "k14_" + uuid.uuid4().hex[:6]
    refused("âge minimum configurable (15 ans) : 14 ans refusé",
            signup_sql(meta(n, years_ago(14), guardian="p_" + n + "@x.dev"), n + "@test.dev"),
            contains="au moins 15 ans")
    set_legal({"min_age": 13, "country_rules": {"france": {"min_age": 16}}})
    n = "fr_" + uuid.uuid4().hex[:6]
    refused("règle par pays (France 16 ans) : 15 ans refusé",
            signup_sql(meta(n, years_ago(15), guardian="p_" + n + "@x.dev", country="France"), n + "@test.dev"),
            contains="au moins 16 ans")
    uk15 = new_user("uk15", years_ago(15), minor=True, country="United Kingdom")
    check("même âge accepté dans un autre pays", bool(uk15))
    set_legal({"country_rules": {}})
    rules = json.loads(val("select get_age_rules(null)", anon=True))
    check("règles d'âge lisibles par l'appli (sans compte)", rules.get("min_age") == 13, rules)

    minor = new_user("minor", years_ago(16), minor=True)
    adult = new_user("adult", years_ago(30))
    check("compte de moins de 18 ans signalé dans la base (account_consents.is_minor)",
          val("select is_minor from account_consents where user_id = '%s'" % minor) == "t")
    check("compte majeur non signalé", val("select is_minor from account_consents where user_id = '%s'" % adult) == "f")
    birthday = new_user("bday", years_ago(18, days=-1), minor=True)  # 18 ans demain
    check("17 ans et 364 jours : encore mineur", val("select private.is_minor('%s')" % birthday) == "t")

    set_legal({"strict_mode": False})
    n = "old_" + uuid.uuid4().hex[:6]
    ok, _, err = run(signup_sql({"username": n}, n + "@test.dev"))
    check("mode compatible (ancienne appli en ligne) : inscription sans CGU acceptée", ok, err)
    old_user = val("select id from profiles where username = '%s'" % n)
    check("… et ce compte sans date de naissance est traité comme mineur",
          val("select private.is_minor('%s')" % old_user) == "t")
    set_legal({"strict_mode": True})
    n = "old2_" + uuid.uuid4().hex[:6]
    refused("mode strict (nouvelle appli publiée) : inscription sans CGU refusée",
            signup_sql({"username": n}, n + "@test.dev"), contains="conditions d'utilisation")

    print("— 2. Réglages par défaut des moins de 18 ans")
    s = json.loads(val("select get_my_safety()", minor))
    check("mineur : profil limité", s["profile_visibility"] == "limited", s)
    check("mineur : messages privés entre abonnés mutuels seulement", s["dm_from"] == "mutual", s)
    check("mineur : pas de Battle aléatoire sans accord", s["allow_random_battles"] is False, s)
    check("mineur : localisation (ville) masquée", s["show_location"] is False, s)
    a = json.loads(val("select get_my_safety()", adult))
    check("majeur : profil public par défaut", a["profile_visibility"] == "public", a)
    refused("un mineur ne peut pas ouvrir ses messages privés à tout le monde",
            "select update_my_safety_settings('{\"dm_from\": \"everyone\"}')", minor, contains="abonnés mutuels")
    accepted("un mineur peut fermer ses messages privés", "select update_my_safety_settings('{\"dm_from\": \"nobody\"}')", minor)
    val("select update_my_safety_settings('{\"dm_from\": \"mutual\"}')", minor)

    stranger = new_user("strgr", years_ago(25))
    p = json.loads(val("select get_public_profile('%s')" % minor, stranger))
    check("profil limité vu par un inconnu : pas de bio ni de compteurs d'abonnés",
          p["limited"] is True and p["followers_count"] == 0 and p["bio"] == "", p)
    val("update profiles set city = 'Lyon' where id = '%s'" % minor)
    check("ville d'un mineur jamais montrée à un inconnu", p.get("city") is None and
          json.loads(val("select get_public_profile('%s')" % minor, stranger)).get("city") is None)
    follow(stranger, adult)
    follow(minor, adult)
    cnt = val("select count(*) from follows where follower_id = '%s'" % minor, stranger)
    check("abonnements d'un profil limité invisibles pour un inconnu", cnt == "0", cnt)
    rk = val("select count(*) from get_rankings('stars', null, 'Lyon', 50) where id = '%s'" % minor, stranger)
    check("classement par ville : le mineur qui masque sa ville n'y apparaît pas", rk == "0", rk)

    print("— 3. Messages privés")
    scout = new_user("scout", years_ago(35), role="scout")
    val("select start_scout_trial()", scout)
    refused("un adulte ne peut pas écrire à un mineur qu'il ne suit pas mutuellement",
            "select request_scout_contact('%s')" % minor, scout, contains="abonnés mutuels")
    follow(scout, minor)
    refused("… même s'il le suit (sans retour)", "select request_scout_contact('%s')" % minor, scout,
            contains="abonnés mutuels")
    follow(minor, scout)
    out = accepted("abonnés mutuels : demande possible, en attente de l'accord du parent",
                   "select request_scout_contact('%s')" % minor, scout)
    conv = json.loads(out)["conversation_id"] if out else None
    if conv:
        tok = val("select guardian_approval_token from conversations where id = '%s'" % conv)
        val("select approve_guardian_contact('%s')" % tok, anon=True)
        accepted("après l'accord du parent : message envoyé", "select send_message('%s', 'Bonjour')" % conv, scout)
        val("delete from follows where follower_id = '%s' and following_id = '%s'" % (minor, scout))
        refused("le mineur ne suit plus le recruteur : message bloqué",
                "select send_message('%s', 'Re-bonjour')" % conv, scout, contains="abonnés mutuels")
        follow(minor, scout)
    r = val("select coalesce(json_agg(json_build_object('id', id, 'city', city, 'm', is_minor)), '[]') "
            "from scout_search_players(null, null, null)", scout)
    row = next((x for x in json.loads(r) if x["id"] == minor), None)
    check("recherche recruteur : mineur signalé, ville cachée", row is not None and row["m"] is True
          and row["city"] is None, r[:200])
    brand = new_user("brand", years_ago(40), role="brand")
    follow(brand, minor)
    follow(minor, brand)
    r = val("select private.can_private_message('%s', '%s')" % (brand, minor))
    check("une marque ne peut jamais écrire en privé à un mineur (même abonnés mutuels)", "marque" in r, r)
    adult2 = new_user("adlt2", years_ago(28))
    val("select update_my_safety_settings('{\"dm_from\": \"everyone\"}')", adult2)
    r = val("select coalesce(private.can_private_message('%s', '%s'), 'permis')" % (scout, adult2))
    check("entre majeurs (messages ouverts) : permis", r == "permis", r)

    print("— 4. Bloquer")
    va = video_of(adult)
    blocked = new_user("blkd", years_ago(22))
    follow(blocked, adult)
    accepted("bloquer un joueur", "select block_user('%s')" % blocked, adult)
    check("le blocage retire l'abonnement",
          val("select count(*) from follows where follower_id = '%s' and following_id = '%s'" % (blocked, adult)) == "0")
    check("le joueur bloqué ne voit plus les vidéos",
          val("select count(*) from videos where id = '%s'" % va, blocked) == "0")
    check("… un autre joueur les voit toujours", val("select count(*) from videos where id = '%s'" % va, stranger) == "1")
    refused("le joueur bloqué ne peut plus commenter",
            "insert into comments (user_id, video_id, content) values ('%s', '%s', 'hey')" % (blocked, va),
            blocked, contains="bloqué")
    refused("le joueur bloqué ne peut plus s'abonner",
            "insert into follows (follower_id, following_id) values ('%s', '%s')" % (blocked, adult),
            blocked, contains="bloqué")
    pr = json.loads(val("select get_public_profile('%s')" % adult, blocked))
    check("le joueur bloqué ne voit plus le profil", pr.get("unavailable") is True, pr)
    r = val("select private.can_private_message('%s', '%s')" % (blocked, adult))
    check("le joueur bloqué ne peut plus écrire en privé", "bloqué" in (r or ""), r)
    ca = val("insert into comments (user_id, video_id, content) values ('%s', '%s', 'avant') returning id"
             % (stranger, va), stranger)
    check("liste des joueurs bloqués", val("select count(*) from list_my_blocks()", adult) == "1")
    accepted("débloquer", "select unblock_user('%s')" % blocked, adult)
    check("après déblocage : vidéos de nouveau visibles",
          val("select count(*) from videos where id = '%s'" % va, blocked) == "1")

    print("— 5. Signaler et modérer")
    out = accepted("signalement d'une vidéo enregistré",
                   "select report_content('video', '%s', 'Contenu inapproprié')" % va, stranger)
    check("… avec le statut « en attente »",
          val("select status from content_reports where target_id = '%s' and reporter_id = '%s'" % (va, stranger)) == "pending")
    accepted("signalement d'un commentaire", "select report_content('comment', '%s', 'Spam')" % ca.splitlines()[0], adult)
    accepted("signalement d'un profil", "select report_content('profile', '%s', 'Fausse identité')" % stranger, adult)
    msg = val("select id from messages where conversation_id = '%s' limit 1" % conv) if conv else None
    if msg:
        accepted("signalement d'un message par le destinataire",
                 "select report_content('message', '%s', 'Harcèlement ou intimidation')" % msg, minor)
        refused("un message ne peut pas être signalé par quelqu'un d'extérieur",
                "select report_content('message', '%s', 'Spam')" % msg, stranger, contains="introuvable")
    r2 = new_user("rep2", years_ago(20))
    r3 = new_user("rep3", years_ago(21))
    val("select report_content('video', '%s', 'Contenu inapproprié')" % va, r2)
    check("2 signalements : vidéo encore visible", val("select status from videos where id = '%s'" % va) == "active")
    val("select report_content('video', '%s', 'Concerne un mineur en danger')" % va, r3)
    check("3 personnes différentes : vidéo masquée tout de suite en attendant la décision",
          val("select status from videos where id = '%s'" % va) == "flagged")
    admin = new_user("admin", years_ago(40))
    val("update profiles set role = 'admin' where id = '%s'" % admin)
    q = val("select count(*) from admin_moderation_queue('pending', 100) where target_id = '%s'" % va, admin)
    check("la vidéo est dans la file de modération (regroupée)", q == "1", q)
    if msg:
        mq = val("select minor_involved from admin_moderation_queue('pending', 100) where target_id = '%s'" % msg, admin)
        check("signalement d'un mineur : marqué « mineur concerné »", mq == "t", mq)
    refused("un non-admin ne voit pas la file", "select * from admin_moderation_queue('pending', 10)", stranger)
    rid = val("select id from content_reports where target_id = '%s' limit 1" % va)
    accepted("l'admin retire la vidéo",
             "select admin_resolve_report('%s', 'actioned', 'Vidéo retirée.', 'Merci.')" % rid, admin)
    row = val("select status, resolved_at is not null from content_reports where target_id = '%s' limit 1" % va)
    check("statut « traité » et date de traitement enregistrés", row == "actioned|t", row)
    check("vidéo retirée", val("select status from videos where id = '%s'" % va) == "removed")
    h = val("select count(*) from admin_moderation_queue('handled', 100) where target_id = '%s' and resolved_at is not null" % va, admin)
    check("historique des signalements traités avec date", h == "1", h)
    if msg:
        mid = val("select id from content_reports where target_id = '%s' limit 1" % msg)
        accepted("l'admin retire un message signalé", "select admin_resolve_report('%s', 'actioned')" % mid, admin)
        check("… le message est effacé", val("select count(*) from messages where id = '%s'" % msg) == "0")

    print("— 6. Achats de Ballons")
    val("insert into coin_packs (id, coins, price_cents, currency, sort_order, active) values "
        "('test_pack', 100, 199, 'eur', 99, true) on conflict (id) do nothing")
    refused("achat refusé à un mineur (réglage par défaut)", "select * from prepare_purchase('test_pack')", minor,
            contains="désactivés pour les moins de 18 ans")
    accepted("achat possible pour un majeur", "select * from prepare_purchase('test_pack')", adult)
    set_legal({"minor_purchases": "parental_consent"})
    refused("mode « accord parental » : refusé tant que le parent n'a pas accepté",
            "select * from prepare_purchase('test_pack')", minor, contains="accord de tes parents")
    token = json.loads(val("select request_parent_purchase_consent()", minor))["token"]
    info = json.loads(val("select get_parent_consent_request('%s')" % token, anon=True))
    check("le parent voit la demande sans compte", info.get("valid") is True, info)
    accepted("le parent accepte (lien à usage unique)", "select answer_parent_consent('%s', true)" % token, anon=True)
    refused("le lien ne sert qu'une fois", "select answer_parent_consent('%s', true)" % token, anon=True,
            contains="déjà utilisé")
    accepted("après l'accord du parent : achat possible", "select * from prepare_purchase('test_pack')", minor)
    set_legal({"minor_purchases": "disabled"})
    refused("réglage remis à « désactivé » : de nouveau refusé", "select * from prepare_purchase('test_pack')", minor)

    print("— 7. Battles aléatoires")
    val("update user_safety_settings set allow_random_battles = false where user_id <> '%s'" % adult)
    val("update user_safety_settings set allow_random_battles = false where user_id = '%s'" % adult)
    vb = video_of(adult)
    val("update profiles set coins = 1000 where id = '%s'" % adult)
    video_of(minor)
    refused("aucun adversaire aléatoire si personne ne l'a accepté (mineur non choisi)",
            "select create_battle('Battle test', '', 10, '%s', now() + interval '2 days', null, true)" % vb,
            adult, contains="Aucun adversaire")
    val("select update_my_safety_settings('{\"allow_random_battles\": true}')", minor)
    out = accepted("le mineur accepte les Battles aléatoires : il peut être choisi",
                   "select create_battle('Battle test', '', 10, '%s', now() + interval '2 days', null, true)" % vb, adult)
    if out:
        cid = json.loads(out)["challenge_id"]
        check("… et c'est bien lui", val("select opponent_id from challenges where id = '%s'" % cid) == minor)

    print("— 8. Séries quotidiennes")
    val("update profiles set last_login_date = current_date - 3, streak_days = 5 where id in ('%s', '%s')" % (minor, adult))
    val("select award_coins('daily_login', null, current_date)", minor)
    check("mineur : un jour manqué ne remet pas la série à zéro",
          val("select streak_days from profiles where id = '%s'" % minor) == "6")
    val("select award_coins('daily_login', null, current_date)", adult)
    check("majeur (réglage par défaut) : comportement habituel",
          val("select streak_days from profiles where id = '%s'" % adult) == "1")

    print("— 9. Droit à l'image")
    url = "https://abc.supabase.co/storage/v1/object/public/videos/%s/%s.mp4" % (adult, uuid.uuid4().hex)
    refused("publication refusée sans la case « j'ai le droit de publier »",
            "insert into videos (user_id, video_url, caption, category) values ('%s', '%s', 'x', 'dribble')"
            % (adult, url), adult, contains="droit de publier")
    accepted("publication acceptée avec la case cochée",
             "insert into videos (user_id, video_url, caption, category, rights_confirmed_at) "
             "values ('%s', '%s', 'x', 'dribble', now())" % (adult, url), adult)

    print("— 10. Suppression de compte")
    victim = new_user("delme", years_ago(17), minor=True)
    val("select block_user('%s')" % adult, victim)
    accepted("suppression de son compte", "select delete_my_account()", victim)
    gone = val(
        "select (select count(*) from profiles where id = '{0}') + (select count(*) from user_safety_settings where user_id = '{0}')"
        " + (select count(*) from user_blocks where blocker_id = '{0}') + (select count(*) from account_consents where user_id = '{0}')"
        " + (select count(*) from guardian_contacts where player_id = '{0}')".format(victim)
    )
    check("profil, réglages, blocages, consentements et e-mail du parent effacés", gone == "0", gone)


if __name__ == "__main__":
    main()
