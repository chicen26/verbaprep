import 'dart:convert';

import 'package:http/http.dart' as http;

/// Auto-enrichment for a captured word: definition, part of speech, example.
/// Ported from the original WordExport logic — dictionaryapi.dev first, then
/// Wiktionary as a fallback for rarer/academic words. Best-effort: any failure
/// (network, CORS on web, word not found) just returns empty fields.
class Enrichment {
  final String? definition;
  final String? partOfSpeech;
  final String? example;
  const Enrichment({this.definition, this.partOfSpeech, this.example});
  bool get isEmpty => definition == null;
  static const empty = Enrichment();
}

class Dictionary {
  static const _dictApi = 'https://api.dictionaryapi.dev/api/v2/entries/en/';
  static const _wiktionary =
      'https://en.wiktionary.org/api/rest_v1/page/definition/';

  static Future<Enrichment> lookup(String word) async {
    final w = word.trim().toLowerCase();
    if (w.isEmpty) return Enrichment.empty;
    final primary = await _dictionaryApi(w);
    if (primary.definition != null) return primary;
    return _wiktionaryLookup(w);
  }

  static Future<Enrichment> _dictionaryApi(String word) async {
    try {
      final res = await http
          .get(Uri.parse('$_dictApi${Uri.encodeComponent(word)}'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return Enrichment.empty;
      final data = jsonDecode(res.body);
      if (data is! List || data.isEmpty) return Enrichment.empty;
      final meanings = (data[0]['meanings'] as List?) ?? const [];
      if (meanings.isEmpty) return Enrichment.empty;
      final meaning = meanings[0];
      final defs = (meaning['definitions'] as List?) ?? const [];
      if (defs.isEmpty) return Enrichment.empty;
      final def = (defs[0]['definition'] as String?)?.trim();
      if (def == null || def.isEmpty) return Enrichment.empty;
      return Enrichment(
        definition: def,
        partOfSpeech: (meaning['partOfSpeech'] as String?)?.toLowerCase(),
        example: (defs[0]['example'] as String?)?.trim(),
      );
    } catch (_) {
      return Enrichment.empty;
    }
  }

  static Future<Enrichment> _wiktionaryLookup(String word) async {
    try {
      final res = await http.get(
        Uri.parse('$_wiktionary${Uri.encodeComponent(word)}'),
        headers: {'User-Agent': 'VerbaPrep/1.0'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return Enrichment.empty;
      final data = jsonDecode(res.body);
      final en = (data is Map ? data['en'] : null) as List?;
      if (en == null) return Enrichment.empty;
      for (final group in en) {
        final defs = (group['definitions'] as List?) ?? const [];
        for (final d in defs) {
          final raw = (d['definition'] as String?) ?? '';
          final clean = _stripHtml(raw).trim();
          if (clean.isNotEmpty) {
            return Enrichment(
              definition: clean,
              partOfSpeech: (group['partOfSpeech'] as String?)?.toLowerCase(),
            );
          }
        }
      }
      return Enrichment.empty;
    } catch (_) {
      return Enrichment.empty;
    }
  }

  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&quot;', '"');
}
