import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketService {
  static const _base = 'https://query2.finance.yahoo.com/v8/finance/chart/';

  static Future<Map<String, dynamic>> fetchQuote(String symbol) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse('$_base$symbol?interval=1m&range=1d&_t=$ts');
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json'
        },
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final json = jsonDecode(resp.body);
      final meta = json['chart']['result'][0]['meta'];
      
      double price = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
      
      try {
        final indicators = json['chart']['result'][0]['indicators']['quote'][0];
        final List<dynamic>? closes = indicators['close'];
        if (closes != null && closes.isNotEmpty) {
          for (int i = closes.length - 1; i >= 0; i--) {
            if (closes[i] != null) {
              price = (closes[i] as num).toDouble();
              break;
            }
          }
        }
      } catch (_) {}
      final prevCloseNum = meta['previousClose'] ?? meta['chartPreviousClose'] ?? price;
      final double prevClose = (prevCloseNum as num?)?.toDouble() ?? 0.0;
      
      return {
        'price': price,
        'prevClose': prevClose,
        'currency': meta['currency'] as String? ?? 'TRY',
        'change': price - prevClose,
        'changePercent': prevClose > 0 ? ((price - prevClose) / prevClose) * 100 : 0.0,
        'high': (meta['regularMarketDayHigh'] as num?)?.toDouble(),
        'low': (meta['regularMarketDayLow'] as num?)?.toDouble(),
        'volume': meta['regularMarketVolume'],
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static List<Map<String, String>> getSuggestedSymbols(String type) {
    switch (type) {
      case 'stock':
        return [
          {'name': 'Türk Hava Yolları', 'symbol': 'THYAO.IS'},
          {'name': 'Garanti BBVA', 'symbol': 'GARAN.IS'},
          {'name': 'Akbank', 'symbol': 'AKBNK.IS'},
          {'name': 'Ereğli Demir Çelik', 'symbol': 'EREGL.IS'},
          {'name': 'Şişecam', 'symbol': 'SISE.IS'},
          {'name': 'Koç Holding', 'symbol': 'KCHOL.IS'},
          {'name': 'Sabancı Holding', 'symbol': 'SAHOL.IS'},
          {'name': 'Aselsan', 'symbol': 'ASELS.IS'},
          {'name': 'BİM', 'symbol': 'BIMAS.IS'},
          {'name': 'Ford Otosan', 'symbol': 'FROTO.IS'},
          {'name': 'Tofaş', 'symbol': 'TOASO.IS'},
          {'name': 'Tüpraş', 'symbol': 'TUPRS.IS'},
          {'name': 'Petkim', 'symbol': 'PETKM.IS'},
          {'name': 'Arçelik', 'symbol': 'ARCLK.IS'},
          {'name': 'Turkcell', 'symbol': 'TCELL.IS'},
          {'name': 'Yapı Kredi', 'symbol': 'YKBNK.IS'},
          {'name': 'Halkbank', 'symbol': 'HALKB.IS'},
          {'name': 'Vakıfbank', 'symbol': 'VAKBN.IS'},
          {'name': 'İş Bankası (C)', 'symbol': 'ISCTR.IS'},
          {'name': 'Enka İnşaat', 'symbol': 'ENKAI.IS'},
          {'name': 'Apple', 'symbol': 'AAPL'},
          {'name': 'Microsoft', 'symbol': 'MSFT'},
          {'name': 'Alphabet (Google)', 'symbol': 'GOOGL'},
          {'name': 'Amazon', 'symbol': 'AMZN'},
          {'name': 'Meta', 'symbol': 'META'},
          {'name': 'Tesla', 'symbol': 'TSLA'},
          {'name': 'Nvidia', 'symbol': 'NVDA'},
          {'name': 'Berkshire Hathaway', 'symbol': 'BRK-B'},
          {'name': 'JPMorgan', 'symbol': 'JPM'},
          {'name': 'Visa', 'symbol': 'V'},
        ];
      case 'crypto':
        return [
          {'name': 'Bitcoin', 'symbol': 'BTC-USD'},
          {'name': 'Ethereum', 'symbol': 'ETH-USD'},
          {'name': 'BNB', 'symbol': 'BNB-USD'},
          {'name': 'Solana', 'symbol': 'SOL-USD'},
          {'name': 'Ripple', 'symbol': 'XRP-USD'},
          {'name': 'Cardano', 'symbol': 'ADA-USD'},
          {'name': 'Avalanche', 'symbol': 'AVAX-USD'},
          {'name': 'Polkadot', 'symbol': 'DOT-USD'},
          {'name': 'Polygon', 'symbol': 'MATIC-USD'},
          {'name': 'Chainlink', 'symbol': 'LINK-USD'},
        ];
      case 'gold':
        return [
          {'name': 'Altın / Ons', 'symbol': 'GC=F'},
          {'name': 'Gümüş / Ons', 'symbol': 'SI=F'},
          {'name': 'Ham Petrol', 'symbol': 'CL=F'},
          {'name': 'Doğalgaz', 'symbol': 'NG=F'},
          {'name': 'Bakır', 'symbol': 'HG=F'},
          {'name': 'Platin', 'symbol': 'PL=F'},
          {'name': 'Paladyum', 'symbol': 'PA=F'},
        ];
      case 'currency':
        return [
          {'name': 'Dolar (USD/TRY)', 'symbol': 'USDTRY=X'},
          {'name': 'Euro (EUR/TRY)', 'symbol': 'EURTRY=X'},
          {'name': 'Sterlin (GBP/TRY)', 'symbol': 'GBPTRY=X'},
          {'name': 'Yen (JPY/TRY)', 'symbol': 'JPYTRY=X'},
          {'name': 'İsviçre Frangı (CHF/TRY)', 'symbol': 'CHFTRY=X'},
          {'name': 'Kanada Doları (CAD/TRY)', 'symbol': 'CADTRY=X'},
          {'name': 'AUD/USD', 'symbol': 'AUDUSD=X'},
          {'name': 'EUR/USD', 'symbol': 'EURUSD=X'},
        ];
      default:
        return [];
    }
  }
}
