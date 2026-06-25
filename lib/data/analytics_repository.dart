import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sat_question.dart';

/// Aggregated progress stats for the dashboard, computed from the user's
/// sat_attempts, skill_mastery, review_log, and words.
class Analytics {
  final int totalAttempts;
  final int totalCorrect;
  final int reviewsToday;
  final int wordsCount;
  final int wordsDue;
  final int studyStreakDays;
  final Map<String, SkillStat> bySkill; // skill_code -> stat
  final List<DayPoint> last14Days; // attempts/correct per day

  Analytics({
    required this.totalAttempts,
    required this.totalCorrect,
    required this.reviewsToday,
    required this.wordsCount,
    required this.wordsDue,
    required this.studyStreakDays,
    required this.bySkill,
    required this.last14Days,
  });

  double get accuracy => totalAttempts == 0 ? 0 : totalCorrect / totalAttempts;

  /// Estimated R&W score (200–800), rough: average skill rating mapped to band,
  /// nudged by recent accuracy. Presented as an estimate only.
  int get estimatedRw {
    if (bySkill.isEmpty) return 200;
    final avg = bySkill.values.map((s) => s.rating).reduce((a, b) => a + b) /
        bySkill.length;
    // 1000→~400, 1800→~790; clamp.
    final fromRating = 400 + (avg - 1000) / 800 * 390;
    final score = (fromRating + (accuracy - 0.6) * 60).round();
    return score.clamp(200, 800);
  }
}

class SkillStat {
  final String skillCode;
  final double rating;
  final int attempts;
  final int correct;
  SkillStat(this.skillCode, this.rating, this.attempts, this.correct);
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

class DayPoint {
  final DateTime day;
  final int attempts;
  final int correct;
  DayPoint(this.day, this.attempts, this.correct);
}

class AnalyticsRepository {
  AnalyticsRepository(this._db);
  final SupabaseClient _db;

  Future<Analytics> fetch() async {
    final attempts = await _db
        .from('sat_attempts')
        .select('correct, answered_at, question_id') as List<dynamic>;
    final mastery = await _db
        .from('skill_mastery')
        .select('skill_code, rating, attempts') as List<dynamic>;
    final words = await _db.from('words').select('due_at') as List<dynamic>;
    final reviews =
        await _db.from('review_log').select('reviewed_at') as List<dynamic>;
    // Map each attempted question to its skill for per-skill correctness.
    final qIds = attempts
        .map((a) => a['question_id'] as String)
        .toSet()
        .toList();
    final skillByQ = <String, String>{};
    if (qIds.isNotEmpty) {
      final qs = await _db
          .from('sat_questions')
          .select('id, skill_code')
          .inFilter('id', qIds) as List<dynamic>;
      for (final q in qs) {
        skillByQ[q['id'] as String] = q['skill_code'] as String;
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Per-skill correctness from attempts.
    final correctBySkill = <String, int>{};
    final attemptsBySkill = <String, int>{};
    var totalCorrect = 0;
    final daysMap = <DateTime, List<int>>{}; // day -> [attempts, correct]
    final attemptDays = <DateTime>{};
    for (final a in attempts) {
      final correct = a['correct'] as bool? ?? false;
      if (correct) totalCorrect++;
      final sk = skillByQ[a['question_id']];
      if (sk != null) {
        attemptsBySkill[sk] = (attemptsBySkill[sk] ?? 0) + 1;
        if (correct) correctBySkill[sk] = (correctBySkill[sk] ?? 0) + 1;
      }
      final at = DateTime.parse(a['answered_at'] as String).toLocal();
      final d = DateTime(at.year, at.month, at.day);
      attemptDays.add(d);
      final slot = daysMap.putIfAbsent(d, () => [0, 0]);
      slot[0]++;
      if (correct) slot[1]++;
    }

    // Mastery + merge per-skill stats.
    final bySkill = <String, SkillStat>{};
    for (final m in mastery) {
      final code = m['skill_code'] as String;
      bySkill[code] = SkillStat(
        code,
        (m['rating'] as num).toDouble(),
        attemptsBySkill[code] ?? 0,
        correctBySkill[code] ?? 0,
      );
    }

    // Reviews today + streak (days with any attempt or review).
    var reviewsToday = 0;
    final activeDays = <DateTime>{...attemptDays};
    for (final r in reviews) {
      final at = DateTime.parse(r['reviewed_at'] as String).toLocal();
      final d = DateTime(at.year, at.month, at.day);
      activeDays.add(d);
      if (d == today) reviewsToday++;
    }
    var streak = 0;
    var cursor = today;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Words due now.
    var due = 0;
    for (final w in words) {
      if (!DateTime.parse(w['due_at'] as String).isAfter(now)) due++;
    }

    // Last 14 days series.
    final series = <DayPoint>[];
    for (var i = 13; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final slot = daysMap[d] ?? [0, 0];
      series.add(DayPoint(d, slot[0], slot[1]));
    }

    return Analytics(
      totalAttempts: attempts.length,
      totalCorrect: totalCorrect,
      reviewsToday: reviewsToday,
      wordsCount: words.length,
      wordsDue: due,
      studyStreakDays: streak,
      bySkill: bySkill,
      last14Days: series,
    );
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(Supabase.instance.client),
);

final analyticsProvider = FutureProvider<Analytics>(
  (ref) => ref.watch(analyticsRepositoryProvider).fetch(),
);

/// Helper to label skills in the dashboard.
String skillLabel(String code) => skillByCode(code).name;
