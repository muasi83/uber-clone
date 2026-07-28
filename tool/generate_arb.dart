import 'dart:convert';
import 'dart:io';

void main() {
  final inventory = File('translations_inventory.txt').readAsStringSync();
  final lines = inventory.split('\n');

  final Map<String, ArbRecord> dedup = {};
  final Set<String> usedKeys = {};

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('=')) continue;
    if (trimmed.startsWith('FILE:')) continue;
    if (trimmed.startsWith('TRANSLATION')) continue;
    if (trimmed.startsWith('Instructions')) continue;
    if (RegExp(r'^\d+\.').hasMatch(trimmed)) continue;
    if (trimmed.startsWith('END OF')) continue;
    if (trimmed.startsWith('BEST PRACTICES')) continue;

    final eqIndex = trimmed.indexOf(' = ');
    if (eqIndex == -1) continue;

    final en = trimmed.substring(0, eqIndex).trim();
    final ar = trimmed.substring(eqIndex + 3).trim();

    if (en.isEmpty || ar.isEmpty) continue;
    if (en.startsWith('"') && en.endsWith('"')) continue;

    if (!dedup.containsKey(en)) {
      final key = generateKey(en, usedKeys);
      usedKeys.add(key);
      dedup[en] = ArbRecord(key, en, ar);
    }
  }

  final records = dedup.values.toList();

  writeArb(records, 'en', 'lib/l10n/app_en.arb');
  writeArb(records, 'ar', 'lib/l10n/app_ar.arb');

  print('Generated ${records.length} unique translation keys.');
}

String generateKey(String english, Set<String> used) {
  if (english == 'OK') return 'ok';
  if (english == '\$') return 'dollar';

  String cleaned = english
      .replaceAll(RegExp(r'\{[^}]+\}'), '')
      .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
      .trim();

  if (cleaned.isEmpty) {
    cleaned = english.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
  }
  if (cleaned.isEmpty) return 'key${used.length}';

  final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return 'key${used.length}';

String key = words[0].toLowerCase();
for (int i = 1; i < words.length; i++) {
  key += words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
}

// Ensure key doesn't start with a digit
if (key.isNotEmpty && RegExp(r'^[0-9]').hasMatch(key)) {
  key = 'n$key';
}

  if (key.length > 80) key = key.substring(0, 80);

  // Avoid Dart keywords
  const keywords = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
    'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
    'factory', 'false', 'final', 'finally', 'for', 'function', 'get', 'hide',
    'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'rethrow', 'return',
    'set', 'show', 'static', 'super', 'switch', 'sync', 'this', 'throw',
    'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',
  };
  if (keywords.contains(key)) {
    key = '${key}Text';
  }

  if (!used.contains(key)) return key;

  int counter = 2;
  while (used.contains('$key$counter')) {
    counter++;
  }
  return '$key$counter';
}

class ArbRecord {
  final String key;
  final String en;
  final String ar;
  ArbRecord(this.key, this.en, this.ar);
}

List<String> placeholders(String text) {
  return RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toList();
}

void writeArb(List<ArbRecord> records, String locale, String path) {
  final root = <String, dynamic>{};
  root['\$\$locale'] = locale;

  for (final rec in records) {
    final text = locale == 'en' ? rec.en : rec.ar;
    root[rec.key] = text;

    final phs = placeholders(text);
    if (phs.isNotEmpty) {
      final meta = <String, dynamic>{};
      final phMap = <String, dynamic>{};
      for (final ph in phs) {
        phMap[ph] = {'type': 'String'};
      }
      meta['placeholders'] = phMap;
      root['@${rec.key}'] = meta;
    }
  }

  final encoder = JsonEncoder.withIndent('  ');
  File(path).writeAsStringSync('${encoder.convert(root)}\n');
}
