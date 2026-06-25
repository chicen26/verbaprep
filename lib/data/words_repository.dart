import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider (Riverpod 3.x)
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/word.dart';
import 'srs.dart';

/// Reads/writes the signed-in user's `words` rows. RLS guarantees a user only
/// ever sees their own rows, so we never filter by user_id on reads.
class WordsRepository {
  WordsRepository(this._db);
  final SupabaseClient _db;

  Future<List<Word>> fetchAll() async {
    final rows = await _db.from('words').select().order('created_at',
        ascending: false) as List<dynamic>;
    return rows.map((r) => Word.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> add({
    required String word,
    String? definition,
    String? partOfSpeech,
    String? example,
    String? context,
    String? sourceApp,
  }) async {
    final userId = _db.auth.currentUser!.id;
    await _db.from('words').upsert({
      'user_id': userId,
      'word': word.trim().toLowerCase(),
      if (definition != null) 'definition': definition,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (example != null) 'example': example,
      if (context != null) 'context': context,
      if (sourceApp != null) 'source_app': sourceApp,
    }, onConflict: 'user_id,word');
  }

  Future<void> setStarred(String id, bool starred) async {
    await _db.from('words').update({'starred': starred}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _db.from('words').delete().eq('id', id);
  }

  /// Cards due for review now (due_at <= now), soonest first.
  Future<List<Word>> fetchDue() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final rows = await _db
        .from('words')
        .select()
        .lte('due_at', nowIso)
        .order('due_at', ascending: true) as List<dynamic>;
    return rows.map((r) => Word.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Apply a review grade: advance the card's SM-2 state and log the review.
  Future<void> recordReview(Word word, ReviewGrade grade) async {
    final next = scheduleSm2(
      ease: word.ease,
      intervalDays: word.intervalDays,
      repetitions: word.repetitions,
      grade: grade,
      now: DateTime.now(),
    );
    await _db.from('words').update({
      'ease': next.ease,
      'interval_days': next.intervalDays,
      'repetitions': next.repetitions,
      'due_at': next.dueAt.toUtc().toIso8601String(),
      'review_count': word.reviewCount + 1,
    }).eq('id', word.id);

    await _db.from('review_log').insert({
      'user_id': _db.auth.currentUser!.id,
      'word_id': word.id,
      'grade': grade.q,
    });
  }
}

final wordsRepositoryProvider = Provider<WordsRepository>(
  (ref) => WordsRepository(Supabase.instance.client),
);

/// All of the current user's words, newest first. Refresh with
/// `ref.invalidate(wordsProvider)` after a mutation.
final wordsProvider = FutureProvider<List<Word>>(
  (ref) => ref.watch(wordsRepositoryProvider).fetchAll(),
);

/// Cards currently due for review. Watches [wordsProvider] so the due count
/// recomputes automatically whenever words are added/changed (no manual refresh).
final dueWordsProvider = FutureProvider<List<Word>>((ref) {
  ref.watch(wordsProvider); // re-run when the word list changes
  return ref.watch(wordsRepositoryProvider).fetchDue();
});

/// Current sort selection for the list screen.
final wordSortProvider = StateProvider<WordSort>((ref) => WordSort.recent);

/// Current search query (matches word + definition).
final wordSearchProvider = StateProvider<String>((ref) => '');
