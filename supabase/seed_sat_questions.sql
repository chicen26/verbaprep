-- Initial SAT Reading & Writing seed bank for VerbaPrep.
-- Original questions written to docs/sat-rw-spec.md + grammar-rules.md.
-- Shared bank rows (owner_id stays null), verified=true so the app serves them.
-- Run once in the Supabase SQL editor. Dollar-quoting ($q$) avoids escaping.

insert into public.sat_questions
  (skill_code, rule_code, difficulty, passage, stimulus_kind, stem, choices, answer, explanation, source, verified)
values

-- ───────── Words in Context (WIC) ─────────
('WIC', null, 2,
 $q$The new bridge was designed to be ______; engineers expected it to stand for at least a century without major repairs.$q$,
 'passage',
 $q$Which choice completes the text with the most logical and precise word?$q$,
 $q$["temporary","durable","elegant","expensive"]$q$::jsonb, 1,
 $q$"Durable" (long-lasting) is restated by "stand for at least a century without major repairs." "Temporary" is the opposite; "elegant" and "expensive" don't connect to longevity.$q$,
 'manual', true),

('WIC', null, 3,
 $q$Although critics initially dismissed her theory as ______, subsequent experiments confirmed its predictions so precisely that it is now a cornerstone of the field.$q$,
 'passage',
 $q$Which choice completes the text with the most logical and precise word?$q$,
 $q$["groundbreaking","implausible","conventional","ambiguous"]$q$::jsonb, 1,
 $q$"Although ... dismissed ... but later confirmed" signals the critics first found the theory unbelievable, so "implausible" fits. "Groundbreaking" is positive (wrong direction); "conventional" and "ambiguous" don't match "dismissed."$q$,
 'manual', true),

('WIC', null, 4,
 $q$Maria's prose is admired for its economy: she ______ every superfluous word, leaving sentences that are lean and exact.$q$,
 'passage',
 $q$Which choice completes the text with the most logical and precise word?$q$,
 $q$["excises","tolerates","embellishes","misplaces"]$q$::jsonb, 0,
 $q$"Economy" and "leaving sentences that are lean and exact" signal cutting words out, so "excises" (removes) is precise. "Tolerates" is the opposite; "embellishes" adds words; "misplaces" is unrelated.$q$,
 'manual', true),

('WIC', null, 5,
 $q$The committee's report was anything but novel; its recommendations merely ______ proposals that others had advanced years earlier.$q$,
 'passage',
 $q$Which choice completes the text with the most logical and precise word?$q$,
 $q$["refuted","echoed","complicated","funded"]$q$::jsonb, 1,
 $q$"Anything but novel ... merely" tells us the report repeated old ideas, so "echoed" fits. "Refuted" is the opposite; "complicated" and "funded" don't capture mere repetition.$q$,
 'manual', true),

-- ───────── Transitions (TRN) ─────────
('TRN', null, 2,
 $q$The factory reduced its emissions by half last year. ______, it cut its water usage by a third.$q$,
 'passage',
 $q$Which choice completes the text with the most logical transition?$q$,
 $q$["However","In addition","For example","Therefore"]$q$::jsonb, 1,
 $q$The two sentences list parallel achievements, so an addition transition ("In addition") fits. "However" signals contrast, "For example" signals an instance, and "Therefore" signals cause-effect — none match.$q$,
 'manual', true),

('TRN', null, 3,
 $q$Most songbirds learn their songs by imitating nearby adults. The brown-headed cowbird, ______, produces its song correctly even when raised in complete isolation.$q$,
 'passage',
 $q$Which choice completes the text with the most logical transition?$q$,
 $q$["however","likewise","for instance","consequently"]$q$::jsonb, 0,
 $q$The cowbird contrasts with "most songbirds," so "however" fits. "Likewise" wrongly signals similarity; "for instance" signals an example; "consequently" signals a result.$q$,
 'manual', true),

