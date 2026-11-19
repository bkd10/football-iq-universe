// Envoie au parent l'e-mail qui lui permet de valider (ou refuser) le
// compte de son enfant, quand celui-ci a moins que l'âge de consentement
// de son pays (`app_config.legal.parental_consent_under`).
//
// Le lien, l'adresse du parent et la limite d'envoi (une fois toutes les
// 10 minutes, 5 par jour) viennent de `request_parent_signup_consent`,
// appelée avec la session du joueur.
//
// Secrets à définir dans Supabase (Edge Functions > Secrets) :
//   RESEND_API_KEY       clé de l'API Resend (https://resend.com)
//   PARENT_EMAIL_FROM    expéditeur vérifié, ex. "Football IQ <securite@ton-domaine>"
// Sans ces secrets, rien n'est envoyé : l'appli copie le lien pour que le
// joueur le transmette lui-même.

import { createClient } from 'npm:@supabase/supabase-js@2.45.4';
import { allowedOrigin, corsHeaders, json } from '../_shared/stripe.ts';

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders(req) });
  if (req.method !== 'POST') return json(req, { error: 'Méthode non autorisée.' }, 405);

  const authorization = req.headers.get('Authorization');
  if (!authorization) return json(req, { error: 'Connexion requise.' }, 401);

  let origin: string | undefined;
  try {
    origin = (await req.json())?.return_origin;
  } catch {
    origin = undefined;
  }

  const userClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authorization } },
  });
  const { data, error } = await userClient.rpc('request_parent_signup_consent');
  if (error) return json(req, { error: error.message }, 400);
  const info = data as { token: string; guardian_email: string | null; username: string };
  const link = `${allowedOrigin(origin)}/#/parent/${info.token}`;

  const apiKey = Deno.env.get('RESEND_API_KEY');
  const from = Deno.env.get('PARENT_EMAIL_FROM');
  if (!apiKey || !from || !info.guardian_email) {
    return json(req, { sent: false, link });
  }

  const name = escapeHtml(info.username ?? '');
  const html = `
<p>Bonjour,</p>
<p>@${name} vient de créer un compte sur <b>Football IQ</b>, un jeu de football (vidéos, défis, classements) édité par Bkd sport Ltd, Londres.
Comme il ou elle est mineur(e), son compte reste bloqué (pas de publication, de commentaire, de message ni d'achat) tant que vous n'avez pas donné votre accord.</p>
<p><a href="${link}">Valider ou refuser le compte</a></p>
<p>Le compte démarre avec les réglages les plus protecteurs : profil limité, messages privés seulement entre abonnés mutuels, ville cachée, aucun achat.
Si vous n'êtes pas concerné(e), ignorez cet e-mail.</p>
<hr>
<p>Hello,</p>
<p>@${name} has just created an account on <b>Football IQ</b>, a football game (videos, challenges, rankings) run by Bkd sport Ltd, London.
As they are under age, the account stays locked (no posting, comments, messages or purchases) until you give your consent.</p>
<p><a href="${link}">Approve or decline the account</a></p>
<p>The account starts with the most protective settings: limited profile, private messages only between mutual followers, city hidden, no purchases.
If this doesn't concern you, please ignore this email.</p>`;

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from,
      to: [info.guardian_email],
      subject: 'Football IQ : accord parental demandé / parental consent requested',
      html,
    }),
  });
  if (!res.ok) {
    console.error('Resend', res.status, await res.text());
    return json(req, { sent: false, link });
  }
  return json(req, { sent: true, guardian_email: info.guardian_email });
});
