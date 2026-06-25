# SAT R&W Question Generation — Coach Spec

How the daily coach (a cloud routine, like `sat-math-coach`) produces
SAT-accurate items into `sat_questions`. Generation MUST follow `sat-rw-spec.md`
and `grammar-rules.md`. **Target student: 790–800**, so accuracy and trap quality
matter more than volume.

## Hard constraints (reject any item that violates these)
- Exactly **4 choices**; one unambiguously correct answer.
- Passage **25–150 words** (a CTC pair shares that budget).
- Single best answer is **textually supported** — no outside knowledge required.
- `skill_code` is one of the 11; `difficulty` 1–5; `rule_code` set for BND/FSS.
- `explanation` states why the answer is right AND why **each** distractor is wrong.
- No real copyrighted passages — original text only.

## Self-verification loop (before insert, set `verified=true` only if all pass)
1. **Single-answer check:** an independent pass must pick the same answer with no
   second defensible choice. If two choices are defensible → discard.
2. **Trap audit:** distractors embody the spec's trap families for that type
   (e.g. WIC: right-meaning/wrong-connotation; RHS: true-but-irrelevant; TRN:
   copycats; BND: comma splice / semicolon=period both-wrong).
3. **Spec-fit:** stem wording matches the canonical stem; format matches (CTC has
   Text 1/Text 2; RHS uses bulleted notes; INF ends in a blank; COE_Q has a
   table/graph in `graphic`).
4. **Difficulty calibration:** hard items (4–5) use the high-scorer traps
   (half-right, true-but-unsupported); easy items (1–2) have clean context.

## Per-type generation recipes (most generatable first)
- **BND / FSS (grammar):** pick a `rule_code` from `grammar-rules.md`, write a
  1-sentence-ish passage with a blank, make the 4 choices differ only along that
  rule, distractors = the named error (splice, mismatched supplement, wrong
  agreement, etc.). The "no comma" / shortest-correct option should sometimes be
  the answer — don't bias against it.
- **TRN:** write two sentences with a clear logical relation; answer = correct
  bucket word; include a **copycat** distractor (same-category word) and a
  "sounds-right" wrong-direction word. Sentence 2 controls the relation.
- **RHS:** write 4–6 bulleted notes + a one-line **goal**; make all 4 choices
  true & drawn from notes; only one achieves the goal; include a partial-fulfill
  and a wrong-direction distractor.
- **WIC:** Statement→Restatement passage with a blank; for hard items make all 4
  valid dictionary definitions so only context disambiguates; vocab from the
  high-utility academic band (see spec). **Also generate from user vocab** — see
  pipeline below.
- **CID / TSP / INF / COE_T / COE_Q / CTC:** original short passage; for COE_Q
  put the table/bar/line data in `graphic` (no calculation needed); CTC needs a
  paired Text 1 / Text 2 differing in point of view.

## Vocab → Words-in-Context pipeline (the product differentiator)
For each captured `words` row (or a batch), generate an `owner_id`-scoped WIC
item: an original 25–150w Statement→Restatement passage whose blank is best
filled by that word, with 3 distractors that are plausible-but-imprecise
(wrong connotation / secondary meaning / topic-fit-only). Tag `source='coach'`,
`skill_code='WIC'`, `owner_id=<user>`. This lets a student practice their own
captured words in real SAT format.

## Scoring / projection
No official raw→scaled table exists. Estimate R&W from per-skill Elo + recent
accuracy, calibrated against multiple Bluebook practice forms; present as an
estimate. Reaching 790–800 in the model requires hard-Module-2-level items
answered with ~0–2 misses.
