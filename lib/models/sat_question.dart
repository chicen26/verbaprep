/// One SAT Reading & Writing question. Mirrors `sat_questions` (see migration
/// and docs/sat-rw-spec.md). `choices` is a 4-element list; `answer` is its index.
class SatQuestion {
  final String id;
  final String skillCode;
  final String? ruleCode;
  final int difficulty; // 1..5
  final String passage;
  final String? passage2; // Cross-Text only
  final String stimulusKind; // 'passage' | 'notes' | 'graph'
  final String stem;
  final List<String> choices;
  final int answer;
  final String explanation;

  SatQuestion({
    required this.id,
    required this.skillCode,
    this.ruleCode,
    required this.difficulty,
    required this.passage,
    this.passage2,
    this.stimulusKind = 'passage',
    required this.stem,
    required this.choices,
    required this.answer,
    required this.explanation,
  });

  factory SatQuestion.fromJson(Map<String, dynamic> j) => SatQuestion(
        id: j['id'] as String,
        skillCode: j['skill_code'] as String,
        ruleCode: j['rule_code'] as String?,
        difficulty: j['difficulty'] as int,
        passage: j['passage'] as String,
        passage2: j['passage2'] as String?,
        stimulusKind: j['stimulus_kind'] as String? ?? 'passage',
        stem: j['stem'] as String,
        choices: (j['choices'] as List).cast<String>(),
        answer: j['answer'] as int,
        explanation: j['explanation'] as String,
      );
}

/// The 11 SAT R&W skills grouped by the 4 College Board domains.
class SatSkill {
  final String code;
  final String name;
  final String domain;
  const SatSkill(this.code, this.name, this.domain);
}

const satSkills = <SatSkill>[
  // Craft & Structure
  SatSkill('WIC', 'Words in Context', 'Craft & Structure'),
  SatSkill('TSP', 'Text Structure & Purpose', 'Craft & Structure'),
  SatSkill('CTC', 'Cross-Text Connections', 'Craft & Structure'),
  // Information & Ideas
  SatSkill('CID', 'Central Ideas & Details', 'Information & Ideas'),
  SatSkill('COE_T', 'Command of Evidence (Textual)', 'Information & Ideas'),
  SatSkill('COE_Q', 'Command of Evidence (Quantitative)', 'Information & Ideas'),
  SatSkill('INF', 'Inferences', 'Information & Ideas'),
  // Standard English Conventions
  SatSkill('BND', 'Boundaries', 'Standard English Conventions'),
  SatSkill('FSS', 'Form, Structure & Sense', 'Standard English Conventions'),
  // Expression of Ideas
  SatSkill('TRN', 'Transitions', 'Expression of Ideas'),
  SatSkill('RHS', 'Rhetorical Synthesis', 'Expression of Ideas'),
];

SatSkill skillByCode(String code) =>
    satSkills.firstWhere((s) => s.code == code,
        orElse: () => SatSkill(code, code, ''));

/// The four domains in test order.
const satDomains = <String>[
  'Craft & Structure',
  'Information & Ideas',
  'Standard English Conventions',
  'Expression of Ideas',
];
