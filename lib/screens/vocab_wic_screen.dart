import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/srs.dart';
import '../data/words_repository.dart';
import '../models/word.dart';

/// A generated Words-in-Context item built from one of the user's own words.
class _Item {
  final Word word;
  final String prompt; // sentence with a blank, or a definition prompt
  final List<String> choices;
  final int answer;
  _Item(this.word, this.prompt, this.choices, this.answer);
}

/// "Practice your words" — turns captured vocabulary into SAT-style
/// Words-in-Context questions (cloze from the example sentence, or
/// definition→word), and records each answer as a spaced-repetition review.
class VocabWicScreen extends ConsumerStatefulWidget {
  const VocabWicScreen({super.key});

  @override
  ConsumerState<VocabWicScreen> createState() => _VocabWicScreenState();
}

class _VocabWicScreenState extends ConsumerState<VocabWicScreen> {
  final _rng = Random();
  List<_Item>? _items;
  int _index = 0;
  int? _chosen;
  int _correct = 0;

  List<_Item> _build(List<Word> words) {
    // Need a pool of words to draw distractors from.
    final usable = words.where((w) => w.definition != null || w.example != null).toList();
    if (usable.length < 4) return [];
    final items = <_Item>[];
    final pool = [...usable]..shuffle(_rng);
    for (final w in pool.take(12)) {
      final distractors = (usable.where((x) => x.id != w.id).toList()..shuffle(_rng))
          .take(3)
          .map((x) => x.word)
          .toList();
      if (distractors.length < 3) continue;
      final choices = [w.word, ...distractors]..shuffle(_rng);
      final answer = choices.indexOf(w.word);

      final ex = w.example;
      final re = RegExp(r'\b' + RegExp.escape(w.word) + r'\b', caseSensitive: false);
      if (ex != null && re.hasMatch(ex)) {
        final prompt = ex.replaceFirst(re, '______');
        items.add(_Item(w, 'Which word best completes the sentence?\n\n“$prompt”',
            choices, answer));
      } else if (w.definition != null) {
        items.add(_Item(
            w, 'Which word most nearly means:\n\n“${w.definition}”', choices, answer));
      }
    }
    return items;
  }

  Future<void> _choose(int i) async {
    if (_chosen != null) return;
    final item = _items![_index];
    setState(() => _chosen = i);
    final right = i == item.answer;
    if (right) _correct++;
    // Record as an SRS review so it feeds the streak and reschedules the word.
    await ref.read(wordsRepositoryProvider).recordReview(
        item.word, right ? ReviewGrade.good : ReviewGrade.again);
  }

  void _next() {
    if (_index + 1 >= _items!.length) {
      ref.invalidate(wordsProvider);
      ref.invalidate(dueWordsProvider);
      setState(() => _index = _items!.length); // -> done
    } else {
      setState(() {
        _index++;
        _chosen = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Practice your words')),
      body: SafeArea(
        child: wordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (words) {
            _items ??= _build(words);
            final items = _items!;
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'Add at least 4 words (with definitions or examples) to practice them in context.',
                      textAlign: TextAlign.center),
                ),
              );
            }
            if (_index >= items.length) {
              return _done(items.length);
            }
            return _question(items[_index], items.length);
          },
        ),
      ),
    );
  }

  Widget _question(_Item item, int total) {
    final answered = _chosen != null;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        LinearProgressIndicator(value: (_index + 1) / total),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${_index + 1} of $total',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              Text(item.prompt, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              for (var i = 0; i < item.choices.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: !answered
                        ? scheme.surface
                        : i == item.answer
                            ? Colors.green.withValues(alpha: 0.15)
                            : (i == _chosen
                                ? scheme.errorContainer.withValues(alpha: 0.5)
                                : scheme.surface),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                          color: !answered
                              ? scheme.outlineVariant
                              : i == item.answer
                                  ? Colors.green
                                  : (i == _chosen
                                      ? scheme.error
                                      : scheme.outlineVariant)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: answered ? null : () => _choose(i),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(item.choices[i]),
                      ),
                    ),
                  ),
                ),
              if (answered && item.word.definition != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text('${item.word.word} — ${item.word.definition}'),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (answered)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(_index + 1 >= total ? 'Finish' : 'Next'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _done(int total) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text('$_correct of $total correct',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
