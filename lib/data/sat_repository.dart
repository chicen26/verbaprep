import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sat_question.dart';

/// Elo: where a brand-new skill starts.
const double kStartRating = 1200;

/// Maps a question's 1–5 difficulty to an Elo "opponent" rating.
/// 1→1000, 2→1200, 3→1400, 4→1600, 5→1800.
double difficultyToRating(int difficulty) => 800 + difficulty * 200;

/// Reads the SAT bank, runs adaptive selection, records attempts, updates Elo.
class SatRepository {
  SatRepository(this._db);
  final SupabaseClient _db;

  /// All verified questions, optionally filtered to one skill. Shared bank rows
  /// (owner_id is null) plus the user's own vocab-derived items are visible.
  Future<List<SatQuestion>> fetchPool({String? skillCode}) async {
    final base = _db.from('sat_questions').select().eq('verified', true);
    final rows = (skillCode == null
        ? await base
        : await base.eq('skill_code', skillCode)) as List<dynamic>;
    return rows
        .map((r) => SatQuestion.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Current Elo rating per skill (defaults applied for skills never practiced).
  Future<Map<String, double>> fetchMastery() async {
    final rows = await _db
        .from('skill_mastery')
        .select('skill_code, rating, attempts') as List<dynamic>;
    final map = <String, double>{};
    for (final r in rows) {
      map[r['skill_code'] as String] = (r['rating'] as num).toDouble();
    }
    return map;
  }

  /// Record an answered question: write the attempt, then update the skill's Elo.
  Future<double> recordAttempt({
    required SatQuestion q,
    required int chosen,
    int? msTaken,
  }) async {
    final userId = _db.auth.currentUser!.id;
    final correct = chosen == q.answer;

    await _db.from('sat_attempts').insert({
      'user_id': userId,
      'question_id': q.id,
      'chosen': chosen,
      'correct': correct,
      if (msTaken != null) 'ms_taken': msTaken,
    });

    // Fetch current rating/attempts for this skill.
    final existing = await _db
        .from('skill_mastery')
        .select('rating, attempts')
        .eq('skill_code', q.skillCode)
        .maybeSingle();
    final rating =
        (existing?['rating'] as num?)?.toDouble() ?? kStartRating;
    final attempts = (existing?['attempts'] as int?) ?? 0;

    // Elo update. K decays as attempts grow so ratings stabilize.
    final k = attempts < 10 ? 40.0 : (attempts < 30 ? 28.0 : 20.0);
    final opp = difficultyToRating(q.difficulty);
    final expected = 1 / (1 + pow(10, (opp - rating) / 400));
    final actual = correct ? 1.0 : 0.0;
    final newRating = rating + k * (actual - expected);

    await _db.from('skill_mastery').upsert({
      'user_id': userId,
      'skill_code': q.skillCode,
      'rating': newRating,
      'attempts': attempts + 1,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    return newRating;
  }
}

/// Pure adaptive picker: from [pool], choose an unseen question whose difficulty
/// best matches the user's [rating], breaking ties at random.
SatQuestion? pickAdaptive({
  required List<SatQuestion> pool,
  required double rating,
  required Set<String> seen,
  required Random rng,
}) {
  final fresh = pool.where((q) => !seen.contains(q.id)).toList();
  if (fresh.isEmpty) return null;

  // Target difficulty band from the current rating (1..5).
  final target = ((rating - 800) / 200).round().clamp(1, 5);

  // Smallest distance to target, then random among the closest.
  fresh.sort((a, b) =>
      (a.difficulty - target).abs().compareTo((b.difficulty - target).abs()));
  final bestDist = (fresh.first.difficulty - target).abs();
  final closest =
      fresh.where((q) => (q.difficulty - target).abs() == bestDist).toList();
  return closest[rng.nextInt(closest.length)];
}

final satRepositoryProvider =
    Provider<SatRepository>((ref) => SatRepository(Supabase.instance.client));

/// Per-skill Elo ratings for the dashboard.
final satMasteryProvider = FutureProvider<Map<String, double>>(
  (ref) => ref.watch(satRepositoryProvider).fetchMastery(),
);
