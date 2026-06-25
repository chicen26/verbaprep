-- VerbaPrep SAT R&W seed bank, part 2: completes coverage of all 11 skill types
-- (adds Cross-Text Connections + Quantitative Evidence) and deepens the bank.
-- Run once in the Supabase SQL editor, after part 1.

insert into public.sat_questions
  (skill_code, rule_code, difficulty, passage, passage2, stimulus_kind, graphic, stem, choices, answer, explanation, source, verified)
values

-- ───────── Cross-Text Connections (CTC) ─────────
('CTC', null, 3,
 $q$Some economists argue that raising the minimum wage inevitably reduces employment: businesses facing higher labor costs, they reason, will simply hire fewer workers.$q$,
 $q$In a widely cited study of fast-food restaurants, Card and Krueger found that employment did not fall — and in some areas rose — after a minimum-wage increase, contrary to the prediction that higher wages must cut jobs.$q$,
 'passage', null,
 $q$Based on the texts, how would the authors of Text 2 most likely respond to the argument presented in Text 1?$q$,
 $q$["By agreeing that higher wages always reduce employment","By noting that empirical evidence does not support the claim that higher wages necessarily reduce employment","By arguing that minimum-wage increases harm businesses more than workers","By concluding that employment levels are entirely unrelated to wages"]$q$::jsonb, 1,
 $q$Text 2's findings directly contradict Text 1's prediction, so its authors would point to evidence against the claim (B). A agrees with Text 1; C and D make claims that go beyond what Text 2 states.$q$,
 'manual', true),

('CTC', null, 4,
 $q$Traditional accounts credit a single inventor with the electric light bulb, portraying innovation as the achievement of a lone genius working in isolation.$q$,
 $q$Historians of technology emphasize that the light bulb emerged from decades of incremental contributions by many researchers. Edison's real achievement, they argue, lay in refining and commercializing existing ideas rather than inventing from nothing.$q$,
 'passage', null,
 $q$Based on the texts, the authors of Text 2 would most likely characterize the view described in Text 1 as$q$,
 $q$["accurate but slightly understating Edison's commercial skill","an oversimplification that overlooks the collaborative, incremental nature of invention","a deliberate falsehood invented only to promote Edison","the single most reasonable way to understand technological progress"]$q$::jsonb, 1,
 $q$Text 2 stresses many contributors and gradual progress, so it would treat Text 1's lone-genius account as an oversimplification (B). A misses that Text 2 challenges the framing itself; C is too extreme; D contradicts Text 2.$q$,
 'manual', true),

-- ───────── Command of Evidence — Quantitative (COE_Q) ─────────
('COE_Q', null, 3,
 $q$A botanist measured the average height of sunflower seedlings grown under different daily light durations, recording each group after three weeks. She claimed that increasing the daily light duration was associated with taller seedlings, but only up to a point.$q$,
 null, 'graph',
 $q${"title":"Average seedling height after 3 weeks","columns":["Light per day (hours)","Avg. height (cm)"],"rows":[["6","8"],["9","14"],["12","19"],["15","20"],["18","19"]]}$q$::jsonb,
 $q$Which choice best uses data from the table to support the botanist's claim?$q$,
 $q$["Seedlings given 6 hours of light averaged 8 cm, while those given 12 hours averaged 19 cm.","Seedlings given 18 hours of light were the tallest in the study.","Seedling height decreased steadily as light duration increased.","Light duration had no measurable effect on seedling height."]$q$::jsonb, 0,
 $q$The claim is that more light means taller seedlings, up to a point. Choice A shows height rising from 8 cm at 6 hours to 19 cm at 12 hours, supporting it. B is false (15 hours was tallest, and 18 hours dropped); C and D are contradicted by the data.$q$,
 'manual', true),

('COE_Q', null, 4,
 $q$A researcher compared recycling rates in four towns, each of which offered curbside pickup at a different frequency. She argued that towns with more frequent pickup tended to achieve higher recycling rates.$q$,
 null, 'graph',
 $q${"title":"Recycling rate by pickup frequency","columns":["Town","Pickups per month","Recycling rate (%)"],"rows":[["Avon","2","31"],["Brey","4","44"],["Colt","4","46"],["Dane","8","62"]]}$q$::jsonb,
 $q$Which choice best uses data from the table to support the researcher's argument?$q$,
 $q$["Avon, with 2 pickups per month, had a recycling rate of 31%, while Dane, with 8 pickups, reached 62%.","Brey and Colt had nearly the same recycling rate.","Dane had the lowest recycling rate of the four towns.","Recycling rate was unrelated to how often pickup occurred."]$q$::jsonb, 0,
 $q$The argument links more frequent pickup to higher recycling. Choice A contrasts the least frequent (Avon, 31%) with the most frequent (Dane, 62%), supporting it. B is true but doesn't bear on frequency; C is false; D contradicts the trend.$q$,
 'manual', true),

