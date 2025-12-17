const statusEl = document.getElementById('contactStatus');
const form = document.getElementById('contactForm');
const paymentButton = document.getElementById('paymentButton');
const pricingPayment = document.getElementById('pricingPayment');

function setStatus(message, tone = 'muted') {
  if (!statusEl) return;
  statusEl.textContent = message;
  statusEl.dataset.tone = tone;
}

async function startCheckout(priceId) {
  const button = document.querySelector(`[data-price="${priceId}"]`);
  if (button) {
    button.disabled = true;
    button.textContent = 'Opening checkout…';
  }

  try {
    const res = await fetch('/api/create-checkout-session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ priceId }),
    });

    if (!res.ok) {
      const error = await res.json().catch(() => ({}));
      throw new Error(error.error || 'Unable to start checkout.');
    }

    const data = await res.json();
    if (data.url) {
      window.location.href = data.url;
    } else {
      throw new Error('Checkout URL missing.');
    }
  } catch (err) {
    alert(err.message);
  } finally {
    if (button) {
      button.disabled = false;
      button.textContent = button.id === 'pricingPayment' ? 'Start checkout' : 'Launch secure checkout';
    }
  }
}

if (paymentButton) {
  paymentButton.addEventListener('click', () => {
    startCheckout(paymentButton.dataset.price);
  });
}

if (pricingPayment) {
  pricingPayment.addEventListener('click', () => {
    startCheckout(pricingPayment.dataset.price);
  });
}

if (form) {
  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    setStatus('Sending…');

    const formData = new FormData(form);
    const body = {
      name: formData.get('name'),
      email: formData.get('email'),
      message: formData.get('message'),
    };

    try {
      const res = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!res.ok) {
        const error = await res.json().catch(() => ({}));
        throw new Error(error.error || 'Unable to send message.');
      }

      setStatus('Message sent. Check your inbox for a reply.', 'success');
      form.reset();
    } catch (err) {
      setStatus(err.message, 'error');
    }
  });
}
