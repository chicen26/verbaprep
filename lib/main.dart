import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Config.isConfigured) {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      anonKey: Config.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: VerbaPrepApp()));
}

class VerbaPrepApp extends StatelessWidget {
  const VerbaPrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VerbaPrep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3D5AFE),
        useMaterial3: true,
      ),
      home: Config.isConfigured ? const _Root() : const _ConfigNeeded(),
    );
  }
}

/// Routes between the auth screen and the app based on the Supabase session.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const AuthScreen();
        return const HomeShell();
      },
    );
  }
}

/// Shown until SUPABASE_URL / SUPABASE_ANON_KEY are provided (see config.dart).
class _ConfigNeeded extends StatelessWidget {
  const _ConfigNeeded();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.key_off, size: 48),
              const SizedBox(height: 16),
              Text('Supabase not configured',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Add your Project URL and anon key in lib/config.dart, or pass '
                'them with --dart-define when running.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
