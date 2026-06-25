import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/capture.dart';
import '../data/words_repository.dart';
import '../widgets/guest_banner.dart';
import 'dashboard_screen.dart';
import 'sat_home_screen.dart';
import 'word_list_screen.dart';

/// Signed-in shell with bottom navigation. Also processes a word "sent" to the
/// app via a share target / shortcut / link (see data/capture.dart).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabs = [WordListScreen(), SatHomeScreen(), DashboardScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleCapture());
  }

  /// If the app was opened with a word in the URL, save it (idempotent upsert).
  Future<void> _handleCapture() async {
    final raw = pendingCapture();
    if (raw == null) return;
    final shown = raw.split(RegExp(r'\s+')).first;
    try {
      await ref
          .read(wordsRepositoryProvider)
          .add(word: raw, sourceApp: 'share');
      ref.invalidate(wordsProvider);
      ref.invalidate(dueWordsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved “$shown” to your words')),
        );
      }
    } catch (_) {/* ignore — keep the app usable */}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const GuestBanner(),
            Expanded(child: IndexedStack(index: _index, children: _tabs)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Words'),
          NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'SAT'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Progress'),
        ],
      ),
    );
  }
}
