import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';
import '../models/sat_question.dart';

/// Progress analytics: estimated score, streak, accuracy, per-skill mastery,
/// and a 14-day activity sparkline.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analyticsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (a) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(analyticsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatRow(stats: [
                _Stat('Est. R&W', a.totalAttempts == 0 ? '—' : '${a.estimatedRw}'),
                _Stat('Streak', '${a.studyStreakDays}d'),
                _Stat('Accuracy',
                    a.totalAttempts == 0 ? '—' : '${(a.accuracy * 100).round()}%'),
              ]),
              const SizedBox(height: 12),
              _StatRow(stats: [
                _Stat('Questions', '${a.totalAttempts}'),
                _Stat('Words', '${a.wordsCount}'),
                _Stat('Due', '${a.wordsDue}'),
              ]),
              const SizedBox(height: 24),
              Text('Last 14 days',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _ActivityBars(points: a.last14Days),
              const SizedBox(height: 24),
              Text('Mastery by skill',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (a.bySkill.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Practice some SAT questions to see mastery here.'),
                )
              else
                for (final domain in satDomains)
                  ..._domainRows(context, a, domain),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _domainRows(BuildContext context, Analytics a, String domain) {
    final skills =
        satSkills.where((s) => s.domain == domain && a.bySkill.containsKey(s.code));
    if (skills.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(domain,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
      for (final s in skills) _SkillBar(stat: a.bySkill[s.code]!),
    ];
  }
}

class _Stat {
  final String label;
  final String value;
  _Stat(this.label, this.value);
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stats});
  final List<_Stat> stats;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final s in stats)
          Expanded(
            child: Card(
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Column(
                  children: [
                    Text(s.value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(s.label,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityBars extends StatelessWidget {
  const _ActivityBars({required this.points});
  final List<DayPoint> points;
  @override
  Widget build(BuildContext context) {
    final maxA =
        points.map((p) => p.attempts).fold<int>(1, (m, v) => v > m ? v : m);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 6 + 56 * (p.attempts / maxA),
                      decoration: BoxDecoration(
                        color: p.attempts == 0
                            ? scheme.surfaceContainerHighest
                            : scheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.stat});
  final SkillStat stat;
  @override
  Widget build(BuildContext context) {
    final progress = ((stat.rating - 1000) / 800).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(skillByCode(stat.skillCode).name,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              stat.attempts == 0
                  ? '${stat.rating.round()}'
                  : '${(stat.accuracy * 100).round()}% · ${stat.rating.round()}',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
