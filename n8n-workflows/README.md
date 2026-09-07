# n8n Workflows

Replaces the Botpress + Make.com + AutoCrat pipeline with two n8n workflows. n8n is free and self-hostable (Docker) or free-tier hosted at n8n.cloud.

## Setup

```bash
# Run n8n locally with Docker (easiest option)
docker run -it --rm --name n8n -p 5678:5678 -v ~/.n8n:/home/node/.n8n docker.n8n.io/n8nio/n8n
```

Then open `http://localhost:5678`, go to **Workflows → Import from File**, and import each JSON file here.

### Credentials to set up in n8n before running

| Credential name (used in the JSON) | What it's for |
|---|---|
| `ResLife Postgres` | Connection to the database in `/database` |
| `ResLife Email` | SMTP for sending quotes/notifications (Gmail app password works for a student project) |
| `ANTHROPIC_API_KEY` env var | Used by the "AI Estimate Cape Town Price" Code node |

Set the API key as an n8n **environment variable**, not hardcoded in the workflow — in Docker, pass `-e ANTHROPIC_API_KEY=sk-...`.

## Workflow 1 — New Quote Request

**Trigger:** `POST /webhook/quote-request` (called by `/frontend`)

```
Webhook
  → Get Active Menu Items (Postgres)
  → Match Items & Flag Custom          <- fuzzy-matches each ordered item against the catalogue
  → AI Estimate Cape Town Price        <- ONLY for items that didn't match; asks an LLM for a
                                           realistic ZAR price + a one-line reason, used as a
                                           clearly-marked placeholder
  → Upsert Customer
  → Calculate Quote Totals
  → Insert Quote (status = pending_manager_review if any item is custom, else approved)
  → Insert Quote Items
  → Insert Custom Item Requests (only for custom items)
  → IF: Needs Manager Review?
        YES → email manager + respond to customer immediately with an estimated total
        NO  → generate PDF, email customer, log as sent
```

This is the piece that solves the technical problem you ran into: **an unrecognised item never blocks the quote.** It's priced with a placeholder and clearly labelled `estimated_placeholder`, exactly like the "**Final pricing is subject to manager approval**" note already on your prototype's PDF — so the behaviour matches what you'd already designed, it's just now backed by a database instead of hoping AutoCrat's mail-merge lines up.

## Workflow 2 — Manager Price Approval

**Trigger:** `POST /webhook/manager-approve` (called by `/frontend/manager-review.html`)

```
Webhook
  → Get Custom Item Request
  → Update Custom Item Request (status = approved)
  → Upsert Menu Item              <- THE catalogue-growth step: the custom item becomes a normal
                                      priced catalogue item with the manager's markup applied, so
                                      it's auto-matched next time a customer asks for it
  → Log Price History (audit trail)
  → Update Quote Item Price
  → Recalculate Quote Total
  → Any Items Still Pending? → IF all confirmed: generate final PDF, email customer, mark quote sent
```

## Swapping AutoCrat for PDF generation

Two free options, in order of how little setup they need:

1. **Gotenberg** (self-hosted, Docker, converts HTML → PDF) — run alongside n8n:
   ```bash
   docker run -d -p 3000:3000 gotenberg/gotenberg:8
   ```
   Point the `Generate PDF Quote` HTTP Request node at `http://localhost:3000/forms/chromium/convert/html`, feeding it the rendered `frontend/quote-template.html`.
2. A hosted API like **PDFShift** or **api2pdf** — free tier, no server to run, same HTTP Request node just points at their endpoint instead.

Either is far faster and more reliable than a Google AutoCrat mail-merge, and both are one HTTP Request node instead of a separate no-code tool.

## Notes on scope

These JSON files are a **working starting point**, not a finished production system — import them, then:
- fill in the real Postgres/SMTP credentials in n8n's credential manager (never commit real credentials to GitHub — see `.gitignore`)
- swap `YOUR_PDF_SERVICE` and `YOUR_DOMAIN` placeholders for your real endpoints
- test each branch with n8n's built-in execution log before going live
