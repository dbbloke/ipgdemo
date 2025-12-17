const jsonHeaders = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export async function onRequestOptions() {
  return new Response(null, { status: 204, headers: jsonHeaders });
}

export async function onRequestPost({ request, env }) {
  if (!env.SENDGRID_API_KEY || !env.CONTACT_TO_EMAIL || !env.CONTACT_FROM_EMAIL) {
    return new Response(
      JSON.stringify({
        error: 'Email is not configured. Add SENDGRID_API_KEY, CONTACT_TO_EMAIL, CONTACT_FROM_EMAIL.',
      }),
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

  const { email, name, message } = payload;
  if (!email || !message) {
    return new Response(JSON.stringify({ error: 'Email and message are required.' }), {
      status: 400,
      headers: jsonHeaders,
    });
  }

  const content = [
    `From: ${name || 'Anonymous'} <${email}>`,
    '---',
    message,
  ].join('\n');

  const mail = {
    personalizations: [
      {
        to: [{ email: env.CONTACT_TO_EMAIL }],
        subject: 'New message from d13mon contact form',
      },
    ],
    from: { email: env.CONTACT_FROM_EMAIL, name: 'd13mon site' },
    reply_to: { email, name: name || 'Website visitor' },
    content: [{ type: 'text/plain', value: content }],
  };

  const sendResponse = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.SENDGRID_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(mail),
  });

  if (!sendResponse.ok) {
    const detail = await sendResponse.text();
    return new Response(JSON.stringify({ error: 'Email failed to send.', detail }), {
      status: 502,
      headers: jsonHeaders,
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: jsonHeaders,
  });
}
