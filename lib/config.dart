/// Supabase connection config.
///
/// Fill these in from your Supabase project: Settings → API.
/// (The anon key is safe to ship in a client app — Row-Level Security is what
/// protects the data, see supabase/migrations/0001_init.sql.)
///
/// You can also pass them at run time without editing this file:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class Config {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gnhxawfzklblrzoyqmbo.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImduaHhhd2Z6a2xibHJ6b3lxbWJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzNTM5OTIsImV4cCI6MjA5NzkyOTk5Mn0.g9B1WETObaleldi8EWi7-GpphqgbJt2GPxsS-ezoe2A',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
