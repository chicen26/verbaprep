import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';
import '../data/sat_repository.dart';
import '../models/sat_question.dart';

/// A module-adaptive R&W mock: Module 1 (mixed), then Module 2 routed harder or
/// easier by Module-1 performance — mirroring the real digital SAT structure.
/// Each module is timed; answers are recorded as one mock sitting.
class MockScreen extends ConsumerStatefulWidget {
  const MockScreen({super.key});

  @override
  ConsumerState<MockScreen> createState() => _MockScreenState();
}

enum _Phase { loading, error, module1, module2, done }

class _MockScreenState extends ConsumerState<MockScreen> {
  final _rng = Random();
  late final String _mockId = _uuid4(_rng);
  _Phase _phase = _Phase.loading;
  String? _error;

  List<SatQuestion> _pool = [];
  int _size = 0; // questions per module
  List<SatQuestion> _module1 = [];
  List<SatQuestion> _module2 = [];
  final _answers = <MockAnswer>[];

  List<SatQuestion> _current = [];
  int _index = 0;
  int? _chosen;
  Timer? _timer;
  int _secondsLeft = 0;

  /// Seconds per module — scaled to module size (the SAT is ~71s/question).
  int get _moduleSeconds => _size * 71;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final pool = await ref.read(satRepositoryProvider).fetchPool();
      if (pool.length < 4) {
        setState(() {
          _error =
              'Not enough questions for a mock yet (need at least 4). The daily coach is adding more.';
          _phase = _Phase.error;
        });
        return;
      }
      // No repeats across modules: each module gets up to 27, bounded by half the bank.
      final size = min(27, pool.length ~/ 2);
      final shuffled = [...pool]..shuffle(_rng);
      setState(() {
        _pool = pool;
        _size = size;
        _module1 = shuffled.take(size).toList();
      });
      _startModule(_Phase.module1, _module1);
    } catch (e) {
      setState(() {
        _error = '$e';
        _phase = _Phase.error;
      });
    }
  }

  void _startModule(_Phase phase, List<SatQuestion> questions) {
    _timer?.cancel();
    setState(() {
      _phase = phase;
      _current = questions;
      _index = 0;
      _chosen = null;
      _secondsLeft = _moduleSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _endModule();
    });
  }

  void _select(int i) => setState(() => _chosen = i);

  void _advance() {
    final q = _current[_index];
    _answers.add(MockAnswer(q, _chosen ?? -1, _phase == _Phase.module1 ? 1 : 2));
    if (_index + 1 >= _current.length) {
      _endModule();
    } else {
      setState(() {
        _index++;
        _chosen = null;
      });
    }
  }

  void _endModule() {
    _timer?.cancel();
    if (_phase == _Phase.module1) {
      // Route module 2 by module-1 accuracy (hard set unlocks the top scores).
      final m1 = _answers.where((a) => a.moduleNo == 1);
      final correct = m1.where((a) => a.correct).length;
      final acc = m1.isEmpty ? 0.0 : correct / m1.length;
      final seen = _module1.map((q) => q.id).toSet();
      final remaining = _pool.where((q) => !seen.contains(q.id)).toList();
      final hard = acc >= 0.7;
      remaining.sort((a, b) => hard
          ? b.difficulty.compareTo(a.difficulty)
          : a.difficulty.compareTo(b.difficulty));
      _module2 = remaining.take(_size).toList()..shuffle(_rng);
      _startModule(_Phase.module2, _module2);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    setState(() => _phase = _Phase.done);
    try {
      await ref
          .read(satRepositoryProvider)
          .recordMockAttempts(_mockId, _answers);
      ref.invalidate(analyticsProvider);
    } catch (_) {/* keep the results visible even if the write fails */}
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.loading:
        return _scaffold('Mock', const Center(child: CircularProgressIndicator()));
      case _Phase.error:
        return _scaffold('Mock',
            Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!))));
      case _Phase.done:
        return _scaffold('Results', _results());
      case _Phase.module1:
      case _Phase.module2:
        return _question();
    }
  }

  Widget _question() {
    final q = _current[_index];
    final moduleNo = _phase == _Phase.module1 ? 1 : 2;
    final mins = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsLeft % 60).toString().padLeft(2, '0');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Module $moduleNo · ${_index + 1}/${_current.length}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('$mins:$secs',
                  style: TextStyle(
                      color: _secondsLeft < 60 ? scheme.error : null,
                      fontFeatures: const [],
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / _current.length),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (q.passage2 != null) ...[
                    _block('Text 1', q.passage),
                    const SizedBox(height: 8),
                    _block('Text 2', q.passage2!),
                  ] else
                    _block(q.stimulusKind == 'notes' ? 'Notes' : null, q.passage),
                  const SizedBox(height: 16),
                  Text(q.stem,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  for (var i = 0; i < q.choices.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        color: _chosen == i
                            ? scheme.primaryContainer
                            : scheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: _chosen == i
                                  ? scheme.primary
                                  : scheme.outlineVariant),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _select(i),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${String.fromCharCode(65 + i)}.',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(q.choices[i])),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _advance, // allow skipping (records as blank)
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _chosen == null ? null : _advance,
                    child: Text(_index + 1 >= _current.length
                        ? 'Finish module'
                        : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    final m1 = _answers.where((a) => a.moduleNo == 1).toList();
    final m2 = _answers.where((a) => a.moduleNo == 2).toList();
    final c1 = m1.where((a) => a.correct).length;
    final c2 = m2.where((a) => a.correct).length;
    final total = _answers.length;
    final correct = c1 + c2;
    final hardModule = m1.isNotEmpty && c1 / m1.length >= 0.7;
    final score = _projectScore(correct, total, hardModule);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Text('Estimated R&W',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('$score',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(hardModule
                  ? 'Routed into the harder Module 2 ✓'
                  : 'Routed into the easier Module 2'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ListTile(
          title: const Text('Module 1'),
          trailing: Text('$c1 / ${m1.length}'),
        ),
        ListTile(
          title: const Text('Module 2'),
          trailing: Text('$c2 / ${m2.length}'),
        ),
        const Divider(),
        ListTile(
          title: const Text('Total correct'),
          trailing: Text('$correct / $total'),
        ),
        const SizedBox(height: 12),
        Text(
          'Estimate only — the real digital SAT uses form-specific (IRT) scoring with no published conversion table. Reaching 790–800 means the hard Module 2 with ~0–2 misses.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  /// Rough projection: accuracy → band, capped lower if the easy module was served.
  int _projectScore(int correct, int total, bool hardModule) {
    if (total == 0) return 200;
    final acc = correct / total;
    if (hardModule) {
      return (520 + acc * 280).round().clamp(200, 800);
    }
    return (400 + acc * 230).round().clamp(200, 630);
  }

  Widget _block(String? label, String text) {
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
            Text(label,
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

  Widget _scaffold(String title, Widget body) =>
      Scaffold(appBar: AppBar(title: Text(title)), body: SafeArea(child: body));
}

/// Minimal RFC-4122 v4 UUID (mock_id is a uuid column).
String _uuid4(Random rng) {
  final b = List<int>.generate(16, (_) => rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final s = List.generate(16, hex).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-'
      '${s.substring(16, 20)}-${s.substring(20)}';
}
