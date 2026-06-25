import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/words_repository.dart';
import '../models/word.dart';
import 'review_screen.dart';

/// The home screen: the user's vocabulary, with sort + search.
class WordListScreen extends ConsumerWidget {
  const WordListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsProvider);
    final sort = ref.watch(wordSortProvider);
    final query = ref.watch(wordSearchProvider).trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Words'),
        actions: [
          PopupMenuButton<WordSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: sort,
            onSelected: (s) =>
                ref.read(wordSortProvider.notifier).state = s,
            itemBuilder: (_) => [
              for (final s in WordSort.values)
                PopupMenuItem(value: s, child: Text(s.label)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add word'),
      ),
      body: Column(
        children: [
          const _ReviewBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search words or definitions',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(wordSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: wordsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load words:\n$e',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (words) {
                var visible = words;
                if (query.isNotEmpty) {
                  visible = visible
                      .where((w) =>
                          w.word.toLowerCase().contains(query) ||
                          (w.definition ?? '')
                              .toLowerCase()
                              .contains(query))
                      .toList();
                }
                visible = sortWords(visible, sort);

                if (visible.isEmpty) {
                  return const Center(
                    child: Text('No words yet. Tap “Add word” to start.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(wordsProvider),
                  child: ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _WordTile(visible[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final wordCtrl = TextEditingController();
    final defCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a word'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Word'),
            ),
            TextField(
              controller: defCtrl,
              decoration: const InputDecoration(labelText: 'Definition (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && wordCtrl.text.trim().isNotEmpty) {
      await ref.read(wordsRepositoryProvider).add(
            word: wordCtrl.text,
            definition: defCtrl.text.trim().isEmpty ? null : defCtrl.text.trim(),
          );
      ref.invalidate(wordsProvider);
    }
  }
}

/// A tappable banner showing how many cards are due, linking to the review session.
class _ReviewBanner extends ConsumerWidget {
  const _ReviewBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCount = ref.watch(dueWordsProvider).maybeWhen(
          data: (w) => w.length,
          orElse: () => 0,
        );
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: dueCount > 0 ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      child: InkWell(
        onTap: dueCount == 0
            ? null
            : () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReviewScreen()),
                );
                ref.invalidate(dueWordsProvider);
                ref.invalidate(wordsProvider);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.school,
                  color: dueCount > 0 ? scheme.onPrimaryContainer : null),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dueCount > 0
                      ? '$dueCount card${dueCount == 1 ? '' : 's'} due for review'
                      : 'No cards due — you’re all caught up',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: dueCount > 0 ? scheme.onPrimaryContainer : null,
                  ),
                ),
              ),
              if (dueCount > 0)
                Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordTile extends ConsumerWidget {
  const _WordTile(this.word);
  final Word word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = word.dueAt.isBefore(DateTime.now());
    return ListTile(
      title: Row(
        children: [
          Text(word.word,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (word.partOfSpeech != null) ...[
            const SizedBox(width: 6),
            Text('(${word.partOfSpeech})',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      subtitle: word.definition == null
          ? null
          : Text(word.definition!, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(word.starred ? Icons.star : Icons.star_border,
                color: word.starred ? Colors.amber : null),
            onPressed: () async {
              await ref
                  .read(wordsRepositoryProvider)
                  .setStarred(word.id, !word.starred);
              ref.invalidate(wordsProvider);
            },
          ),
          Text(
            due ? 'due' : DateFormat.MMMd().format(word.createdAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: due ? Theme.of(context).colorScheme.error : null,
                ),
          ),
        ],
      ),
    );
  }
}
