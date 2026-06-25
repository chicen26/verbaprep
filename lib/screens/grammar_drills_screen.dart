import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sat_repository.dart';
import 'sat_practice_screen.dart';

/// Lists the grammar rules present in the bank; tap to drill that rule.
class GrammarDrillsScreen extends ConsumerWidget {
  const GrammarDrillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(_rulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Grammar drills')),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'No grammar-tagged questions yet. The daily coach adds more over time.'),
              ),
            );
          }
          return ListView.separated(
            itemCount: rules.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final code = rules[i];
              return ListTile(
                leading: Icon(code.startsWith('BND')
                    ? Icons.format_quote
                    : Icons.spellcheck),
                title: Text(_ruleLabel(code)),
                subtitle: Text(code,
                    style: Theme.of(context).textTheme.labelSmall),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SatPracticeScreen(
                    ruleCode: code,
                    title: _ruleLabel(code),
                  ),
                )),
              );
            },
          );
        },
      ),
    );
  }
}

final _rulesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(satRepositoryProvider).distinctRules(),
);

/// Turn a rule_code like "FSS.sva_intervening" into a human label.
String _ruleLabel(String code) {
  final parts = code.split('.');
  final tail = parts.length > 1 ? parts[1] : code;
  final words = tail
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'\bsva\b'), (_) => 'subject-verb');
  final domain = code.startsWith('BND') ? 'Boundaries' : 'Form/Structure';
  return '$domain — ${words[0].toUpperCase()}${words.substring(1)}';
}
