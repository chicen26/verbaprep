# SAT Reading & Writing — Content Spec

Source of truth for question generation and the adaptive engine. Compiled from
College Board primary docs, Khan Academy (official partner), Princeton Review,
Kaplan, UWorld, Erica Meltzer (*The Critical Reader*), and College Panda.
**Target: 790–800.** See `question-generation.md` for how the coach uses this.

## Section structure (must match exactly)

- **54 questions / 64 minutes**, two modules of **27 questions × 32 min**.
- Each module = **25 scored + 2 unscored pretest**. ~71 sec/question.
- **Module-adaptive (two-stage, block-level):** one routing decision after
  Module 1. Module 1 = mixed difficulty; Module-1 performance routes you into a
  **hard (2B)** or **easy (2A)** Module 2. **The hard Module 2 is the only path
  to a top-band score** — an easy Module 2 caps the section ≈590–630. Rough
  threshold to unlock hard M2: ~18/27 (~70%) of M1 correct.
- Each short passage has **exactly one** question. **4 choices (A–D)**, single
  best answer. No student-produced responses in R&W.
- Passage length **25–150 words** (a Text 1/Text 2 pair shares that budget).
- Graphics only: tables, bar graphs, line graphs (no calc required).
- Rights-only scoring (no guessing penalty).

## Scoring note for the 790–800 target

There is **no official raw→scaled table** (form-specific IRT equating). Strong
prep estimate: **790–800 = reach hard Module 2 AND miss ~0–2 total**; one miss
can mean 780. The curve at the top is brutal (10–20 pts/miss). **Engine
implications:** weight Module-1 accuracy heavily; never coach tanking M1; model
difficulty per item; present any score estimate as an estimate validated across
multiple Bluebook forms, not a fixed conversion.

## Domains, weights, question order

Within a module, types run easiest→hardest in this order (use for sequencing):

| # | Domain (weight) | Question type | Skill code |
|---|---|---|---|
| 1 | Craft & Structure (~28%) | Words in Context | `WIC` |
| 2 | | Text Structure & Purpose | `TSP` |
| 3 | | Cross-Text Connections | `CTC` |
| 4 | Information & Ideas (~26%) | Central Ideas & Details | `CID` |
| 5 | | Command of Evidence — Textual | `COE_T` |
| 6 | | Command of Evidence — Quantitative | `COE_Q` |
| 7 | | Inferences | `INF` |
| 8 | Standard English Conventions (~26%) | Boundaries | `BND` |
| 9 | | Form, Structure, and Sense | `FSS` |
| 10 | Expression of Ideas (~20%) | Transitions | `TRN` |
| 11 | | Rhetorical Synthesis | `RHS` |

Frequency: **WIC is the most common (~1/5 of the section)**; TRN and RHS ~5–6
each; CTC rarest (~1–2). Domain %s vary ±2 per form.

## Per-type generation contract

### WIC — Words in Context (most generatable; ties to user vocab)
- **Stem:** "Which choice completes the text with the most logical and precise
  word or phrase?" or "As used in the text, X most nearly means".
- **Structure:** single 25–150w passage with a blank (or a marked word). Often a
  "Statement → Restatement" pattern (the blank's meaning is restated nearby,
  e.g. after a colon).
- **Distractors:** right-meaning/wrong-connotation; secondary meaning of a
  polysemous word; topic-fit but wrong precise meaning; too strong/weak. **Hard
  items:** all four are valid dictionary definitions — only context disambiguates.
- **Vocab band:** mid-to-advanced *high-utility academic* words (abate,
  corroborate, ostensible, ubiquitous, foil, undermine, supplant, augment,
  coalesce, idiosyncratic, engender). Not obscure old-SAT words.

### TSP — Text Structure & Purpose
- Identify main **purpose** (why: explain/illustrate/criticize/argue) or
  **structure** (how ideas flow), not the main idea. Distractors swap the axis
  the passage uses; the tempting one nails half the structure and misstates the rest.

### CTC — Cross-Text Connections
- **Always two passages: "Text 1" / "Text 2"** on one subject. Always about
  point of view / how one author would respond to the other. Distractors:
  too-extreme views, swapped viewpoints, claims beyond the text.

### CID — Central Ideas & Details
- Main-idea or specific-detail. Distractors: "too narrow," "true but not the
  answer," blanket words (always/all/never), out-of-scope. One wrong word kills a choice.

### COE_T / COE_Q — Command of Evidence
- **Textual:** pick the finding/quotation that supports/weakens a stated claim.
  No outside knowledge. Distractors are true but address a *different variable*.
- **Quantitative:** claim + table/bar/line graph; pick data that matches the
  figure AND supports the claim. Distractors misread the axis/year or are
  accurate but irrelevant to the claim.

### INF — Inferences (top difference-maker)
- **Stem always:** "Which choice most logically completes the text?" Passage
  ends in a blank. Answer must be *supported* by the text, not a leap.
  Distractors: overreach, absolute qualifiers when text says "sometimes," subtle
  focus shifts. Correct answer is usually the most explicit, not a reach.

### BND — Boundaries (punctuation/sentence structure)
- Exactly one grammatically correct choice (not style). Rules in
  `grammar-rules.md` §A. Frequent traps: comma splices, run-ons, semicolon=period
  (both wrong if both appear), mismatched supplement punctuation, the often-correct
  **no-comma** option.

### FSS — Form, Structure, and Sense (usage)
- Khan's five: subject-verb agreement, pronoun-antecedent agreement, verb
  forms/tense, modifier placement, plural & possessive nouns. Rules in
  `grammar-rules.md` §B. Difficulty driver: words inserted between subject and
  verb (cross them out); proximity traps with a nearer mismatched noun.

### TRN — Transitions (formulaic)
- **Stem:** "Which choice completes the text with the most logical transition?"
  Correct answers come from a pool of **~25 words** in 4 buckets:
  contrast / continuation(+addition/example/emphasis) / cause-effect / sequence.
- **Method to encode:** cover choices → name the logical relation in your own
  words → predict → match. **Trap design:** make 3 of 4 "sound right"; include
  **copycats** (two same-category words → both wrong); the controlling signal is
  sentence 2; redundant transition when example already given.

### RHS — Rhetorical Synthesis (formulaic)
- **Stimulus is a bulleted list of student notes** + a stated **goal** + "Which
  choice most effectively uses relevant information from the notes to accomplish
  this goal?"
- **Trap design (key):** make all four true, grammatical, and drawn from the
  notes — **only one achieves the goal.** Families: true-but-irrelevant; partial
  fulfillment (two-part goal, satisfies one); outside info; wrong-direction keyword.

## High-scorer trap taxonomy (weight heavily at high difficulty)
- **Half-right** (#1): mostly correct + one wrong qualifier/direction/reason. The
  *whole* option must be supported — split it at commas/"because"/"which" and
  prove each clause ("no clause left unproven").
- **True-but-not-supported** ("could be true" in the real world, not in passage).
- Extreme/absolute language; recycled passage wording with distorted meaning;
  detail-instead-of-function over-reading.

## Cross-company consensus the SAT rewards
1. Most **concise** among equivalent correct answers (tiebreaker, not a law).
2. **Textual support mandatory** — no outside knowledge.
3. **Predict-then-eliminate** universally.
4. Don't default to "No Change."
5. Punctuation **symmetry** for nonessentials.
6. Hedged/soft language over absolutes in correct reading answers.
7. **Redundancy** is heavily tested (never state the same info twice).
