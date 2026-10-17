"""Tests de sécurité + non-régression du backend Supabase (instance LOCALE).

Joue le rôle d'un client malveillant (appels HTTP directs à l'API, comme
n'importe qui peut le faire avec la clé anonyme publique) et vérifie que
chaque fraude est refusée, puis que les parcours normaux fonctionnent.

    supabase start
    python3 supabase/tests/security_checks.py

Ne jamais lancer contre la production : crée des comptes de test.
"""

import datetime
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
import uuid

API = os.environ.get("SUPABASE_URL", "http://127.0.0.1:54321")
# Clé anonyme de démo publique de la CLI Supabase (identique sur toutes les
# installations locales) — pas un secret.
ANON = os.environ.get(
    "SUPABASE_ANON_KEY",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6"
    "ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0",
)
DB_URL = os.environ.get("SUPABASE_DB_URL", "postgresql://postgres:postgres@127.0.0.1:54322/postgres")

if "127.0.0.1" not in API and "localhost" not in API:
    sys.exit("Refusé : ce script ne vise qu'une instance locale.")


def req(method, path, body=None, token=None, headers=None):
    h = {"apikey": ANON, "Content-Type": "application/json", "Authorization": "Bearer " + (token or ANON)}
    if headers:
        h.update(headers)
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(API + path, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(r) as resp:
            text = resp.read().decode()
            return resp.status, (json.loads(text) if text else None)
    except urllib.error.HTTPError as e:
        text = e.read().decode()
        try:
            return e.code, json.loads(text)
        except ValueError:
            return e.code, text


def signup(name, role=None, birth=None):
    data = {"username": name}
    if role:
        data["role"] = role
    if birth:
        data["birth_date"] = birth
    s, b = req("POST", "/auth/v1/signup", {"email": f"{name}@test.dev", "password": "Passw0rd!123", "data": data})
    assert s == 200, (s, b)
    return b["access_token"], b["user"]["id"]


def rpc(fn, args, tok):
    return req("POST", f"/rest/v1/rpc/{fn}", args, tok)


def sel(path, tok=None):
    return req("GET", "/rest/v1/" + path, None, tok)


def ins(table, row, tok):
    return req("POST", "/rest/v1/" + table, row, tok, {"Prefer": "return=representation"})


def upd(path, row, tok):
    return req("PATCH", "/rest/v1/" + path, row, tok, {"Prefer": "return=representation"})


def profile(uid):
    return sel(f"profiles?id=eq.{uid}&select=coins,stars,followers_count")[1][0]


RESULTS = []


def check(name, cond, info=""):
    RESULTS.append((cond, name, str(info)[:200]))


def main():
    sfx = uuid.uuid4().hex[:6]
    a_tok, a = signup("ana" + sfx, birth="2012-05-01")  # joueuse mineure
    b_tok, b = signup("ben" + sfx)
    c_tok, c = signup("cid" + sfx)
    check("bonus de bienvenue = 100 Ballons", profile(b)["coins"] == 100, profile(b))
    # Les scénarios ci-dessous dépensent plus : on recharge les comptes de test
    # par une vraie transaction pour garder le grand livre juste.
    for uid in (a, b, c):
        subprocess.run(["psql", DB_URL, "-Atqc",
                        f"update profiles set coins = coins + 900 where id='{uid}'; "
                        f"insert into transactions (user_id, type, amount, currency, balance_after, reason) "
                        f"select id, 'earn', 900, 'coins', coins, 'test_topup' from profiles where id='{uid}'"],
                       check=True)
    today = datetime.date.today().isoformat()
    storage = f"{API}/storage/v1/object/public"

    # --- Parcours normaux -------------------------------------------------
    s, r = ins("videos", {"user_id": a, "video_url": f"{storage}/videos/{a}/x.mp4", "category": "dribble",
                          "is_move": True, "move_name": "Roulette"}, a_tok)
    check("publier un Move", s == 201, r)
    vid = r[0]["id"]
    s, r = ins("videos", {"user_id": b, "video_url": f"{storage}/videos/{b}/y.mp4", "category": "dribble",
                          "original_move_id": vid}, b_tok)
    check("reproduire un Move", s == 201, r)
    ins("videos", {"user_id": b, "video_url": f"{storage}/videos/{b}/z.mp4", "category": "dribble",
                   "original_move_id": vid}, b_tok)
    s, r = rpc("award_coins", {"p_reason": "post_video", "p_reference_id": vid, "p_local_date": today}, a_tok)
    check("récompense vidéo publiée", s == 200, r)
    s, r = rpc("award_coins", {"p_reason": "daily_login", "p_local_date": today}, a_tok)
    check("connexion du jour suivie sans Ballon (règles v2)", s == 200 and r["amount_awarded"] == 0, r)
    s, r = ins("likes", {"user_id": b, "video_id": vid, "type": "like"}, b_tok)
    check("liker", s == 201, r)
    s, r = upd(f"likes?user_id=eq.{b}&video_id=eq.{vid}", {"type": "masterclass"}, b_tok)
    check("passer un like en Masterclass", s == 200 and r, r)
    s, r = ins("comments", {"user_id": b, "video_id": vid, "content": "Énorme"}, b_tok)
    check("commenter", s == 201, r)
    s, r = ins("follows", {"follower_id": b, "following_id": a}, b_tok)
    check("suivre un joueur", s == 201, r)
    for t in (b_tok, b_tok, c_tok):
        rpc("increment_video_views", {"p_video_id": vid}, t)
    s, r = sel(f"videos?id=eq.{vid}&select=views_count,likes_count,masterclass_count,comments_count,reproductions_count", a_tok)
    check("compteurs exacts (vues dédupliquées)", r and r[0] == {"views_count": 2, "likes_count": 0, "masterclass_count": 1,
                                                       "comments_count": 1, "reproductions_count": 2}, r)
    check("compteur d'abonnés", profile(a)["followers_count"] == 1, profile(a))
    s, r = sel("transactions?select=reason&reason=eq.move_reproduced", a_tok)
    check("Move reproduit : plus aucun Ballon (règles v2)", len(r) == 0, r)
    s, r = rpc("get_my_profile", {}, a_tok)
    check("lire sa propre date de naissance", s == 200 and r[0]["birth_date"] == "2012-05-01", r)
    s, r = req("PATCH", f"/rest/v1/profiles?id=eq.{a}&select=id,bio", {"bio": "Ailier gauche"}, a_tok,
               {"Prefer": "return=representation"})
    check("modifier son profil", s == 200 and r[0]["bio"] == "Ailier gauche", r)
    end = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=2)).isoformat()
    s, r = rpc("create_challenge", {"p_title": "Roi du jongle", "p_description": "d", "p_type": "challenge",
                                    "p_end_date": end}, c_tok)
    check("créer un défi", s == 200, r)
    cid = r["challenge_id"]
    s, r = rpc("join_challenge", {"p_challenge_id": cid, "p_video_id": vid}, a_tok)
    check("rejoindre un défi", s == 200, r)
    s, r = rpc("vote_for_participant", {"p_challenge_id": cid, "p_participant_id": a}, b_tok)
    check("voter", s == 200, r)
    s, r = sel("conversations?select=id,status", c_tok)
    check("lister ses conversations", s == 200, r)

    # --- Fraudes : toutes doivent échouer ----------------------------------
    before = profile(a)["coins"]
    for i in range(5):
        d = (datetime.date(2001, 1, 1) + datetime.timedelta(days=i)).isoformat()
        rpc("award_coins", {"p_reason": "daily_login", "p_local_date": d}, a_tok)
        rpc("award_coins", {"p_reason": "ad_watched", "p_local_date": d}, a_tok)
        rpc("increment_videos_watched", {"p_local_date": d}, a_tok)
    check("FRAUDE dates inventées = 0 Ballon", profile(a)["coins"] == before, profile(a))
    s, r = rpc("award_coins", {"p_reason": "daily_login", "p_local_date": today}, a_tok)
    check("FRAUDE double bonus de connexion refusé", s == 400, r)
    s, r = rpc("award_coins", {"p_reason": "post_video", "p_reference_id": vid}, a_tok)
    check("FRAUDE double récompense vidéo refusée", s == 400, r)
    s, r = rpc("create_challenge", {"p_title": "Cagnotte magique", "p_description": "d", "p_type": "challenge",
                                    "p_end_date": end, "p_prize_pool": 1000000}, c_tok)
    pool = sel(f"challenges?id=eq.{r.get('challenge_id')}&select=prize_pool")[1] if s == 200 else None
    check("FRAUDE cagnotte gratuite ignorée", pool == [{"prize_pool": 0}], (s, r, pool))
    s, r = ins("videos", {"user_id": a, "video_url": f"{storage}/videos/{a}/f.mp4", "category": "dribble",
                          "views_count": 99, "talent_score": 999, "is_boosted": True}, a_tok)
    check("FRAUDE vidéo avec stats truquées refusée", s in (401, 403), r)
    s, r = ins("videos", {"user_id": b, "video_url": "https://evil.example/x.mp4", "category": "dribble"}, b_tok)
    check("FRAUDE vidéo hébergée ailleurs refusée", s == 400, r)
    stars = profile(a)["stars"]
    for _ in range(100):
        rpc("increment_video_views", {"p_video_id": vid}, b_tok)
    check("FRAUDE 100 vues du même compte = 0 Star", profile(a)["stars"] == stars, profile(a))
    s, r = upd(f"profiles?id=eq.{a}", {"coins": 99999}, a_tok)
    check("FRAUDE modifier ses Ballons refusé", s in (401, 403), r)
    s, r = sel(f"profiles?id=eq.{a}&select=username,birth_date")
    check("CONFIDENTIALITÉ date de naissance cachée (anonyme)", s in (401, 403), r)
    s, r = sel(f"profiles?id=eq.{a}&select=birth_date", b_tok)
    check("CONFIDENTIALITÉ date de naissance cachée (connecté)", s in (401, 403), r)
    s, r = upd(f"notifications?user_id=eq.{a}", {"title": "pirate"}, a_tok)
    check("FRAUDE modifier le texte d'une notification refusé", s in (401, 403), r)
    s, r = upd(f"comments?user_id=eq.{b}", {"likes_count": 5000}, b_tok)
    check("FRAUDE gonfler les likes d'un commentaire refusé", s in (401, 403), r)
    s, r = rpc("resolve_expired_challenges", {}, a_tok)
    check("FRAUDE déclencher la résolution des défis refusé", s in (401, 403, 404), r)
    s, r = rpc("find_ledger_drift", {}, a_tok)
    check("ADMIN contrôle du grand livre réservé", s in (400, 403), r)

    # Mineure : un recruteur ne doit jamais pouvoir s'auto-approuver.
    sc_tok, sc = signup("scout" + sfx, role="scout")
    req("POST", "/rest/v1/guardian_contacts", {"player_id": a, "guardian_email": "parent@test.dev"}, a_tok)
    rpc("start_scout_trial", {}, sc_tok)
    s, r = rpc("request_scout_contact", {"p_player_id": a}, sc_tok)
    check("contact recruteur -> mineure en attente du tuteur", s == 200 and r["status"] == "pending_guardian_approval", r)
    s, r = sel("conversations?select=guardian_approval_token", sc_tok)
    check("MINEURS jeton tuteur illisible par le recruteur", s in (401, 403), r)

    # Admin : modération réelle + grand livre cohérent.
    subprocess.run(["psql", DB_URL, "-Atqc", f"update profiles set role='admin' where id='{c}'"], check=True)
    s, r = rpc("find_ledger_drift", {}, c_tok)
    check("grand livre = soldes (aucune dérive)", s == 200 and r == [], r)
    s, r = ins("content_reports", {"target_type": "video", "target_id": vid, "reporter_id": b, "reason": "spam"}, b_tok)
    check("signaler une vidéo", s == 201, r)
    s, r = rpc("admin_resolve_report", {"p_report_id": r[0]["id"], "p_status": "actioned"}, c_tok)
    check("admin retire la vidéo signalée", s == 200, r)
    s, r = sel(f"videos?id=eq.{vid}&select=status", b_tok)
    check("vidéo retirée invisible", r == [], r)

    # Panneau admin : statistiques, signalements avec messages, bannissement,
    # défis officiels. Tout est refusé à un non-admin.
    s, r = rpc("admin_dashboard_stats", {}, a_tok)
    check("ADMIN stats refusées à un joueur", s in (401, 403), r)
    s, r = rpc("admin_set_ban", {"p_user_id": b, "p_banned": True, "p_reason": "x"}, a_tok)
    check("ADMIN bannissement refusé à un joueur", s in (401, 403), r)
    s, r = rpc("admin_dashboard_stats", {}, c_tok)
    check("admin voit les statistiques", s == 200 and r["players_total"] >= 2, r)
    s, r = sel(f"videos?user_id=eq.{b}&select=id&limit=1", a_tok)
    bvid = r[0]["id"]
    ins("content_reports", {"target_type": "video", "target_id": bvid, "reporter_id": a, "reason": "Spam"}, a_tok)
    s, r = rpc("admin_list_reports", {}, c_tok)
    rep = next((x for x in (r or []) if x["target_id"] == bvid), None)
    check("admin voit le signalement avec l'auteur", s == 200 and rep and rep["author_id"] == b and rep["video_url"], r)
    s, r = rpc("admin_resolve_report", {"p_report_id": rep["report_id"], "p_status": "dismissed",
                                        "p_author_message": "Ta vidéo reste en ligne.",
                                        "p_reporter_message": "Merci, le contenu respecte nos règles."}, c_tok)
    check("admin garde la vidéo avec messages", s == 200 and r["reports_closed"] == 1, r)
    s, r = sel("notifications?type=eq.moderation&select=body", b_tok)
    check("l'auteur reçoit le message de modération", s == 200 and len(r) == 1, r)
    s, r = sel("notifications?type=eq.moderation&select=body", a_tok)
    check("le signaleur reçoit la réponse", s == 200 and len(r) == 1, r)
    s, r = rpc("admin_set_ban", {"p_user_id": c, "p_banned": True, "p_reason": "x"}, c_tok)
    check("un admin ne peut pas se bannir", s >= 400, r)
    s, r = rpc("admin_set_ban", {"p_user_id": b, "p_banned": True, "p_reason": "Triche"}, c_tok)
    check("admin bannit un joueur", s == 200, r)
    s, r = req("POST", "/auth/v1/token?grant_type=password", {"email": f"ben{sfx}@test.dev", "password": "Passw0rd!123"})
    check("joueur banni ne peut plus se connecter", s >= 400, r)
    s, r = sel(f"videos?user_id=eq.{b}&select=id", a_tok)
    check("vidéos du joueur banni masquées", r == [], r)
    s, r = sel("profiles?select=is_banned&limit=1", a_tok)
    check("statut de bannissement illisible via l'API", s in (401, 403), r)
    s, r = rpc("admin_list_users", {"p_search": "ben" + sfx}, c_tok)
    check("admin retrouve le joueur (banni)", s == 200 and len(r) == 1 and r[0]["is_banned"], r)
    s, r = rpc("admin_set_ban", {"p_user_id": b, "p_banned": False}, c_tok)
    s, r2 = req("POST", "/auth/v1/token?grant_type=password", {"email": f"ben{sfx}@test.dev", "password": "Passw0rd!123"})
    check("débannir rend la connexion", s == 200 and r2.get("access_token"), r2)
    b_tok = r2["access_token"]
    s, r = sel(f"videos?user_id=eq.{b}&select=id", a_tok)
    check("débannir remet les vidéos", len(r) >= 1, r)
    end = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=13)).isoformat()
    s, r = rpc("admin_create_official_challenge", {"p_title": "Défi Ballon d'Or", "p_description": "x",
                                                   "p_end_date": end}, a_tok)
    check("ADMIN défi officiel refusé à un joueur", s in (401, 403), r)
    s, r = rpc("admin_create_official_challenge", {"p_title": "Défi Ballon d'Or", "p_description": "x",
                                                   "p_end_date": end, "p_prize_description": "Maillot"}, c_tok)
    check("admin crée un défi officiel", s == 200, r)
    s, r = sel(f"challenges?id=eq.{r['challenge_id']}&select=type,is_official,entry_cost", a_tok)
    check("défi officiel gratuit et marqué officiel", r == [{"type": "world", "is_official": True, "entry_cost": 0}], r)

    # --- Règles v2 : visionnage complet, Challenge daté, Battle 1 contre 1 ---
    def sql(q):
        return subprocess.run(["psql", DB_URL, "-Atqc", q], capture_output=True, text=True).stdout.strip()

    s, r = ins("videos", {"user_id": b, "video_url": f"{storage}/videos/{b}/w1.mp4", "category": "dribble",
                          "duration_seconds": 10}, b_tok)
    wv1 = r[0]["id"]
    s, r = ins("videos", {"user_id": b, "video_url": f"{storage}/videos/{b}/w2.mp4", "category": "dribble",
                          "duration_seconds": 10}, b_tok)
    wv2 = r[0]["id"]
    s, r = ins("videos", {"user_id": a, "video_url": f"{storage}/videos/{a}/av.mp4", "category": "dribble",
                          "duration_seconds": 12}, a_tok)
    avid = r[0]["id"]
    s, r = ins("videos", {"user_id": c, "video_url": f"{storage}/videos/{c}/cv.mp4", "category": "dribble"}, c_tok)
    d_tok, d = signup("dan" + sfx)
    sql(f"update profiles set coins = coins + 900 where id='{d}'; "
        f"insert into transactions (user_id, type, amount, currency, balance_after, reason) "
        f"select id, 'earn', 900, 'coins', coins, 'test_topup' from profiles where id='{d}'")
    rpc("start_video_watch", {"p_video_id": wv1, "p_local_date": today}, a_tok)
    s, r = rpc("complete_video_watch", {"p_video_id": wv1, "p_duration_seconds": 10, "p_local_date": today}, a_tok)
    check("FRAUDE vidéo « regardée » trop vite non comptée", s == 200 and not r["counted"], r)
    sql(f"update private.video_watch_sessions set started_at = now() - interval '11 seconds' where user_id='{a}'")
    s, r = rpc("complete_video_watch", {"p_video_id": wv1, "p_duration_seconds": 10, "p_local_date": today}, a_tok)
    check("vidéo regardée en entier comptée", s == 200 and r["counted"] and r["full_videos_watched"] == 1, r)
    s, r = rpc("complete_video_watch", {"p_video_id": wv1, "p_duration_seconds": 10, "p_local_date": today}, a_tok)
    check("FRAUDE même vidéo comptée deux fois refusée", s == 200 and not r["counted"], r)
    rpc("start_video_watch", {"p_video_id": vid, "p_local_date": today}, a_tok)
    s, r = rpc("complete_video_watch", {"p_video_id": vid, "p_duration_seconds": 5, "p_local_date": today}, a_tok)
    check("FRAUDE regarder sa propre vidéo ne compte pas", s == 200 and not r["counted"], r)
    sql(f"update daily_missions set full_videos_watched = 19, last_full_watch_at = now() - interval '1 minute' "
        f"where user_id='{a}' and mission_date='{today}'")
    rpc("start_video_watch", {"p_video_id": wv2, "p_local_date": today}, a_tok)
    sql(f"update private.video_watch_sessions set started_at = now() - interval '11 seconds' where user_id='{a}' and video_id='{wv2}'")
    coins = profile(a)["coins"]
    s, r = rpc("complete_video_watch", {"p_video_id": wv2, "p_duration_seconds": 10, "p_local_date": today}, a_tok)
    check("20 vidéos en entier = 30 Ballons", s == 200 and r["reward_awarded"] and profile(a)["coins"] == coins + 30, r)

    start = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=1)).isoformat()
    end2 = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=3)).isoformat()
    s, r = rpc("create_challenge", {"p_title": "Défi de demain", "p_description": "d", "p_type": "challenge",
                                    "p_start_date": start, "p_end_date": end2}, d_tok)
    check("créer un Challenge avec date de début", s == 200, r)
    s, r = rpc("join_challenge", {"p_challenge_id": (r or {}).get("challenge_id") if isinstance(r, dict) else None, "p_video_id": avid}, a_tok)
    check("participer avant le début refusé", s == 400 and "pas encore commencé" in str(r), r)
    for t in ("world", "king", "battle"):
        s, r = rpc("create_challenge", {"p_title": "Interdit " + t, "p_description": "d", "p_type": t,
                                        "p_end_date": end}, a_tok)
        check(f"FRAUDE joueur crée un défi {t} par create_challenge refusé", s == 400, r)

    a_coins, b_coins = profile(a)["coins"], profile(b)["coins"]
    s, r = rpc("create_battle", {"p_title": "Plus beau but", "p_rules": "Le plus beau but gagne", "p_stake": 30,
                                 "p_video_id": avid, "p_end_date": end, "p_opponent_username": "ben" + sfx}, a_tok)
    check("lancer une Battle avec mise", s == 200 and profile(a)["coins"] == a_coins - 30, r)
    bid = r.get("challenge_id") if isinstance(r, dict) else None
    s, r = rpc("join_challenge", {"p_challenge_id": bid, "p_video_id": avid}, c_tok)
    check("FRAUDE rejoindre la Battle d'un autre refusé", s == 400, r)
    s, r = rpc("vote_for_participant", {"p_challenge_id": bid, "p_participant_id": a}, c_tok)
    check("vote avant que l'adversaire relève refusé", s == 400, r)
    s, r = rpc("join_challenge", {"p_challenge_id": bid, "p_video_id": wv1}, b_tok)
    check("l'adversaire relève la Battle (même mise)", s == 200 and profile(b)["coins"] == b_coins - 30, r)
    s, r = rpc("vote_for_participant", {"p_challenge_id": bid, "p_participant_id": b}, a_tok)
    check("FRAUDE un joueur de la Battle vote refusé", s == 400, r)
    s, r = rpc("vote_for_participant", {"p_challenge_id": bid, "p_participant_id": b}, d_tok)
    check("FRAUDE compte neuf sans vidéo ne vote pas", s == 400, r)
    s, r = rpc("vote_for_participant", {"p_challenge_id": bid, "p_participant_id": b}, c_tok)
    check("un joueur avec vidéo vote", s == 200, r)
    b_coins, b_stars = profile(b)["coins"], profile(b)["stars"]
    sql("select refresh_form_scores()")
    form_before = {r["id"]: r["form_score"] for r in sel(f"profiles?id=in.({a},{b})&select=id,form_score")[1]}
    sql(f"update challenges set end_date = now() - interval '1 minute' where id='{bid}'")
    sql("select resolve_expired_challenges()")
    check("le gagnant de la Battle prend les 2 mises + 100 Stars",
          profile(b)["coins"] == b_coins + 60 and profile(b)["stars"] == b_stars + 100, profile(b))
    sql("select refresh_form_scores()")
    after = {r["id"]: r["form_score"] for r in sel(f"profiles?id=in.({a},{b})&select=id,form_score")[1]}
    check("forme : la Battle gagnée fait monter, la perdue fait baisser",
          after.get(b) == form_before[b] + 2 and after.get(a) == form_before[a] - 2, (form_before, after))
    s, r = upd(f"profiles?id=eq.{a}", {"form_score": 10}, a_tok)
    check("FRAUDE modifier sa propre forme refusé", s in (401, 403), r)

    a_coins = profile(a)["coins"]
    s, r = rpc("create_battle", {"p_title": "Qui jongle le plus", "p_rules": "x", "p_stake": 20,
                                 "p_video_id": avid, "p_end_date": end}, a_tok)
    bid2 = r.get("challenge_id") if isinstance(r, dict) else None
    sql(f"update challenges set end_date = now() - interval '1 minute' where id='{bid2}'")
    sql("select resolve_expired_challenges()")
    st = sel(f"challenges?id=eq.{bid2}&select=status")[1]
    check("Battle sans adversaire : mise rendue", profile(a)["coins"] == a_coins and st == [{"status": "cancelled"}],
          (profile(a), st))
    s, r = rpc("create_battle", {"p_title": "Trop cher", "p_rules": "x", "p_stake": 999999,
                                 "p_video_id": avid, "p_end_date": end}, a_tok)
    check("FRAUDE mise hors limites refusée", s == 400, r)
    s, r = rpc("find_ledger_drift", {}, c_tok)
    check("grand livre toujours juste après Battles et remboursements", s == 200 and r == [], r)
    s, r = rpc("delete_my_account", {}, b_tok)
    check("supprimer son compte", s == 204, r)

    failed = 0
    for ok, name, info in RESULTS:
        print(("OK   " if ok else "FAIL ") + name + ("" if ok else f"  -> {info}"))
        failed += 0 if ok else 1
    print(f"\n{len(RESULTS) - failed}/{len(RESULTS)} vérifications réussies")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
