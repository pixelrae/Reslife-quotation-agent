# ResLife Foods — AI Quotation Agent

An AI-assisted quoting system built for **ResLife Foods**, a student catering
business at the University of the Western Cape. A customer describes an
order, the system prices it instantly against a live catalogue, and if
something's not in the catalogue yet, it's estimated on the spot and
confirmed by the manager — growing the catalogue automatically instead of
requiring someone to maintain it by hand.

This is a rebuild of an earlier prototype (Botpress + Make.com + Google
Sheets + AutoCrat), started as a university systems-design project (IFS 317)
and continued here as a real, deployable piece of software.

> 📄 See [`docs/architecture.md`](docs/architecture.md) for exactly what
> changed from the original prototype and why.

## The problem this solves

The original prototype could only quote items it already knew about — anything
new stalled the whole order until the owner manually priced and re-typed it.
This version:

- ✅ **Never blocks a customer's quote.** New items get an AI-estimated,
  clearly-labelled placeholder price so the customer gets a response
  immediately.
- ✅ **Grows its own catalogue.** Once a manager confirms a price for a new
  item, it's saved permanently — the next customer who asks for it gets an
  instant, confirmed price.
- ✅ **Keeps a paper trail.** Every AI price estimate and every manager
  override is logged (`custom_item_requests`, `price_history`), so pricing
  decisions are auditable, not a black box.

## Tech stack

| Layer | Tool | Why |
|---|---|---|
| Automation / orchestration | [n8n](https://n8n.io) | Free, self-hostable, visual workflow builder — replaces Make.com |
| Database | PostgreSQL (Firebase documented as an alternative) | Real relational integrity for quotes/pricing data |
| AI price estimation | LLM API call (Claude/GPT) | Estimates a fair market price for items outside the catalogue |
| PDF generation | Gotenberg (headless Chromium) | Replaces the slow, fragile AutoCrat mail-merge |
| Frontend | Plain HTML/CSS/JS | No build step, free to host on GitHub Pages |
| Hosting | GitHub Pages (frontend) + any Docker host (n8n/Postgres) | Free tier covers the whole demo |

## Project structure

```
reslife-quotation-agent/
├── database/            # SQL schema + Firebase alternative + ERD
│   ├── schema.sql
│   └── README.md
├── n8n-workflows/        # The automation logic, importable into n8n
│   ├── 1-new-quote-request.json
│   ├── 2-manager-price-approval.json
│   └── README.md
├── frontend/             # Customer form, manager review page, PDF template
│   ├── index.html / styles.css / script.js
│   ├── manager-review.html
│   ├── quote-template.html
│   └── README.md
├── docs/
│   ├── architecture.md   # System diagram + the custom-item pricing flow explained
│   └── roadmap.md
└── sample-data/
    └── seed-quotes.sql   # Realistic seed data based on real prototype quotes
```

## Quick start

```bash
# 1. Database
createdb reslife_quotes
psql reslife_quotes -f database/schema.sql
psql reslife_quotes -f sample-data/seed-quotes.sql

# 2. n8n (Docker)
docker run -it --rm --name n8n -p 5678:5678 \
  -e ANTHROPIC_API_KEY=sk-... \
  -v ~/.n8n:/home/node/.n8n docker.n8n.io/n8nio/n8n
# then import both files from /n8n-workflows in the n8n UI

# 3. Frontend
cd frontend && python3 -m http.server 8000
# visit http://localhost:8000
```

Full setup detail is in each folder's own README.

## Origin

Built for IFS 317 (Information Systems), extending the Discovery & Scope
(Envision Phase) individual assignment's finding that the original MVP's
biggest technical gap was the lack of a persistent product/pricing database —
see `docs/architecture.md` for how each piece of that gap was addressed.

## License

MIT — see [`LICENSE`](LICENSE).
