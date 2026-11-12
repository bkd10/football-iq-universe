// Ouvre une page de paiement Stripe pour un pack de Ballons.
//
// Le prix vient de la base (`prepare_purchase`), jamais de l'appli. Les
// contrôles d'âge, d'accord parental et de plafond des mineurs sont faits
// par `prepare_purchase`, avec la session du joueur.
//
// Secrets à définir dans Supabase (Edge Functions > Secrets) :
//   STRIPE_SECRET_KEY  clé secrète Stripe (sk_live_... ou sk_test_...)

import { createClient } from 'npm:@supabase/supabase-js@2.45.4';
import { allowedOrigin, corsHeaders, json, stripeRequest } from '../_shared/stripe.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Méthode non autorisée.' }, 405);

  const authorization = req.headers.get('Authorization');
  if (!authorization) return json({ error: 'Connexion requise.' }, 401);

  let packId: string | undefined;
  let origin: string | undefined;
  try {
    const body = await req.json();
    packId = body?.pack_id;
    origin = body?.return_origin;
  } catch {
    return json({ error: 'Requête invalide.' }, 400);
  }
  if (!packId) return json({ error: 'Pack introuvable.' }, 400);

  const url = Deno.env.get('SUPABASE_URL')!;
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authorization } },
  });
  const { data, error } = await userClient.rpc('prepare_purchase', { p_pack_id: packId });
  if (error) return json({ error: error.message }, 400);
  const purchase = (data as Array<Record<string, unknown>>)?.[0];
  if (!purchase) return json({ error: 'Pack introuvable.' }, 400);

  const appOrigin = allowedOrigin(origin);
  try {
    const params: Record<string, string> = {
      mode: 'payment',
      'line_items[0][quantity]': '1',
      'line_items[0][price_data][currency]': String(purchase.currency),
      'line_items[0][price_data][unit_amount]': String(purchase.amount_cents),
      'line_items[0][price_data][product_data][name]': `${purchase.coins} Ballons – Football IQ`,
      'line_items[0][price_data][product_data][description]':
        'Monnaie virtuelle du jeu, sans valeur en argent, non misable.',
      success_url: `${appOrigin}/#/wallet?achat=ok`,
      cancel_url: `${appOrigin}/#/wallet/shop`,
      client_reference_id: String(purchase.purchase_id),
      'metadata[purchase_id]': String(purchase.purchase_id),
      'payment_intent_data[metadata][purchase_id]': String(purchase.purchase_id),
      // Repris sur le reçu envoyé par Stripe (support durable) : confirme
      // l'accord pour la livraison immédiate et la renonciation (art. L221-13
      // du Code de la consommation).
      'payment_intent_data[description]':
        `${purchase.coins} Ballons – Football IQ. Contenu numérique livré immédiatement : ` +
        'livraison immédiate demandée et renonciation au droit de rétractation acceptées avant le paiement.',
      locale: 'auto',
      // Contenu numérique livré tout de suite : le client renonce au délai
      // de rétractation (affiché aussi dans les Règles des Ballons).
      'consent_collection[terms_of_service]': 'required',
      'custom_text[terms_of_service_acceptance][message]':
        "J'accepte les règles des Ballons et la livraison immédiate : je renonce au délai de rétractation de 14 jours.",
    };
    if (purchase.email) params.customer_email = String(purchase.email);
    const session = await stripeRequest('checkout/sessions', params);

    const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { error: attachError } = await admin.rpc('attach_checkout_session', {
      p_purchase_id: purchase.purchase_id,
      p_session_id: session.id,
    });
    if (attachError) return json({ error: 'Une erreur serveur est survenue.' }, 500);

    return json({ url: session.url });
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : 'Erreur Stripe.' }, 502);
  }
});
