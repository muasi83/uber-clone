import 'package:flutter/services.dart';

class MapStyleLoader {
  static String? _cachedStyle;

  static String? get cachedStyle => _cachedStyle;

  static Future<String?> load() async {
    if (_cachedStyle != null) return _cachedStyle;
    try {
      _cachedStyle = await rootBundle.loadString('assets/map_style.json');
      return _cachedStyle;
    } catch (_) {
      return null;
    }
  }

  static void clearCache() {
    _cachedStyle = null;
  }
}