('TRN', null, 4,
 $q$The drug performed well in early trials. ______, researchers cautioned that its long-term effects remained unknown and urged further study.$q$,
 'passage',
 $q$Which choice completes the text with the most logical transition?$q$,
 $q$["As a result","Nevertheless","Similarly","For example"]$q$::jsonb, 1,
 $q$Good results are followed by a caution, a concession/contrast, so "Nevertheless" fits. "As a result" signals cause-effect, "Similarly" signals comparison, "For example" signals an instance.$q$,
 'manual', true),

-- ───────── Rhetorical Synthesis (RHS) ─────────
('RHS', null, 3,
 $q$While researching a topic, a student has taken the following notes:
• The axolotl is a salamander native to lakes near Mexico City.
• Unlike most amphibians, it keeps its larval features for its entire life.
• It can regenerate lost limbs, organs, and even parts of its brain.
• Scientists study it to better understand tissue regeneration.$q$,
 'notes',
 $q$The student wants to emphasize the axolotl's regenerative ability. Which choice most effectively uses relevant information from the notes to accomplish this goal?$q$,
 $q$["The axolotl, a salamander from lakes near Mexico City, keeps its larval features for life.","The axolotl can regenerate lost limbs, organs, and even parts of its brain.","Native to the lakes near Mexico City, the axolotl is studied by scientists.","Unlike most amphibians, the axolotl retains its larval features throughout its life."]$q$::jsonb, 1,
 $q$Only choice B is about regeneration, the stated goal. A, C, and D are accurate to the notes but emphasize the axolotl's habitat or larval features instead.$q$,
 'manual', true),

('RHS', null, 4,
 $q$While researching a topic, a student has taken the following notes:
• Jane Austen published her novels anonymously.
• Her early works were credited only to "A Lady."
• Her authorship became widely known only after her death.
• Today she is among the most celebrated English novelists.$q$,
 'notes',
 $q$The student wants to emphasize the contrast between Austen's anonymity during her life and her fame today. Which choice most effectively uses relevant information from the notes to accomplish this goal?$q$,
 $q$["Jane Austen, who published anonymously as \"A Lady,\" is now among the most celebrated English novelists.","Jane Austen published her novels anonymously and was credited only as \"A Lady.\"","Jane Austen is today among the most celebrated English novelists.","Austen's authorship became widely known only after her death."]$q$::jsonb, 0,
 $q$Only choice A captures both halves of the contrast — anonymity in her lifetime AND fame today. B states only the anonymity, C states only the fame, and D gives a partial detail.$q$,
 'manual', true),

-- ───────── Boundaries (BND) ─────────
('BND', 'BND.comma_misuse', 2,
 $q$The scientist who first identified the compound ______ never received public credit for the discovery.$q$,
 'passage',
 $q$Which choice completes the text so that it conforms to the conventions of Standard English?$q$,
 $q$["compound,","compound;","compound:","compound"]$q$::jsonb, 3,
 $q$"The scientist who first identified the compound" is the subject; nothing should separate it from the verb "never received." So no punctuation (D) is correct. A comma, semicolon, or colon all wrongly break the subject from its verb.$q$,
 'manual', true),

('BND', 'BND.supplement', 3,
 $q$The Great Barrier Reef ______ the largest living structure on Earth, is visible from space.$q$,
 'passage',
 $q$Which choice completes the text so that it conforms to the conventions of Standard English?$q$,
 $q$["Reef,","Reef","Reef;","Reef:"]$q$::jsonb, 0,
 $q$"the largest living structure on Earth" is nonessential information, set off by a pair of commas; the closing comma is already present after "Earth," so a comma is needed before it too (A). No punctuation (B) leaves an unmatched comma; a semicolon or colon (C, D) would create a fragment.$q$,
 'manual', true),

