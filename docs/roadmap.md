# Roadmap

Rough order of what to build next, grouped by what it unlocks.

## Now (get it running end to end)
- [ ] Stand up Postgres locally and run `database/schema.sql`
- [ ] Import both n8n workflows, wire up Postgres + SMTP credentials
- [ ] Set `ANTHROPIC_API_KEY` (or `OPENAI_API_KEY`) as an n8n environment variable
- [ ] Stand up a PDF service (Gotenberg via Docker is the fastest path) and point the `Generate PDF Quote` node at it
- [ ] Update `frontend/config.js` with the local n8n webhook URLs and test a full order

## Next (make it demoable / deployable)
- [ ] Deploy the frontend to GitHub Pages
- [ ] Deploy n8n somewhere reachable from the internet (Railway free tier, a small VPS, or n8n.cloud)
- [ ] Add basic auth to `manager-review.html` before sharing the link with anyone
- [ ] Replace the hardcoded `demoQueue` in `manager-review.html` with a real "list pending items" n8n endpoint

## Later (production-quality)
- [ ] Swap the token-overlap item matcher for a proper fuzzy-match library or embedding similarity
- [ ] Add a threshold so AI estimates above a certain rand value always require manager approval before the quote is sent, not just flagged
- [ ] WhatsApp Business API integration alongside email
- [ ] A simple owner dashboard: quotes this month, average estimate accuracy (AI estimate vs manager-approved price), most-requested custom items
- [ ] Move secrets out of `.env`/n8n UI and into a proper secrets manager if this becomes a real paid product
