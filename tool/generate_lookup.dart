import 'dart:convert';
import 'dart:io';

void main() {
  final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
  
  final lookup = <String, String>{};
  for (final entry in arb.entries) {
    final key = entry.key;
    if (key.startsWith('@') || key == '\$\$locale') continue;
    final value = entry.value as String;
    // Normalize for lookup
    final normalized = value.trim();
    if (!lookup.containsKey(normalized)) {
      lookup[normalized] = key;
    }
  }

  final buffer = StringBuffer();
  buffer.writeln('// Auto-generated lookup map from English text to ARB key');
  buffer.writeln('// Generated on ${DateTime.now()}');
  buffer.writeln('const Map<String, String> englishToArbKey = {');
  
  final entries = lookup.entries.toList();
  entries.sort((a, b) => a.key.compareTo(b.key));
  
  for (int i = 0; i < entries.length; i++) {
    final e = entries[i];
    final escaped = e.key
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n');
    buffer.write("  '$escaped': '${e.value}'");
    if (i < entries.length - 1) buffer.writeln(',');
    else buffer.writeln();
  }
  
  buffer.writeln('};');
  buffer.writeln();
  buffer.writeln('String? arbKeyFor(String text) => englishToArbKey[text.trim()];');
  
  File('lib/l10n/lookup_map.dart').writeAsStringSync(buffer.toString());
  print('Lookup map written to lib/l10n/lookup_map.dart with ${lookup.length} entries.');
}
