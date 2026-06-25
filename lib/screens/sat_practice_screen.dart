import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sat_repository.dart';
import '../models/sat_question.dart';

/// Adaptive practice over one skill (or mixed if skillCode is null).
class SatPracticeScreen extends ConsumerStatefulWidget {
  const SatPracticeScreen({super.key, this.skillCode});
  final String? skillCode;

  @override
  ConsumerState<SatPracticeScreen> createState() => _SatPracticeScreenState();
}

class _SatPracticeScreenState extends ConsumerState<SatPracticeScreen> {
  final _rng = Random();
  final _seen = <String>{};
  List<SatQuestion>? _pool;
  double _rating = kStartRating;
  SatQuestion? _current;
  int? _chosen; // null until answered
  bool _loading = true;
  String? _error;
  int _answered = 0;
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(satRepositoryProvider);
      final pool = await repo.fetchPool(skillCode: widget.skillCode);
      final mastery = await repo.fetchMastery();
      _rating = widget.skillCode != null
          ? (mastery[widget.skillCode] ?? kStartRating)
          : (mastery.values.isEmpty
              ? kStartRating
              : mastery.values.reduce((a, b) => a + b) / mastery.values.length);
      setState(() {
        _pool = pool;
        _loading = false;
      });
      _next();
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _next() {
    final q = pickAdaptive(
        pool: _pool ?? [], rating: _rating, seen: _seen, rng: _rng);
    setState(() {
      _current = q;
      _chosen = null;
      if (q != null) _seen.add(q.id);
    });
  }

  Future<void> _choose(int i) async {
    if (_chosen != null) return; // already answered
    final q = _current!;
    setState(() => _chosen = i);
    final correct = i == q.answer;
    _answered++;
    if (correct) _correct++;
    final newRating =
        await ref.read(satRepositoryProvider).recordAttempt(q: q, chosen: i);
    if (mounted) setState(() => _rating = newRating);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.skillCode == null
        ? 'Mixed practice'
        : skillByCode(widget.skillCode!).name;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('$_correct/$_answered  ·  ${_rating.round()}',
                  style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load practice:\n$_error',
                  textAlign: TextAlign.center)));
    }
    if (_current == null) {
      return _Done(answered: _answered, correct: _correct);
    }

    final q = _current!;
    final answered = _chosen != null;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SkillChip(q),
        const SizedBox(height: 12),
        if (q.passage2 != null) ...[
          _PassageBlock(label: 'Text 1', text: q.passage),
          const SizedBox(height: 10),
          _PassageBlock(label: 'Text 2', text: q.passage2!),
        ] else
          _PassageBlock(
              label: q.stimulusKind == 'notes' ? 'Notes' : null,
              text: q.passage),
        const SizedBox(height: 16),
        Text(q.stem,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (var i = 0; i < q.choices.length; i++)
          _ChoiceTile(
            letter: String.fromCharCode(65 + i),
            text: q.choices[i],
            state: !answered
                ? _ChoiceState.idle
                : i == q.answer
                    ? _ChoiceState.correct
                    : (i == _chosen
                        ? _ChoiceState.wrong
                        : _ChoiceState.idle),
            onTap: answered ? null : () => _choose(i),
          ),
        if (answered) ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chosen == q.answer ? '✓ Correct' : '✗ Not quite',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _chosen == q.answer
                          ? Colors.green
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(q.explanation),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _next,
            child: const Text('Next question'),
          ),
        ],
      ],
    );
  }
}

enum _ChoiceState { idle, correct, wrong }

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });
  final String letter;
  final String text;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? bg;
    Color? border;
    switch (state) {
      case _ChoiceState.correct:
        bg = Colors.green.withValues(alpha: 0.12);
        border = Colors.green;
      case _ChoiceState.wrong:
        bg = scheme.errorContainer.withValues(alpha: 0.5);
        border = scheme.error;
      case _ChoiceState.idle:
        bg = null;
        border = scheme.outlineVariant;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: bg ?? scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border ?? scheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$letter.',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassageBlock extends StatelessWidget {
  const _PassageBlock({this.label, required this.text});
  final String? label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
          ],
          Text(text, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.q);
  final SatQuestion q;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Chip(
          visualDensity: VisualDensity.compact,
          label: Text(skillByCode(q.skillCode).name),
        ),
        const SizedBox(width: 8),
        Text('Difficulty ${q.difficulty}/5',
            style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.answered, required this.correct});
  final int answered;
  final int correct;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            answered == 0
                ? 'No questions available yet'
                : 'Done! $correct of $answered correct',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(answered == 0
              ? 'The question bank is empty — seed it to start practicing.'
              : 'You’ve gone through every available question here.'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
