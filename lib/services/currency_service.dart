import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class CurrencyService {
  static const String _url = 'https://open.er-api.com/v6/latest/USD';

  static Future<double> getUSDToTRYRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check cache for 6 hours validity
      final lastFetched = prefs.getInt('rates_timestamp') ?? 0;
      final cachedRate = prefs.getDouble('usd_try_rate');

      final now = DateTime.now().millisecondsSinceEpoch;

      if (cachedRate != null && (now - lastFetched) < (6 * 60 * 60 * 1000)) {
        return cachedRate;
      }

      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>;
          if (rates.containsKey('TRY')) {
            final double rate = (rates['TRY'] as num).toDouble();

            await prefs.setDouble('usd_try_rate', rate);
            await prefs.setInt('rates_timestamp', now);

            await DBService.instance.updateRates({'TRY': 1.0, 'USD': rate});
            return rate;
          }
        }
      }
    } catch (_) {
      // Ignore for production fallback
    }

    // Fallback to SQLite DB or defaults
    final storedRates = await DBService.instance.getRates();
    return storedRates['USD'] ?? 32.50;
  }
}