('BND', 'BND.colon', 4,
 $q$Archaeologists recovered three artifacts from the site ______ a bronze coin, a clay tablet, and a small carved figurine.$q$,
 'passage',
 $q$Which choice completes the text so that it conforms to the conventions of Standard English?$q$,
 $q$["site,","site:","site;","site, namely;"]$q$::jsonb, 1,
 $q$A complete sentence precedes the punctuation and a list follows, so a colon (B) is correct. A comma (A) can't introduce the list this way; a semicolon (C) needs an independent clause after it; "namely;" (D) misuses the semicolon.$q$,
 'manual', true),

-- ───────── Form, Structure, and Sense (FSS) ─────────
('FSS', 'FSS.sva_intervening', 2,
 $q$The collection of rare medieval manuscripts ______ housed in a climate-controlled vault beneath the library.$q$,
 'passage',
 $q$Which choice completes the text so that it conforms to the conventions of Standard English?$q$,
 $q$["are","is","were","have been"]$q$::jsonb, 1,
 $q$The subject is the singular "collection"; "of rare medieval manuscripts" is an intervening prepositional phrase that doesn't change the number. So the singular "is" (B) agrees. A, C, and D are plural.$q$,
 'manual', true),

('FSS', 'FSS.pronoun_number', 3,
 $q$Although the company expanded into a dozen countries within five years, ______ never lost sight of its original mission.$q$,
 'passage',
 $q$Which choice completes the text so that it conforms to the conventions of Standard English?$q$,
 $q$["they","it","one","its"]$q$::jsonb, 1,
 $q$"Company" is singular, so the singular pronoun "it" (B) agrees with it. "They" is plural; "one" is vague; "its" is possessive and can't serve as the subject.$q$,
 'manual', true),

('FSS', 'FSS.dangling', 4,
 $q$Discovered in 1994, ______ has become one of the most studied prehistoric cave-art sites in the world.$q$,
 'passage',
 $q$Which choice completes the text so that it conforms to the conventions of Standard English?$q$,
 $q$["researchers consider the Chauvet Cave","the Chauvet Cave","there is the Chauvet Cave, which","it is the Chauvet Cave that"]$q$::jsonb, 1,
 $q$The opening modifier "Discovered in 1994" must describe the subject that follows. Only "the Chauvet Cave" (B) was discovered in 1994. "Researchers" (A) weren't discovered; C and D are awkward and break the modifier-subject link.$q$,
 'manual', true),

-- ───────── Inferences (INF) ─────────
('INF', null, 3,
 $q$Deep-sea anglerfish live in waters so deep that almost no sunlight reaches them. To draw prey out of this near-total darkness, they have evolved a glowing lure that dangles just in front of their mouths. For the anglerfish, then, the ability to produce its own light is ______$q$,
 'passage',
 $q$Which choice most logically completes the text?$q$,
 $q$["a disadvantage in deep water.","essential to catching food.","harmful to its prey's vision.","unrelated to its survival."]$q$::jsonb, 1,
 $q$The glowing lure attracts prey in the dark, so the fish's self-produced light is essential to catching food (B). A, C, and D contradict the passage's point that the light helps the fish feed.$q$,
 'manual', true),

('INF', null, 4,
 $q$Researchers observed that crows in several cities crack nuts by dropping them onto crosswalks and retrieving the kernels once traffic halts at red lights. Crows in nearby rural areas, which lack such intersections, almost never display this behavior. The findings suggest that the nut-cracking behavior is ______$q$,
 'passage',
 $q$Which choice most logically completes the text?$q$,
 $q$["instinctive in every crow.","shaped by the crows' surroundings.","steadily declining over time.","harmful to the crows that use it."]$q$::jsonb, 1,
 $q$Urban crows display the behavior and rural crows don't, which points to the environment (the presence of intersections) shaping it (B). A is contradicted; C and D have no support in the text.$q$,
 'manual', true),

