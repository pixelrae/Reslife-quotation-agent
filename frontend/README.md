# Frontend

Plain HTML/CSS/JS — no build step, no framework — so it can be hosted anywhere for free.

| File | Purpose |
|---|---|
| `index.html` / `styles.css` / `script.js` | The customer-facing quote request form |
| `manager-review.html` | Where the manager confirms AI-estimated prices for new items |
| `quote-template.html` | The HTML template the PDF service renders into the final quote PDF |
| `config.js` | The only file you need to edit before deploying — points at your n8n webhook URLs |

## Run it locally

Just open `index.html` in a browser, or serve it so `fetch()` calls work cleanly:

```bash
cd frontend
python3 -m http.server 8000
# visit http://localhost:8000
```

Make sure n8n is running (see `/n8n-workflows/README.md`) and `config.js` points at it.

## Deploy for free — GitHub Pages

A quick reality check before you go looking for a free custom domain: **Freenom (the old free `.tk`/`.ml` domain service) shut down in 2024** after a Meta lawsuit, so that route no longer exists. The genuinely free, permanent option today is a subdomain from GitHub Pages, Netlify, or Vercel. A real custom domain (`reslifefoods.co.za` or similar) typically costs a few dollars a year from a normal registrar — worth it later if this becomes a real product, not needed for the university project or your portfolio.

To publish this site for free on GitHub Pages:

```bash
# from the repo root
git add .
git commit -m "Add frontend"
git push origin main
```

Then in your GitHub repo: **Settings → Pages → Source → Deploy from a branch → main → /frontend**.

Your site will be live at:
```
https://<your-github-username>.github.io/reslife-quotation-agent/
```

That URL is exactly what you'd put in an email or WhatsApp message to a client — free forever, no renewal, and it doubles as evidence of a deployed project for your portfolio/CV.

## Before you send this to a real client

- Update `config.js` with your **deployed** n8n webhook URL (not `localhost`) — n8n needs to be hosted somewhere reachable from the internet, e.g. a small VPS, Railway, or n8n.cloud's free trial.
- `manager-review.html` currently uses a hardcoded demo list (`demoQueue`) for simplicity. Wire it up to a real "list pending reviews" endpoint in n8n (a Postgres `SELECT` behind a webhook) before using it day-to-day, and add a login step — right now anyone with the link could approve prices.
