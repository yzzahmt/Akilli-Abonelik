// SubsTrack yeni özellik — Yatırım servisi (Bölüm 7)
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class InvestmentService {
  static const _baseUrl =
      'https://query2.finance.yahoo.com/v8/finance/chart';

  // Anlık fiyat çek — Yahoo Finance
  static Future<double?> fetchCurrentPrice(String symbol) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/$symbol?interval=1d&range=1d');
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result =
            json['chart']?['result']?[0];
        if (result == null) return null;

        // Güncel kapanış fiyatı
        final meta = result['meta'];
        final price = meta?['regularMarketPrice'] as num?;
        return price?.toDouble();
      }
    } catch (e) {
      debugPrint('InvestmentService fetchCurrentPrice error: $e');
    }
    return null;
  }

  // Döviz kuru çek (USDTRY=X)
  static Future<double?> fetchUsdToTry() async {
    return await fetchCurrentPrice('USDTRY=X');
  }

  // EUR/TRY kuru
  static Future<double?> fetchEurToTry() async {
    return await fetchCurrentPrice('EURTRY=X');
  }

  // Sembol önerileri (tip bazlı)
  static List<Map<String, String>> getSuggestedSymbols(String type) {
    switch (type) {
      case 'stock':
        return [
          {'name': 'Türk Hava Yolları', 'symbol': 'THYAO.IS'},
          {'name': 'Garanti BBVA', 'symbol': 'GARAN.IS'},
          {'name': 'Türkiye Petrol Rafinerileri', 'symbol': 'TUPRS.IS'},
          {'name': 'BIM Birleşik Mağazalar', 'symbol': 'BIMAS.IS'},
          {'name': 'Ereğli Demir Çelik', 'symbol': 'EREGL.IS'},
          {'name': 'Apple', 'symbol': 'AAPL'},
          {'name': 'Tesla', 'symbol': 'TSLA'},
          {'name': 'Microsoft', 'symbol': 'MSFT'},
        ];
      case 'crypto':
        return [
          {'name': 'Bitcoin', 'symbol': 'BTC-USD'},
          {'name': 'Ethereum', 'symbol': 'ETH-USD'},
          {'name': 'Solana', 'symbol': 'SOL-USD'},
          {'name': 'BNB', 'symbol': 'BNB-USD'},
          {'name': 'Ripple', 'symbol': 'XRP-USD'},
        ];
      case 'gold':
        return [
          {'name': 'Altın (Ons)', 'symbol': 'GC=F'},
          {'name': 'Gümüş (Ons)', 'symbol': 'SI=F'},
        ];
      case 'currency':
        return [
          {'name': 'Dolar (USD/TRY)', 'symbol': 'USDTRY=X'},
          {'name': 'Euro (EUR/TRY)', 'symbol': 'EURTRY=X'},
          {'name': 'Sterlin (GBP/TRY)', 'symbol': 'GBPTRY=X'},
          {'name': 'İsviçre Frangı (CHF/TRY)', 'symbol': 'CHFTRY=X'},
        ];
      default:
        return [];
    }
  }
}
