// Outils partagés par les fonctions Stripe.

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/** Adresse de retour autorisée après le paiement (site et versions test). */
export function allowedOrigin(origin: string | undefined | null): string {
  const fallback = 'https://football-iq-universe.pages.dev';
  if (!origin) return fallback;
  const extra = (Deno.env.get('APP_ORIGINS') ?? '').split(',').map((s) => s.trim()).filter(Boolean);
  if (extra.includes(origin)) return origin;
  if (/^https:\/\/([a-z0-9-]+\.)?football-iq-universe\.pages\.dev$/.test(origin)) return origin;
  return fallback;
}

/** Appel à l'API Stripe (formulaire encodé, comme l'exige Stripe). */
export async function stripeRequest(path: string, params: Record<string, string>) {
  const key = Deno.env.get('STRIPE_SECRET_KEY');
  if (!key) throw new Error('Paiement pas encore activé.');
  const res = await fetch(`https://api.stripe.com/v1/${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams(params),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(body?.error?.message ?? 'Erreur Stripe.');
  return body;
}

function toHex(buf: ArrayBuffer): string {
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

/**
 * Vérifie l'en-tête `Stripe-Signature` (HMAC SHA-256 de `t.corps`), comme
 * la bibliothèque officielle. Refuse un message de plus de 5 minutes.
 */
export async function verifyStripeSignature(
  rawBody: string,
  header: string | null,
  secret: string,
  toleranceSeconds = 300,
  nowSeconds = Math.floor(Date.now() / 1000),
): Promise<boolean> {
  if (!header) return false;
  const parts = header.split(',').map((p) => p.split('='));
  const t = parts.find(([k]) => k === 't')?.[1];
  const signatures = parts.filter(([k]) => k === 'v1').map(([, v]) => v);
  if (!t || signatures.length === 0) return false;
  if (Math.abs(nowSeconds - Number(t)) > toleranceSeconds) return false;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const expected = toHex(await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(`${t}.${rawBody}`)));
  return signatures.some((s) => safeEqual(s, expected));
}