-- ───────── Central Ideas & Details (CID) ─────────
('CID', null, 2,
 $q$Bioluminescent fungi glow faintly in the dark forests where they grow. Scientists once assumed the glow was simply a useless byproduct of the fungi's metabolism. Recent experiments, however, show that the light attracts insects, which then carry away and spread the fungi's spores — suggesting the glow serves an important reproductive purpose.$q$,
 'passage',
 $q$Which choice best states the main idea of the text?$q$,
 $q$["Bioluminescent fungi glow because of their metabolism.","Insects are harmed by the light of bioluminescent fungi.","The glow of bioluminescent fungi may help the fungi reproduce.","Bioluminescent fungi are common in dark forests."]$q$::jsonb, 2,
 $q$The text builds to the point that the glow aids reproduction by attracting spore-spreading insects (C). A is the old, rejected assumption; B is not stated; D is a minor detail, not the main idea.$q$,
 'manual', true),

('CID', null, 3,
 $q$In her research on coral reefs, marine biologist Dr. Ruiz documented that reefs exposed to moderate wave action recovered from bleaching faster than sheltered reefs did. She proposes that the water movement delivers nutrients and flushes away harmful algae, giving stressed corals a better chance to rebound.$q$,
 'passage',
 $q$Which choice best states the main idea of the text?$q$,
 $q$["Coral bleaching is caused by wave action.","Dr. Ruiz found that moderate wave action can help corals recover from bleaching.","Sheltered reefs never recover from bleaching.","Harmful algae are the leading cause of coral bleaching."]$q$::jsonb, 1,
 $q$The passage's central finding is that wave action speeds recovery from bleaching (B). A reverses cause and effect; C overstates with "never"; D is not the focus.$q$,
 'manual', true),

-- ───────── Text Structure & Purpose (TSP) ─────────
('TSP', null, 3,
 $q$Many people assume that lightning never strikes the same place twice. In reality, tall structures such as the Empire State Building are hit dozens of times every year. The persistence of the saying shows how a memorable phrase can outlast the very facts it distorts.$q$,
 'passage',
 $q$Which choice best describes the overall structure of the text?$q$,
 $q$["It presents a common belief, refutes it with evidence, and then reflects on why the belief endures.","It describes a scientific experiment and reports its results.","It compares two competing theories about how lightning forms.","It argues that popular sayings are usually based on accurate observations."]$q$::jsonb, 0,
 $q$The text states a common belief, disproves it with the Empire State Building example, then comments on why the saying survives (A). B, C, and D describe structures the passage doesn't follow.$q$,
 'manual', true),

('TSP', null, 4,
 $q$The author opens the essay with a vivid description of a bustling night market, then narrows the focus to a single vendor frying dumplings, and finally uses that vendor's story to illustrate the resilience of immigrant communities.$q$,
 'passage',
 $q$Which choice best describes the main purpose of the text?$q$,
 $q$["To criticize the working conditions of night markets","To explain a recipe for preparing dumplings","To show how the essay moves from a broad scene to a specific story that supports a larger point","To compare two different immigrant communities"]$q$::jsonb, 2,
 $q$The sentence describes a movement from a wide scene to one vendor whose story makes a broader point about resilience (C). A, B, and D misread the passage's purpose.$q$,
 'manual', true),

-- ───────── Command of Evidence — Textual (COE_T) ─────────
('COE_T', null, 3,
 $q$A researcher hypothesizes that giving students brief physical-activity breaks during class improves their focus on the tasks that follow. To test this, she plans to compare students' focus after lessons that include activity breaks with their focus after lessons that do not.$q$,
 'passage',
 $q$Which finding, if true, would most strongly support the researcher's hypothesis?$q$,
 $q$["Students reported that they enjoyed the activity breaks.","Students scored higher on focus tasks after lessons with activity breaks than after lessons without them.","The activity breaks were easy for teachers to fit into their lessons.","Students who exercised outside of school had higher grades overall."]$q$::jsonb, 1,
 $q$The hypothesis links activity breaks to improved focus, so the directly supporting finding compares focus with vs. without breaks (B). A and C concern enjoyment and feasibility, not focus; D measures a different variable (out-of-school exercise and grades).$q$,
 'manual', true);
