/// Reads a word "sent" to the app via the launch URL — used by the Android
/// PWA share target, the iOS Shortcut, and plain share links. The shared text
/// arrives as ?text= (Web Share Target / Shortcut) or ?add= (manual link).
String? pendingCapture() {
  final p = Uri.base.queryParameters;
  final raw = (p['text'] ?? p['add'] ?? p['title'])?.trim();
  if (raw == null || raw.isEmpty) return null;
  return raw;
}
