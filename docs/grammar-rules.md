# SAT Standard English Conventions — Complete Rule Set

The most generatable question bank. Each rule is a generation template: produce a
passage with a blank, make the answer choices differ only along that rule, and
write distractors that embody the named error. Tag every generated item with its
rule code so the engine can track per-rule mastery.

## §A. BOUNDARIES (`BND`) — punctuation & sentence structure

- `BND.splice` **Comma splices & run-ons.** Two independent clauses can't be
  joined by a comma alone or by nothing. A conjunctive adverb (however,
  therefore) is NOT a conjunction. Legal fixes: period; comma+FANBOYS;
  semicolon; make one clause dependent. *Wrong: He was hungry, he bought a
  burrito. / …, therefore he bought… Right: …, so he bought… / …; he bought…*
- `BND.semi_period` **Periods = semicolons.** Both join two independent clauses;
  the SAT never makes you choose between them → if both appear, both are wrong.
- `BND.colon` **Colons** follow a **complete sentence**, introduce a
  list/explanation. *Wrong: Three things that matter are: … Right: Three things
  matter: time, effort, dedication.*
- `BND.dash` **Dashes.** Single dash = colon (after a complete clause). A
  **pair** of dashes = a pair of commas/parentheses around nonessential info.
- `BND.fanboys` **Comma + FANBOYS** (for/and/nor/but/or/yet/so) joins two
  independent clauses.
- `BND.dependent` **Dependent + independent.** Leading dependent clause
  (although/because/when/while/since/if) takes a comma; needs no conjunction.
- `BND.supplement` **Supplements.** Removable info uses a **matched pair** (two
  commas, two dashes, or two parentheses) — never mixed, never a single comma
  before an appositive. Essential info gets **no** punctuation.
- `BND.which_that` *That* = essential, no comma. *Which* = nonessential, comma.
  *Who(m)* for people.
- `BND.names` Names/titles: no commas (essential) OR two commas (nonessential),
  never one.
- `BND.comma_misuse` **No comma** between subject and verb, before/after a
  preposition, around *that*, between two verbs sharing one subject, or between
  adjective and its noun. (The "no comma" choice is frequently correct.)
- `BND.list` Commas between series items and between two reversible (coordinate)
  adjectives.
- `BND.transition_punct` Conjunctive adverb joining two clauses: semicolon/period
  before, comma after. *…hard; therefore, she passed.*

## §B. FORM, STRUCTURE & SENSE (`FSS`) — usage

- `FSS.sva_core` Singular subject → singular verb.
- `FSS.sva_intervening` **#1 trap:** prepositional phrase/clause between subject
  and verb doesn't change number — cross it out. *The success of new platforms
  **has**…*
- `FSS.sva_compound` "And" subjects are plural.
- `FSS.sva_or` or/nor, either…or, neither…nor → verb agrees with **nearest**
  subject.
- `FSS.sva_collective` Team/group/committee/government and each/every/everyone/
  gerund subjects = singular.
- `FSS.sva_inverted` "There is/are" and inverted order: verb agrees with the
  subject that follows.
- `FSS.pronoun_number` Pronoun matches antecedent in number. *The flytrap's jaws
  close when **it** senses prey.*
- `FSS.its_their` its/it's, their/there/they're, whose/who's — for pronouns,
  apostrophe = contraction, never possession.
- `FSS.pronoun_case` Subjective vs objective (between you and **me**).
- `FSS.who_whom` who = subject, whom = object.
- `FSS.pronoun_ambiguous` Every pronoun needs one clear antecedent.
- `FSS.tense_consistency` Keep tense consistent unless the timeline shifts.
- `FSS.perfect` Present perfect (has/have + participle, cued by for/since); past
  perfect (had + participle) = earlier of two past actions.
- `FSS.finite` A nonfinite form (infinitive/gerund/participle) used as the main
  verb creates a fragment.
- `FSS.subjunctive` Hypothetical "if" → *were*.
- `FSS.dangling` Intro descriptive phrase must be immediately followed by the
  noun it describes. *Born in Mexico City, Frida Kahlo painted…*
- `FSS.misplaced` Modifier sits next to what it modifies.
- `FSS.parallel` Series items / elements joined by and/but and correlatives
  (not only…but also, either…or, as…as) share grammatical form.
- `FSS.apostrophe` Singular → 's; plural -s → apostrophe only; irregular plural →
  's; plain plurals get none.
- `FSS.noun_number` Nouns agree logically in number with the sentence.
- `FSS.comparison` Compare equivalent items (that of / those of / possessive);
  *than* (not *then*).
- `FSS.quantity` Countable → fewer/many/number; uncountable → less/much/amount.
- `FSS.comparative` -er/more for two; -est/most for 3+; never double.
- `FSS.fragment` Need subject + finite verb + complete thought.

**Secondary:** could/should/would **have** (never "of"); idiom/preposition by
ear; commonly confused words (affect/effect, discreet/discrete); a/an/the;
**redundancy** (never state the same info twice — heavily tested).
