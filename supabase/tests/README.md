# Tests de sécurité du backend

`security_checks.py` joue le rôle d'un client malveillant contre une
instance Supabase **locale** (jamais la production : il crée des comptes de
test et tente des fraudes) et vérifie que chaque tentative est refusée,
puis que les parcours normaux (publier, liker, suivre, défier, voter,
signaler, supprimer son compte) fonctionnent toujours.

```bash
supabase start          # depuis la racine du dépôt
python3 supabase/tests/security_checks.py
```

Toutes les lignes doivent afficher `OK`. Les variables `SUPABASE_URL` et
`SUPABASE_ANON_KEY` permettent de viser une autre instance de test.
