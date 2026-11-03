// Reçoit les événements Stripe et crédite les Ballons.
//
// À déclarer dans Stripe (Développeurs > Webhooks) avec l'adresse
//   https://<projet>.supabase.co/functions/v1/stripe-webhook
// et les événements : checkout.session.completed,
// checkout.session.async_payment_succeeded, checkout.session.expired,
// charge.refunded.
//
// Secret à définir dans Supabase : STRIPE_WEBHOOK_SECRET (whsec_...).
// Seuls les messages signés par Stripe sont acceptés.

import { createClient } from 'npm:@supabase/supabase-js@2.45.4';
import { verifyStripeSignature } from '../_shared/stripe.ts';

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Méthode non autorisée', { status: 405 });
  const secret = Deno.env.get('STRIPE_WEBHOOK_SECRET');
  if (!secret) return new Response('Webhook non configuré', { status: 500 });

  const raw = await req.text();
  const ok = await verifyStripeSignature(raw, req.headers.get('Stripe-Signature'), secret);
  if (!ok) return new Response('Signature invalide', { status: 400 });

  const event = JSON.parse(raw);
  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const obj = event?.data?.object ?? {};

  let error: unknown = null;
  switch (event.type) {
    case 'checkout.session.completed':
    case 'checkout.session.async_payment_succeeded':
      if (obj.payment_status === 'paid') {
        ({ error } = await admin.rpc('complete_purchase', {
          p_session_id: obj.id,
          p_amount_total: obj.amount_total,
          p_currency: obj.currency,
          p_payment_intent: obj.payment_intent ?? null,
        }));
      }
      break;
    case 'checkout.session.expired':
      ({ error } = await admin.rpc('expire_purchase', { p_session_id: obj.id }));
      break;
    case 'charge.refunded':
      if (obj.payment_intent) {
        ({ error } = await admin.rpc('refund_purchase', { p_payment_intent: obj.payment_intent }));
      }
      break;
  }

  // Une erreur renvoie 500 : Stripe réessaiera plus tard.
  if (error) return new Response('Erreur', { status: 500 });
  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
