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
    check("bonus de connexion du jour", s == 200, r)
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
    check("Move reproduit récompensé une seule fois par joueur", len(r) == 1, r)
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
