# VerbaPrep — Build Roadmap

Status legend: ✅ done · 🔜 next · ⬜ later · ⛔ blocked

## Phase 0 — Unblock toolchain ✅
- ✅ Freed disk (cleared caches/CoreSimulator/Downloads clutter → 23 GB free).
- ✅ Installed Flutter 3.44.4 / Dart 3.12.2 (`~/development/flutter`, on PATH).
- ✅ Installed Supabase CLI 2.107.0; Android SDK 36 + build-tools 36.
- ⬜ Create Supabase project (you, in the browser) → get URL + anon key.
- ⬜ Apply `supabase/migrations/0001_init.sql`.

## Phase 1 — Backend vertical slice (pillar 1) 🔜 (code done, needs DB)
- ✅ `flutter create` app shell; added supabase_flutter, flutter_riverpod, intl.
- ✅ Auth screen (email/password; Google/Apple OAuth later) — `lib/screens/auth_screen.dart`.
- ✅ Words data layer (`lib/data/words_repository.dart`) + model (`lib/models/word.dart`).
- ✅ Word-list screen with all 8 sorts + search + add + star + delete — `lib/screens/word_list_screen.dart`.
- ✅ Config guard (`lib/config.dart`); app compiles + `flutter build web` passes.
- ⬜ **Wire live DB** (needs your Supabase URL + anon key), then run on web/device.
- ⬜ Offline cache + sync (Drift).
- ⬜ Port Android `PROCESS_TEXT` capture as a native shim feeding the Flutter app.

## Phase 2 — SRS review (pillar 2) ⬜
- ⬜ SM-2 scheduler over `words` (fields already in schema).
- ⬜ Review screen + grade buttons; write `review_log`.
- ⬜ Quiz modes (word↔def, fill-blank-in-context, type-the-word).
- ⬜ Streaks, "due today," daily goal, push reminder.
- ⬜ Auto-enrich on capture: example sentence, synonyms, POS, audio (TTS),
  SAT-relevance flag.

## Phase 3 — SAT R&W engine (pillar 3) ⬜
- ⬜ Elo-per-skill selection (`skill_mastery`); reuse math-app engine ideas.
- ⬜ Practice by skill + by grammar rule (generatable types first: BND, FSS,
  TRN, RHS, WIC).
- ⬜ **Daily R&W coach** cloud routine (clone of `sat-math-coach`) generating +
  self-verifying questions per `question-generation.md` into `sat_questions`.
- ⬜ Vocab→WIC pipeline: turn each captured word into a Words-in-Context item.
- ⬜ Module-adaptive full mock (2×27, 64 min) + projected R&W score.
- ⬜ Combined 1600 estimate (with math app).

## Phase 4 — Commercial ⬜
- ⬜ Freemium gating, AI explanations, dashboard/analytics, leaderboards.
- ⬜ COPPA/FERPA age gate + privacy policy.
- ⬜ iOS build (Xcode, Apple Developer acct, Share Extension capture).
- ⬜ Store listings (Play + App Store).

## What's already done ✅
- ✅ SAT R&W content spec (`sat-rw-spec.md`) + full grammar rule set
  (`grammar-rules.md`), researched from College Board/Khan/Princeton/Kaplan/
  UWorld/Meltzer/College Panda.
- ✅ Supabase schema with RLS (`supabase/migrations/0001_init.sql`).
- ✅ Architecture + this roadmap.

## Immediate next action
Free disk space → then I install Flutter + Supabase CLI and scaffold Phase 1.
You separately: create the Supabase project and paste me the URL + anon key.
