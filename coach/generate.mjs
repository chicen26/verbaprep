// VerbaPrep daily SAT Reading & Writing question coach.
//
// Generates a batch of original, spec-accurate SAT R&W questions across all 11
// skill types using Claude, runs a self-verification pass, and inserts the
// survivors into the shared `sat_questions` bank in Supabase (service role).
//
// Runs as a scheduled GitHub Action (see ../.github/workflows/coach.yml).
// Required env: ANTHROPIC_API_KEY, SUPABASE_SERVICE_ROLE_KEY.
// Optional env: SUPABASE_URL (defaults below), COACH_BATCH (questions per run).

import Anthropic from '@anthropic-ai/sdk';

const SUPABASE_URL =
  process.env.SUPABASE_URL || 'https://gnhxawfzklblrzoyqmbo.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BATCH = parseInt(process.env.COACH_BATCH || '12', 10);
const MODEL = 'claude-opus-4-8';

if (!process.env.ANTHROPIC_API_KEY) throw new Error('ANTHROPIC_API_KEY missing');
if (!SERVICE_KEY) throw new Error('SUPABASE_SERVICE_ROLE_KEY missing');

const client = new Anthropic();

// ── The spec the model must follow (condensed from docs/sat-rw-spec.md) ──────
const SPEC = `You write ORIGINAL practice questions for the digital SAT Reading & Writing
section, calibrated to help a student reach 790-800. Follow these rules exactly.

The 11 skill types (skill_code):
- WIC Words in Context — Statement→Restatement passage with a blank; for hard
  items make all 4 choices valid dictionary words so only context disambiguates;
  high-utility academic vocabulary.
- TSP Text Structure & Purpose — identify rhetorical purpose or structure (not main idea).
- CTC Cross-Text Connections — TWO passages (set passage2); about how one author
  views the other; distractors too-extreme or swapped viewpoints.
- CID Central Ideas & Details — main idea or specific detail; kill choices with one wrong word.
- COE_T Command of Evidence (Textual) — pick finding/quote that supports a claim;
  distractors true but wrong variable.
- COE_Q Command of Evidence (Quantitative) — include a small data table in "graphic"
  as {"title":..,"columns":[..],"rows":[[..]]}; pick the data that supports the claim.
- INF Inferences — passage ends in a blank; stem "Which choice most logically
  completes the text?"; answer must be supported, not a leap.
- BND Boundaries — punctuation/sentence structure; exactly one correct choice;
  set rule_code (e.g. BND.splice, BND.colon, BND.supplement, BND.comma_misuse).
- FSS Form, Structure & Sense — agreement/verbs/modifiers/possessives; set rule_code
  (e.g. FSS.sva_intervening, FSS.pronoun_number, FSS.dangling, FSS.parallel).
- TRN Transitions — stem "Which choice completes the text with the most logical
  transition?"; include a copycat distractor (same category as a wrong one).
- RHS Rhetorical Synthesis — stimulus is bulleted student notes (stimulus_kind
  "notes") + a stated goal; make all 4 choices true & from the notes; only one meets the goal.

Hard constraints:
- Exactly 4 choices; exactly one unambiguously correct answer (0-based index).
- Passage 25-150 words. Original text only — never copy real passages.
- "explanation" must say why the answer is right AND why each distractor is wrong.
- difficulty 1-5. stimulus_kind is "passage", "notes", or "graph".
- Generate hard items (4-5) using high-scorer traps: half-right answers,
  true-but-unsupported, extreme language.`;

