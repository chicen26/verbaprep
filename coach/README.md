# VerbaPrep — Daily Question Coach

A scheduled job that grows the SAT Reading & Writing bank automatically. Each run
generates a batch of original questions across all 11 R&W skill types with Claude
(`claude-opus-4-8`), runs a second-pass verification, and inserts the survivors
into the shared `sat_questions` table in Supabase.

It runs as a **GitHub Action on a cron** (`.github/workflows/coach.yml`, daily at
7am PT) — free, no server to run.

## One-time setup

Add three repository secrets in GitHub
(**Settings → Secrets and variables → Actions → New repository secret**):

| Secret | Where to get it |
|---|---|
| `ANTHROPIC_API_KEY` | console.anthropic.com → API keys |
| `SUPABASE_URL` | `https://gnhxawfzklblrzoyqmbo.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Project Settings → API → **service_role** (secret — never ship in the app) |

> The **service role key bypasses Row-Level Security**, which is why generation
> runs server-side in CI and never in the Flutter client.

Then trigger it: **Actions tab → SAT question coach → Run workflow** (or wait for
the daily schedule).

## Run locally

```bash
cd coach
npm install
ANTHROPIC_API_KEY=... \
SUPABASE_SERVICE_ROLE_KEY=... \
COACH_BATCH=12 \
node generate.mjs
```

## How it stays accurate

- The system prompt encodes the spec from `docs/sat-rw-spec.md` (the 11 types,
  formats, and trap patterns).
- Structured outputs force a clean, schema-valid question array.
- A separate verification call marks an item OK only if it has a single
  defensible answer and the right format for its skill type; rejects are logged
  and not inserted.
- Inserted rows are `source='coach'`, `verified=true`, so the app serves them.

## Tuning

- `COACH_BATCH` (env) — questions generated per run (default 12).
- Change the cron in `coach.yml` to run more/less often.
