# VerbaPrep — Architecture (working title; rename TBD)

Evolution of the WordExport Android app into a commercial SAT verbal-prep
product: capture vocab in the wild → review it with spaced repetition → get
tested on it in real SAT Reading & Writing format → track a projected score.
The unifying hook: **your captured words become personalized Words-in-Context
SAT questions** — nobody else does that.

## Stack (decided)

- **Client: Flutter** (one Dart codebase → Android, iOS later, optional web).
  Thin native shims for OS-specific text capture (Android `PROCESS_TEXT`
  activity; iOS Share/Action Extension — note iOS has no toolbar injection, so
  capture is select→Share→VerbaPrep, one extra tap).
- **Backend: Supabase** (Postgres + Auth + Row-Level Security + Realtime).
  Auth providers: Google, Apple (mandatory on iOS once any social login exists),
  email. Schema in `supabase/migrations/0001_init.sql`.
- **Offline:** local cache (Drift/SQLite) syncing to Supabase; capture must work
  offline and flush when online.
- **Daily coach:** a cloud routine (same pattern as the existing
  `sat-math-coach`) that generates + verifies SAT R&W questions and inserts them
  into `sat_questions`. See `question-generation.md`.
- **Legacy:** "Export to Google Sheets" survives as an *optional* export, not the
  store of record (alongside CSV / Anki `.apkg` / PDF).

## The three feature pillars

1. **Vocabulary store + list** (backend vertical slice): auth, `words` table,
   capture writes to Supabase instead of Sheets, list screen with sort options
   (A–Z, Z–A, most recent, oldest, due, most/least reviewed, by mastery, by POS,
   by source, by tag, random, starred) + search/filter.
2. **SRS review:** SM-2 flashcards over `words` (fields already in schema), quiz
   modes (word→def, def→word, fill-the-blank-in-original-context, type-the-word),
   streaks, "due today."
3. **SAT R&W engine:** Elo-per-skill adaptive selection (`skill_mastery`),
   per-skill + per-grammar-rule practice, a module-adaptive full mock (2×27),
   projected R&W score, combined with math for a 1600 estimate. Content accuracy
   per `sat-rw-spec.md` + `grammar-rules.md`.

## Data model (see migration for detail)

`profiles` · `words` (+SM-2) · `review_log` · `sat_questions` (shared bank;
vocab-derived WIC items are user-owned) · `sat_attempts` · `skill_mastery` (Elo).

## Adaptive engine notes (from research)

- SAT R&W is **two-stage block-adaptive**, not item-by-item. Model: a mixed
  Module 1, then route to hard/easy Module 2 as a block. Reaching 790–800
  requires the **hard** Module 2 + ~0–2 misses → weight Module-1 accuracy heavily.
- For daily practice (not the mock), use live one-at-a-time Elo selection like
  the math app, targeting items slightly above current rating per skill.

## Toolchain status (2026-06-24)

- arm64 Mac. Android SDK at `/opt/homebrew/share/android-commandlinetools`,
  JDK 17 at `/opt/homebrew/opt/openjdk@17`. Node v22.
- **Flutter/Dart NOT installed. Supabase CLI NOT installed. No Xcode.**
- **BLOCKER: disk 99% full (~3.3 GB free).** Must free ~6 GB before installing
  the Flutter SDK (+ precache + Android build cache). See roadmap Phase 0.

## Open product decisions

- **Name** (WordExport is too narrow). Candidates: VerbaPrep, Lexly, WordVault.
- **Relationship to `sat-math-prep`:** separate app, or merge into one
  "SAT 1600" app sharing the engine + a combined score dashboard? (Recommend
  eventual merge; build verbal first.)
- **Monetization:** freemium (free capture + basic list; premium = SRS, unlimited
  words, full mocks, AI explanations, audio).
- **Compliance:** COPPA (under-13) / FERPA (schools) — design age gate early.
