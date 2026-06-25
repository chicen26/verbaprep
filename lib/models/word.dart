/// A captured vocabulary word + its spaced-repetition state.
/// Mirrors the `words` table in supabase/migrations/0001_init.sql.
class Word {
  final String id;
  final String word;
  final String? definition;
  final String? partOfSpeech;
  final String? example;
  final String? context;
  final String? sourceApp;
  final List<String> tags;
  final bool starred;
  // SM-2 spaced-repetition state
  final double ease;
  final int intervalDays;
  final int repetitions;
  final DateTime dueAt;
  final int reviewCount;
  final bool isSatRelevant;
  final int? difficulty;
  final DateTime createdAt;

  Word({
    required this.id,
    required this.word,
    this.definition,
    this.partOfSpeech,
    this.example,
    this.context,
    this.sourceApp,
    this.tags = const [],
    this.starred = false,
    this.ease = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    required this.dueAt,
    this.reviewCount = 0,
    this.isSatRelevant = false,
    this.difficulty,
    required this.createdAt,
  });

  factory Word.fromJson(Map<String, dynamic> j) => Word(
        id: j['id'] as String,
        word: j['word'] as String,
        definition: j['definition'] as String?,
        partOfSpeech: j['part_of_speech'] as String?,
        example: j['example'] as String?,
        context: j['context'] as String?,
        sourceApp: j['source_app'] as String?,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        starred: j['starred'] as bool? ?? false,
        ease: (j['ease'] as num?)?.toDouble() ?? 2.5,
        intervalDays: j['interval_days'] as int? ?? 0,
        repetitions: j['repetitions'] as int? ?? 0,
        dueAt: DateTime.parse(j['due_at'] as String),
        reviewCount: j['review_count'] as int? ?? 0,
        isSatRelevant: j['is_sat_relevant'] as bool? ?? false,
        difficulty: j['difficulty'] as int?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  /// Only the columns a client is allowed to write (the rest have DB defaults).
  Map<String, dynamic> toInsert(String userId) => {
        'user_id': userId,
        'word': word,
        if (definition != null) 'definition': definition,
        if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
        if (example != null) 'example': example,
        if (context != null) 'context': context,
        if (sourceApp != null) 'source_app': sourceApp,
        'tags': tags,
      };
}

/// User-selectable orderings for the word list.
enum WordSort {
  recent('Most recent'),
  oldest('Oldest'),
  az('A–Z'),
  za('Z–A'),
  due('Due for review'),
  mostReviewed('Most reviewed'),
  leastReviewed('Least reviewed'),
  starredFirst('Starred first');

  const WordSort(this.label);
  final String label;
}

/// Sorts a copy of [words] by [sort] (client-side so the menu is instant).
List<Word> sortWords(List<Word> words, WordSort sort) {
  final list = [...words];
  switch (sort) {
    case WordSort.recent:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case WordSort.oldest:
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case WordSort.az:
      list.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    case WordSort.za:
      list.sort((a, b) => b.word.toLowerCase().compareTo(a.word.toLowerCase()));
    case WordSort.due:
      list.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    case WordSort.mostReviewed:
      list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    case WordSort.leastReviewed:
      list.sort((a, b) => a.reviewCount.compareTo(b.reviewCount));
    case WordSort.starredFirst:
      list.sort((a, b) {
        if (a.starred != b.starred) return a.starred ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }
  return list;
}
