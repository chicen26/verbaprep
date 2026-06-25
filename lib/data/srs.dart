/// SM-2 spaced-repetition scheduling (the algorithm Anki/SuperMemo are based on).
///
/// Given a card's current state and the user's recall grade, it returns the new
/// ease/interval/repetition count and when the card is next due.

/// Recall quality, surfaced to the user as four buttons.
enum ReviewGrade {
  again('Again', 1), // forgot — relearn this session
  hard('Hard', 3),
  good('Good', 4),
  easy('Easy', 5);

  const ReviewGrade(this.label, this.q);
  final String label;
  final int q; // 0..5 SM-2 quality
}

class SrsState {
  final double ease;
  final int intervalDays;
  final int repetitions;
  final DateTime dueAt;
  const SrsState({
    required this.ease,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
  });
}

/// Compute the next SRS state. Pure — pass `now` in so it's deterministic/testable.
SrsState scheduleSm2({
  required double ease,
  required int intervalDays,
  required int repetitions,
  required ReviewGrade grade,
  required DateTime now,
}) {
  final q = grade.q;

  // Ease factor update (clamped at 1.3), per SM-2.
  var newEase = ease + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
  if (newEase < 1.3) newEase = 1.3;

  // Failed recall → relearn in the same session (~10 min), reset streak.
  if (q < 3) {
    return SrsState(
      ease: newEase,
      intervalDays: 0,
      repetitions: 0,
      dueAt: now.add(const Duration(minutes: 10)),
    );
  }

  // Successful recall → grow the interval.
  int newInterval;
  if (repetitions == 0) {
    newInterval = 1;
  } else if (repetitions == 1) {
    newInterval = 6;
  } else {
    newInterval = (intervalDays * newEase).round();
    if (newInterval < 1) newInterval = 1;
  }

  return SrsState(
    ease: newEase,
    intervalDays: newInterval,
    repetitions: repetitions + 1,
    dueAt: now.add(Duration(days: newInterval)),
  );
}
