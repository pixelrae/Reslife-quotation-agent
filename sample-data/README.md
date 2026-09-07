# Sample data

- `seed-quotes.sql` — realistic seed data for the new database, based on
  actual quotes the original prototype generated (`RES-26-002`), plus one
  extra example (`RES-26-014`) that walks through the custom-item pricing
  path the old prototype couldn't handle.
- `prototype-example-output-RES-26-002.pdf` — the real PDF the original
  Botpress + Make.com + AutoCrat pipeline produced, kept here as a
  before/after reference against `frontend/quote-template.html`.

Load the seed data after the schema:

```bash
psql reslife_quotes -f database/schema.sql
psql reslife_quotes -f sample-data/seed-quotes.sql
```
