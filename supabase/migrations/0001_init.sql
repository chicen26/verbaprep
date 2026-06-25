-- VerbaPrep initial schema
-- Supabase (Postgres). Run via the Supabase SQL editor or `supabase db push`.
-- Design: each user owns their words, attempts, mastery, and reviews (enforced
-- by Row-Level Security). The SAT question bank is shared/read-only to clients;
-- only the service role (the daily coach) inserts into it. Words-in-Context
-- items generated from a user's own vocab are user-owned.

-- ─────────────────────────────────────────────────────────────────────────────
-- Extensions
create extension if not exists "pgcrypto";   -- gen_random_uuid()

-- ─────────────────────────────────────────────────────────────────────────────
-- profiles: 1:1 with auth.users, holds app-level prefs + the SAT target
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text,
  sat_target    int  default 800 check (sat_target between 200 and 800),
  test_date     date,                         -- e.g. Sept 2026 sitting
  created_at    timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- words: the vocabulary capture + spaced-repetition state (SM-2)
create table public.words (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  word           text not null,
  definition     text,
  part_of_speech text,
  example        text,                         -- enriched example sentence
  context        text,                         -- the sentence it was captured in
  source_app     text,                         -- e.g. "Chrome", "Kindle"
  tags           text[] not null default '{}',
  starred        boolean not null default false,
  -- SM-2 spaced repetition fields
  ease           real    not null default 2.5, -- ease factor
  interval_days  int     not null default 0,
  repetitions    int     not null default 0,
  due_at         timestamptz not null default now(),
  review_count   int     not null default 0,
  -- SAT relevance
  is_sat_relevant boolean default false,
  difficulty      int,                         -- 1..5 CEFR-ish, nullable
  created_at     timestamptz not null default now(),
  unique (user_id, word)
);
create index words_user_due_idx on public.words (user_id, due_at);
create index words_user_created_idx on public.words (user_id, created_at desc);

-- ─────────────────────────────────────────────────────────────────────────────
-- review_log: one row per flashcard review (for analytics + streaks)
create table public.review_log (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  word_id     uuid not null references public.words(id) on delete cascade,
  grade       int  not null check (grade between 0 and 5), -- SM-2 quality
  reviewed_at timestamptz not null default now()
);
create index review_log_user_idx on public.review_log (user_id, reviewed_at desc);

-- ─────────────────────────────────────────────────────────────────────────────
-- sat_questions: shared question bank (read-only to clients).
-- skill_code ∈ WIC,TSP,CTC,CID,COE_T,COE_Q,INF,BND,FSS,TRN,RHS  (see sat-rw-spec.md)
-- rule_code  ∈ grammar-rules.md codes, only for BND/FSS items (nullable otherwise)
create table public.sat_questions (
  id           uuid primary key default gen_random_uuid(),
  skill_code   text not null,
  rule_code    text,
  difficulty   int  not null check (difficulty between 1 and 5),
  -- content
  passage      text not null,
  passage2     text,                           -- only for Cross-Text (CTC)
  stimulus_kind text not null default 'passage', -- 'passage' | 'notes' | 'graph'
  graphic      jsonb,                           -- table/bar/line data for COE_Q
  stem         text not null,
  choices      jsonb not null,                  -- ["A text","B text","C","D"]
  answer       int  not null check (answer between 0 and 3),
  explanation  text not null,                   -- why right + why each distractor wrong
  -- provenance / QA
  source       text,                            -- 'coach' | 'official' | 'manual'
  owner_id     uuid references auth.users(id) on delete cascade, -- set for vocab-derived WIC
  verified     boolean not null default false,
  created_at   timestamptz not null default now()
);
create index sat_questions_skill_diff_idx on public.sat_questions (skill_code, difficulty);

-- ─────────────────────────────────────────────────────────────────────────────
-- sat_attempts: every question a user answers
create table public.sat_attempts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  question_id  uuid not null references public.sat_questions(id) on delete cascade,
  chosen       int  not null check (chosen between 0 and 3),
  correct      boolean not null,
  ms_taken     int,
  module_no    int,                             -- 1 or 2 if part of a mock
  mock_id      uuid,                            -- groups a full-test sitting
  answered_at  timestamptz not null default now()
);
create index sat_attempts_user_idx on public.sat_attempts (user_id, answered_at desc);

-- ─────────────────────────────────────────────────────────────────────────────
-- skill_mastery: Elo per skill (and optionally per grammar rule) per user
create table public.skill_mastery (
  user_id     uuid not null references auth.users(id) on delete cascade,
  skill_code  text not null,
  rating      real not null default 1200,      -- Elo
  attempts    int  not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (user_id, skill_code)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Row-Level Security
alter table public.profiles      enable row level security;
alter table public.words         enable row level security;
alter table public.review_log    enable row level security;
alter table public.sat_attempts  enable row level security;
alter table public.skill_mastery enable row level security;
alter table public.sat_questions enable row level security;

-- owner-only policies (one helper pattern repeated)
create policy "own profile"      on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "own words"        on public.words
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own reviews"      on public.review_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own attempts"     on public.sat_attempts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own mastery"      on public.skill_mastery
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- sat_questions: anyone signed in can read shared (owner_id is null) or their own
-- vocab-derived items; no client writes (service role bypasses RLS).
create policy "read shared or own questions" on public.sat_questions
  for select using (owner_id is null or owner_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- Auto-create a profile row when a user signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.email));
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
