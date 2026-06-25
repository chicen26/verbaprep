import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/srs.dart';
import '../data/words_repository.dart';
import '../models/word.dart';

/// Spaced-repetition flashcard session over the cards that are due now.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<Word>? _queue; // snapshot taken once at session start
  int _index = 0;
  bool _revealed = false;
  int _reviewed = 0;

  @override
  Widget build(BuildContext context) {
    // Take a one-time snapshot of the due list so grading doesn't reshuffle us.
    if (_queue == null) {
      final due = ref.watch(dueWordsProvider);
      return due.when(
        loading: () => _scaffold(
            const Center(child: CircularProgressIndicator())),
        error: (e, _) =>
            _scaffold(Center(child: Text('Could not load review: $e'))),
        data: (words) {
          _queue = words;
          return _buildSession();
        },
      );
    }
    return _buildSession();
  }

  Widget _buildSession() {
    final queue = _queue!;
    if (queue.isEmpty) {
      return _scaffold(_DoneCard(reviewed: _reviewed));
    }
    if (_index >= queue.length) {
      return _scaffold(_DoneCard(reviewed: _reviewed));
    }

    final word = queue[_index];
    final theme = Theme.of(context);

    return _scaffold(
      Column(
        children: [
          LinearProgressIndicator(
            value: queue.isEmpty ? 0 : _index / queue.length,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('${_index + 1} of ${queue.length}',
                style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _revealed = true),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(word.word,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (word.partOfSpeech != null)
                          Text(word.partOfSpeech!,
                              style: theme.textTheme.bodySmall),
                        if (!_revealed) ...[
                          const SizedBox(height: 24),
                          Text('Tap to reveal',
                              style: theme.textTheme.bodySmall),
                        ] else ...[
                          const Divider(height: 32),
                          Text(word.definition ?? '(no definition saved)',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium),
                          if (word.example != null) ...[
                            const SizedBox(height: 12),
                            Text('“${word.example}”',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_revealed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Row(
                children: [
                  for (final g in ReviewGrade.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilledButton.tonal(
                          onPressed: () => _grade(word, g),
                          child: Text(g.label),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: FilledButton(
                onPressed: () => setState(() => _revealed = true),
                child: const Text('Show answer'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _grade(Word word, ReviewGrade grade) async {
    await ref.read(wordsRepositoryProvider).recordReview(word, grade);
    if (!mounted) return;
    setState(() {
      _reviewed++;
      _index++;
      _revealed = false;
    });
  }

  Widget _scaffold(Widget body) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: SafeArea(child: body),
    );
  }
}

class _DoneCard extends ConsumerWidget {
  const _DoneCard({required this.reviewed});
  final int reviewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            reviewed == 0 ? 'Nothing due right now 🎉' : 'Reviewed $reviewed cards 🎉',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Come back when more cards are due.'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // refresh both views so counts/ordering update
              ref.invalidate(dueWordsProvider);
              ref.invalidate(wordsProvider);
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
