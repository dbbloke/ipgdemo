# d13mon on Cloudflare Pages + Workers

This repository replaces the previous infrastructure demo with a Cloudflare Pages site that mirrors the d13mon brand and adds two edge functions:

* **Stripe checkout** via `/api/create-checkout-session` (Workers) for hosted payment pages.
* **SendGrid-powered contact** via `/api/contact` (Workers) to forward messages to your inbox.

Everything runs directly from the repository root – no build tooling required.

## Project layout

```
.
├── app.js                     # Front-end logic for checkout + contact form
├── index.html                 # Landing page content
├── styles.css                 # Styling for the landing page
├── thank-you.html             # Redirect target after successful checkout
├── functions/                 # Cloudflare Pages Functions (Workers)
│   └── api/
│       ├── contact.js         # SendGrid email sender
│       └── create-checkout-session.js  # Stripe Checkout session creator
└── wrangler.toml              # Cloudflare configuration
```

## Running locally with Wrangler

1. Install Wrangler if needed:
   ```bash
   npm install -g wrangler
   ```
2. Start the Pages dev server with functions:
   ```bash
   wrangler pages dev .
   ```
   The dev server proxies `/api/*` to your local Workers runtime.

## Deployment to Cloudflare Pages

1. Create a new **Pages** project and connect this repository.
2. Set **Build command** to `npm run build` (not required) or leave empty; **Build output directory** should be `.` because assets live at the repo root.
3. Add the following **environment variables** to the Pages project (or to `wrangler secret put` when running locally):

   | Variable | Purpose |
   | --- | --- |
   | `STRIPE_SECRET_KEY` | Required. Secret key for the Stripe account. |
   | `STRIPE_PRICE_ID` | Optional default price for checkout buttons. |
   | `STRIPE_SUCCESS_URL` | Optional success redirect (defaults to `/thank-you.html`). |
   | `STRIPE_CANCEL_URL` | Optional cancel redirect (defaults to the page origin). |
   | `SENDGRID_API_KEY` | Required. API key for SendGrid. |
   | `CONTACT_TO_EMAIL` | Required. Destination email address for contact form submissions. |
   | `CONTACT_FROM_EMAIL` | Required. Verified sender address for SendGrid. |

4. Deploy from the Pages dashboard or run:
   ```bash
   wrangler pages deploy .
   ```

## How payments work

* Buttons with `data-price` call `/api/create-checkout-session`.
* The Worker uses the Stripe secret key to create a hosted Checkout session.
* Visitors are redirected to the Stripe URL returned by the API.

## How email works

* The contact form posts JSON `{ name, email, message }` to `/api/contact`.
* The Worker calls SendGrid with `reply_to` set so you can respond directly.

## Customization tips

* Update copy, pricing, and sections in `index.html`.
* Adjust color tokens and layout in `styles.css`.
* Add new API routes under `functions/api/` for more automation (KV, Durable Objects, Turnstile, etc.).

## Security

* Never commit real API keys. Use Pages secrets or `wrangler secret put` locally.
* The Workers endpoints are CORS-permissive for simplicity; consider restricting `Access-Control-Allow-Origin` to your domain in production.
