import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

enum Currency { usd, sar, syp }

class CurrencyService {
  static const _key = 'preferred_currency';
  static const _symbols = {Currency.usd: '\$', Currency.sar: 'SAR', Currency.syp: 'SYP'};
  static const _rates = {Currency.usd: 1.0, Currency.sar: 3.75, Currency.syp: 13000.0};

  static Currency _preferred = Currency.usd;

  static Currency get preferred => _preferred;
  static String get symbol => _symbols[_preferred]!;
  static double get rate => _rates[_preferred]!;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key) ?? 'usd';
      _preferred = Currency.values.firstWhere(
        (c) => c.name == raw,
        orElse: () => Currency.usd,
      );
    } catch (_) {
      _preferred = Currency.usd;
    }
  }

  static Future<void> setCurrency(Currency c) async {
    _preferred = c;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, c.name);
    } catch (_) {}
  }

  static double convert(num usdAmount) => usdAmount.toDouble() * rate;

  static String format(num usdAmount) {
    final converted = convert(usdAmount);
    if (_preferred == Currency.syp) {
      return 'SYP ${NumberFormat('#,##0.00', 'en_US').format(converted)}';
    }
    if (symbol == 'SAR') {
      return 'SAR ${converted.toStringAsFixed(2)}';
    }
    return '\$${converted.toStringAsFixed(2)}';
  }
}
