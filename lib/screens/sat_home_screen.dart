import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sat_repository.dart';
import '../models/sat_question.dart';
import 'grammar_drills_screen.dart';
import 'mock_screen.dart';
import 'sat_practice_screen.dart';
import 'vocab_wic_screen.dart';

/// SAT Reading & Writing home: estimated level + per-skill mastery, grouped by
/// domain, each a tap into adaptive practice.
class SatHomeScreen extends ConsumerWidget {
  const SatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteryAsync = ref.watch(satMasteryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SAT Reading & Writing')),
      body: masteryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (mastery) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(satMasteryProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MixedCard(onTap: () => _practice(context, ref, null)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.4,
                  children: [
                    _ActionTile(
                      icon: Icons.today,
                      label: 'Daily set (10)',
                      onTap: () => _push(
                          context,
                          ref,
                          const SatPracticeScreen(
                              limit: 10, title: 'Daily set')),
                    ),
                    _ActionTile(
                      icon: Icons.timer,
                      label: 'Full mock',
                      onTap: () => _push(context, ref, const MockScreen()),
                    ),
                    _ActionTile(
                      icon: Icons.trending_down,
                      label: 'Weak skills',
                      onTap: () => _push(
                          context,
                          ref,
                          SatPracticeScreen(
                            skillCodes: _weakest(mastery),
                            title: 'Weak-skills focus',
                          )),
                    ),
                    _ActionTile(
                      icon: Icons.spellcheck,
                      label: 'Grammar drills',
                      onTap: () =>
                          _push(context, ref, const GrammarDrillsScreen()),
                    ),
                    _ActionTile(
                      icon: Icons.menu_book,
                      label: 'Practice your words',
                      onTap: () =>
                          _push(context, ref, const VocabWicScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final domain in satDomains) ...[
                  Text(domain,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final skill
                      in satSkills.where((s) => s.domain == domain))
                    _SkillRow(
                      skill: skill,
                      rating: mastery[skill.code],
                      onTap: () => _practice(context, ref, skill.code),
                    ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _practice(
      BuildContext context, WidgetRef ref, String? skillCode) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SatPracticeScreen(skillCode: skillCode),
    ));
    ref.invalidate(satMasteryProvider); // refresh ratings after practicing
  }

  Future<void> _push(BuildContext context, WidgetRef ref, Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    ref.invalidate(satMasteryProvider);
  }

  /// The 3 lowest-rated practiced skills; falls back to all skills if none yet.
  List<String> _weakest(Map<String, double> mastery) {
    if (mastery.isEmpty) return satSkills.map((s) => s.code).toList();
    final entries = mastery.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(3).map((e) => e.key).toList();
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MixedCard extends StatelessWidget {
  const _MixedCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.shuffle, color: scheme.onPrimaryContainer, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mixed adaptive practice',
                        style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('Questions across all skills, tuned to your level',
                        style: TextStyle(color: scheme.onPrimaryContainer)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow(
      {required this.skill, required this.rating, required this.onTap});
  final SatSkill skill;
  final double? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Map Elo (~1000–1800) to a 0–1 progress bar for a rough mastery sense.
    final r = rating ?? kStartRating;
    final progress = ((r - 1000) / 800).clamp(0.0, 1.0);
    final practiced = rating != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(skill.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      trailing: Text(
        practiced ? r.round().toString() : '—',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      onTap: onTap,
    );
  }
}