const QUESTION_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    questions: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          skill_code: {
            type: 'string',
            enum: ['WIC', 'TSP', 'CTC', 'CID', 'COE_T', 'COE_Q', 'INF', 'BND', 'FSS', 'TRN', 'RHS'],
          },
          rule_code: { type: ['string', 'null'] },
          difficulty: { type: 'integer', enum: [1, 2, 3, 4, 5] },
          passage: { type: 'string' },
          passage2: { type: ['string', 'null'] },
          stimulus_kind: { type: 'string', enum: ['passage', 'notes', 'graph'] },
          graphic: { type: ['object', 'null'] },
          stem: { type: 'string' },
          choices: { type: 'array', items: { type: 'string' } },
          answer: { type: 'integer', enum: [0, 1, 2, 3] },
          explanation: { type: 'string' },
        },
        required: [
          'skill_code', 'rule_code', 'difficulty', 'passage', 'passage2',
          'stimulus_kind', 'graphic', 'stem', 'choices', 'answer', 'explanation',
        ],
      },
    },
  },
  required: ['questions'],
};

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          index: { type: 'integer' },
          ok: { type: 'boolean' },
          issue: { type: ['string', 'null'] },
        },
        required: ['index', 'ok', 'issue'],
      },
    },
  },
  required: ['verdicts'],
};

function textOf(message) {
  const block = message.content.find((b) => b.type === 'text');
  return block ? block.text : '';
}

async function generate() {
  const msg = await client.messages.create({
    model: MODEL,
    max_tokens: 16000,
    thinking: { type: 'adaptive' },
    output_config: { format: { type: 'json_schema', schema: QUESTION_SCHEMA } },
    system: SPEC,
    messages: [
      {
        role: 'user',
        content:
          `Generate ${BATCH} original SAT R&W questions. Cover a spread of the 11 ` +
          `skill types (weight Words in Context, Transitions, Rhetorical Synthesis, ` +
          `Boundaries, and Form/Structure/Sense a bit more, but include at least one ` +
          `each of Cross-Text and Quantitative Evidence). Vary difficulty 1-5.`,
      },
    ],
  });
  return JSON.parse(textOf(msg)).questions;
}

// Independent verification: an item survives only if a second pass agrees there
// is exactly one defensible answer and the format matches its skill type.
async function verify(questions) {
  const msg = await client.messages.create({
    model: MODEL,
    max_tokens: 8000,
    thinking: { type: 'adaptive' },
    output_config: { format: { type: 'json_schema', schema: VERDICT_SCHEMA } },
    system:
      'You are a strict SAT item reviewer. For each question, mark ok=true ONLY if: ' +
      'the labeled answer is the single best answer with no second defensible choice; ' +
      'there are exactly 4 choices; and the format fits its skill_code (CTC has two ' +
      'texts, RHS uses bulleted notes + a goal, INF ends in a blank, COE_Q has a graphic). ' +
      'Otherwise ok=false with a one-line issue.',
    messages: [
      { role: 'user', content: 'Review these questions:\n' + JSON.stringify(questions) },
    ],
  });
  return JSON.parse(textOf(msg)).verdicts;
}

async function insert(rows) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/sat_questions`, {
    method: 'POST',
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify(rows),
  });
  if (!res.ok) throw new Error(`Insert failed ${res.status}: ${await res.text()}`);
}

async function main() {
  console.log(`Generating ${BATCH} questions with ${MODEL}…`);
  const questions = await generate();
  console.log(`Generated ${questions.length}. Verifying…`);

  const verdicts = await verify(questions);
  const okIdx = new Set(verdicts.filter((v) => v.ok).map((v) => v.index));
  verdicts.filter((v) => !v.ok).forEach((v) => console.log(`  reject #${v.index}: ${v.issue}`));

  const rows = questions
    .filter((_, i) => okIdx.has(i))
    .filter((q) => Array.isArray(q.choices) && q.choices.length === 4)
    .map((q) => ({
      skill_code: q.skill_code,
      rule_code: q.rule_code,
      difficulty: q.difficulty,
      passage: q.passage,
      passage2: q.passage2,
      stimulus_kind: q.stimulus_kind,
      graphic: q.graphic,
      stem: q.stem,
      choices: q.choices,
      answer: q.answer,
      explanation: q.explanation,
      source: 'coach',
      verified: true,
    }));

  if (rows.length === 0) {
    console.log('Nothing passed verification this run.');
    return;
  }
  await insert(rows);
  console.log(`Inserted ${rows.length} verified questions into the bank. ✅`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
