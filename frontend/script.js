// ResLife Foods — quote request form logic
// No frameworks: this is a small enough form that plain JS keeps the
// project easy to host anywhere (GitHub Pages, Netlify, a plain static host).

const itemRows = document.getElementById('itemRows');
const addItemBtn = document.getElementById('addItemBtn');
const form = document.getElementById('quoteForm');
const statusEl = document.getElementById('formStatus');

addItemBtn.addEventListener('click', () => {
  const row = document.createElement('div');
  row.className = 'item-row';
  row.innerHTML = `
    <input type="text" class="item-name" placeholder="Item name" required>
    <input type="number" class="item-qty" placeholder="Qty" min="1" value="1" required>
  `;
  itemRows.appendChild(row);
});

function collectItems() {
  const names = itemRows.querySelectorAll('.item-name');
  const qtys = itemRows.querySelectorAll('.item-qty');
  const items = [];
  names.forEach((nameInput, i) => {
    const name = nameInput.value.trim();
    const quantity = Number(qtys[i].value);
    if (name && quantity > 0) items.push({ name, quantity });
  });
  return items;
}

function setStatus(message, kind) {
  statusEl.textContent = message;
  statusEl.className = 'form-status' + (kind ? ` form-status--${kind}` : '');
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const data = new FormData(form);
  const items = collectItems();

  if (items.length === 0) {
    setStatus('Add at least one item to your order.', 'err');
    return;
  }

  const payload = {
    customer: {
      fullName: data.get('fullName'),
      email: data.get('email'),
      phone: data.get('phone'),
      companyName: data.get('companyName'),
      billingAddress: ''
    },
    event: {
      date: data.get('eventDate'),
      time: data.get('eventTime'),
      deliveryLocation: data.get('deliveryLocation'),
      deliveryMethod: 'N/A'
    },
    items
  };

  const submitBtn = form.querySelector('button[type="submit"]');
  submitBtn.disabled = true;
  setStatus('Sending your request…');

  try {
    const response = await fetch(RESLIFE_CONFIG.QUOTE_WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (!response.ok) throw new Error(`Server responded ${response.status}`);
    const result = await response.json();

    if (result.status === 'pending_review') {
      setStatus(
        `Quote ${result.quoteNumber} sent to your email — estimated total R${result.estimatedTotal}. ` +
        `Some items are new to us, so our team will confirm final pricing shortly.`,
        'ok'
      );
    } else {
      setStatus(
        `Quote ${result.quoteNumber} sent to your email — total R${result.estimatedTotal}.`,
        'ok'
      );
    }
    form.reset();
  } catch (err) {
    console.error(err);
    setStatus('Something went wrong sending your request. Please try again or WhatsApp us directly.', 'err');
  } finally {
    submitBtn.disabled = false;
  }
});
