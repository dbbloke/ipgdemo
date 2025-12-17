const jsonHeaders = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export async function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: jsonHeaders,
  });
}

export async function onRequestPost({ request, env }) {
  if (!env.STRIPE_SECRET_KEY) {
    return new Response(
      JSON.stringify({ error: 'Stripe is not configured. Add STRIPE_SECRET_KEY.' }),
      { status: 500, headers: jsonHeaders },
    );
  }

  const payload = await request.json().catch(() => null);
  if (!payload) {
    return new Response(JSON.stringify({ error: 'Invalid JSON payload.' }), {
      status: 400,
      headers: jsonHeaders,
    });
  }

  const priceId = payload.priceId || env.STRIPE_PRICE_ID;
  if (!priceId) {
    return new Response(
      JSON.stringify({ error: 'Provide priceId in the payload or set STRIPE_PRICE_ID.' }),
      { status: 400, headers: jsonHeaders },
    );
  }

  const quantity = Number(payload.quantity ?? 1);
  const origin = request.headers.get('Origin') || request.headers.get('origin');
  const successUrl = payload.successUrl || env.STRIPE_SUCCESS_URL || `${origin || ''}/thank-you.html`;
  const cancelUrl = payload.cancelUrl || env.STRIPE_CANCEL_URL || origin || '';

  const body = new URLSearchParams({
    mode: 'payment',
    'line_items[0][price]': priceId,
    'line_items[0][quantity]': String(quantity > 0 ? quantity : 1),
    success_url: successUrl,
    cancel_url: cancelUrl,
  });

  const stripeResponse = await fetch('https://api.stripe.com/v1/checkout/sessions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  });

  if (!stripeResponse.ok) {
    const detail = await stripeResponse.text();
    return new Response(
      JSON.stringify({ error: 'Stripe checkout could not be created.', detail }),
      { status: 502, headers: jsonHeaders },
    );
  }

  const session = await stripeResponse.json();
  return new Response(JSON.stringify({ url: session.url, id: session.id }), {
    status: 200,
    headers: jsonHeaders,
  });
}