-- ───────── More Words in Context ─────────
('WIC', null, 3,
 $q$Far from being ______, the senator's remarks were carefully calculated to appeal to undecided voters without alienating her longtime supporters.$q$,
 null, 'passage', null,
 $q$Which choice completes the text with the most logical and precise word?$q$,
 $q$["spontaneous","deliberate","persuasive","lengthy"]$q$::jsonb, 0,
 $q$"Far from being ______ ... carefully calculated" signals the opposite of calculated, so "spontaneous" fits. "Deliberate" is a synonym of calculated (wrong direction); "persuasive" and "lengthy" don't fit the contrast.$q$,
 'manual', true),

-- ───────── More Transitions ─────────
('TRN', null, 3,
 $q$The museum's new wing was widely praised for its bold, futuristic architecture. The exhibits inside, ______, struck many visitors as disappointingly conventional.$q$,
 null, 'passage', null,
 $q$Which choice completes the text with the most logical transition?$q$,
 $q$["for example","in addition","by contrast","as a result"]$q$::jsonb, 2,
 $q$The bold exterior is set against the conventional interior, so a contrast transition ("by contrast") fits. "For example" and "in addition" signal continuation; "as a result" signals cause-effect.$q$,
 'manual', true),

-- ───────── More Inferences ─────────
('INF', null, 3,
 $q$Certain desert plants open the pores in their leaves to take in carbon dioxide only at night, when the air is cooler. Because water evaporates more slowly in cool air than in hot air, this nighttime schedule allows the plants to ______$q$,
 null, 'passage', null,
 $q$Which choice most logically completes the text?$q$,
 $q$["absorb far more sunlight than other plants.","take in carbon dioxide while losing less water.","grow taller than plants in wetter climates.","stop producing sugars altogether."]$q$::jsonb, 1,
 $q$Opening pores at night, when evaporation is slower, lets the plants gather carbon dioxide while losing less water (B). A, C, and D are not supported by the passage.$q$,
 'manual', true),

-- ───────── More Boundaries ─────────
('BND', 'BND.splice', 3,
 $q$The volcano had been dormant for several centuries ______ geologists still monitored it closely for any signs of renewed activity.$q$,
 null, 'passage', null,
 $q$Which choice completes the text so that it conforms to the conventions of Standard English?$q$,
 $q$["centuries,","centuries, but","centuries; but","centuries but"]$q$::jsonb, 1,
 $q$Two independent clauses are joined here, so a comma plus the conjunction "but" is correct (B). A comma alone (A) is a splice; "; but" (C) redundantly pairs a semicolon with a conjunction; "but" with no comma (D) is incorrect.$q$,
 'manual', true),

-- ───────── More Form, Structure & Sense ─────────
('FSS', 'FSS.parallel', 3,
 $q$The internship taught her to analyze raw data, to write clear summaries, and ______ her findings to large audiences.$q$,
 null, 'passage', null,
 $q$Which choice completes the text so that it conforms to the conventions of Standard English?$q$,
 $q$["presenting","to present","presented","the presentation of"]$q$::jsonb, 1,
 $q$The sentence lists parallel infinitive phrases — "to analyze ... to write ... to present." Only "to present" (B) keeps the parallel structure; the other forms break it.$q$,
 'manual', true),

-- ───────── More Rhetorical Synthesis ─────────
('RHS', null, 3,
 $q$While researching a topic, a student has taken the following notes:
• Maria Tallchief was a celebrated American ballerina.
• She was the first Native American to hold the rank of prima ballerina.
• She danced leading roles with the New York City Ballet.
• She was of Osage heritage.$q$,
 null, 'notes', null,
 $q$The student wants to introduce Maria Tallchief to an audience unfamiliar with her. Which choice most effectively uses relevant information from the notes to accomplish this goal?$q$,
 $q$["Maria Tallchief, a celebrated American ballerina of Osage heritage, was the first Native American to become a prima ballerina.","Maria Tallchief danced leading roles with the New York City Ballet.","Maria Tallchief was of Osage heritage.","Maria Tallchief held the rank of prima ballerina."]$q$::jsonb, 0,
 $q$To introduce her, the best choice gives an identifying overview. Choice A combines who she was, her heritage, and her landmark achievement. B, C, and D each give only a single narrow detail.$q$,
 'manual', true),

-- ───────── More Central Ideas & Details (detail) ─────────
('CID', null, 4,
 $q$In the novel, the lighthouse keeper records every passing ship in a worn ledger, though no one ever asks to see it. He keeps up the practice long after the shipping company that once required it has dissolved, finding in the daily ritual a sense of order that the rest of his life lacks.$q$,
 null, 'passage', null,
 $q$According to the text, why does the lighthouse keeper continue recording the ships?$q$,
 $q$["Because the shipping company still requires the records","Because visitors frequently ask to see his ledger","Because the routine gives him a sense of order","Because he expects to be paid for the records"]$q$::jsonb, 2,
 $q$The text says he finds in the ritual "a sense of order that the rest of his life lacks" (C). A is contradicted (the company has dissolved); B is contradicted (no one asks); D has no support.$q$,
 'manual', true);
