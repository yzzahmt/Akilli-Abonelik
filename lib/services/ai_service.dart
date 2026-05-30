import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subscription.dart';
import '../models/investment_model.dart';
import '../models/cash_account_model.dart';

class AIService {
  // Gizli Backend AI Motoru (SubsTrack AI)
  static const String _aiApiKey = "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";

  static Future<String> chatWithAI({
    required List<Map<String, String>> messages,
    required List<Subscription> subscriptions,
    required List<Investment> investments,
    required List<CashAccount> cashAccounts,
    required String lang,
  }) async {
    final double totalMonthlyTL = subscriptions.fold(0, (sum, sub) {
      double price = (sub.currency == 'TL') ? sub.price : (sub.price * 34.5);
      if (sub.billingCycle == 'Yıllık') {
        price /= 12;
      } else if (sub.billingCycle == '6 Aylık') {
        price /= 6;
      } else if (sub.billingCycle == '3 Aylık') {
        price /= 3;
      } else if (sub.billingCycle == '2 Haftada Bir') {
        price = (price / 14) * 30;
      } else if (sub.billingCycle == 'Haftalık') {
        price = (price / 7) * 30;
      }
      return sum + price;
    });

    final subsText = subscriptions.isEmpty 
        ? "Aktif abonelik bulunmuyor." 
        : subscriptions.map((s) => '- ${s.name}: ${s.price} ${s.currency} (Kategori: ${s.category}, Yenilenme: ${s.billingCycle})').join('\n');

    final invText = investments.isEmpty 
        ? "Aktif yatırım bulunmuyor." 
        : investments.map((i) => '- ${i.symbol} (${i.type}): ${i.quantity} adet, Ortalama Maliyet: ${i.buyPrice} ${i.currency}, Güncel Fiyat: ${i.currentPrice ?? "Bilinmiyor"} ${i.currency}').join('\n');

    final cashText = cashAccounts.isEmpty
        ? "Boşta nakit bulunmuyor."
        : cashAccounts.map((c) => '- ${c.name}: ${c.amount} ${c.currency}').join('\n');

    final promptRule = (lang == 'EN') 
        ? 'You must speak ONLY in English. All your responses must be strictly in English.'
        : 'Sadece Türkçe konuşacaksın. Tüm cevapların tamamen Türkçe olmalı.';

    final systemPrompt = '''
Sen Wall Street seviyesinde stratejiler geliştiren, son derece zeki, analitik ve kapsamlı bir Yapay Zeka Finans Danışmanısın (SubsTrack AI). $promptRule
Senin görevin kullanıcının kişisel finansını, aboneliklerini, yatırımlarını ve boşta duran nakit varlıklarını mükemmel bir şekilde yönetmesini sağlamak, bütçe optimizasyonu yapmak ve enflasyona karşı koruyucu derinlemesine projeksiyonlar sunmaktır.

KULLANICI VERİLERİ (GÜNCEL):
- Aylık Abonelik Gideri (Tahmini): ₺${totalMonthlyTL.toStringAsFixed(2)}
- Mevcut Abonelikleri:
$subsText
- Mevcut Yatırımları (Hisse, Kripto vb.):
$invText
- Bankadaki / Boşta Duran Nakitleri:
$cashText

GELİŞMİŞ TAVSİYE VE DAVRANIŞ KURALLARI:
1. Sen sıradan bir asistan değilsin; kullanıcının zenginleşmesini sağlayan bir uzmansın. Detaylı, adım adım ve vizyoner cevaplar ver.
2. Matematiksel bir hesaplama istendiğinde (örn. "aboneliklerime %30 zam gelirse", "yılda ne kadar biriktiririm") verileri kullanarak son derece detaylı bir tablo veya döküm oluştur. Yuvarlama yapma, kesin ve açıklayıcı ol.
3. Kullanıcıya harcamalarını kısması veya yatırımlarını çeşitlendirmesi için akıllı taktikler (Örn: 50/30/20 kuralı, bileşik getiri) sun.
4. Eğer kullanıcı finans, bütçe, yatırım veya harcama/tasarruf (öneri kartları dahil) dışında alakasız veya bilinmeyen bir şey sorarsa SADECE şu cevabı ver: "Ne dediğinizi anlayamadım." (Başka hiçbir açıklama yapma).
5. Eğer kullanıcı iletişim, destek, yapımcı, şikayet, öneri veya yardım almak ile ilgili bir şey sorarsa şu cevabı ver: "Destek ve iletişim için yazify.net adresini ziyaret edebilir veya yzz_software@hotmail.com adresine e-posta gönderebilirsiniz."
6. Yatırım tavsiyesi verirken mutlaka sonuna ufak bir YTD (Yatırım Tavsiyesi Değildir) notu düş.
7. Cevaplarını zenginleştir: Madde işaretleri, kalın yazılar (bold) ve dikkat çekici başlıklar kullanarak şık, okunması zevkli bir formatta sun.
''';

    final List<Map<String, dynamic>> formattedMessages = [
      {"role": "system", "content": systemPrompt}
    ];

    for (var msg in messages) {
      final textContent = msg["text"] ?? msg["content"] ?? "";
      if (msg["role"] == "user") {
        formattedMessages.add({"role": "user", "content": textContent});
      } else if (msg["role"] == "ai" && msg != messages.first) {
        formattedMessages.add({"role": "assistant", "content": textContent});
      }
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_aiApiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": formattedMessages,
          // Removed response_format to prevent 400 errors for standard chat
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        return (lang == 'EN') ? 'SubsTrack AI Servers are currently busy. Please try again later.' : 'SubsTrack AI Sunucuları şu anda yoğun. Lütfen birazdan tekrar deneyin.';
      }
    } catch (e) {
      return (lang == 'EN') ? 'Connection error: Please check your internet connection.' : 'Bağlantı hatası: Lütfen internetinizi kontrol edin.';
    }
  }

  // --- Detailed Financial Dashboard AI ---
  static Future<Map<String, dynamic>?> getFinancialSummaryAndInsights({
    required List<Subscription> subscriptions,
    required List<Investment> investments,
    required List<CashAccount> cashAccounts,
    required List<Map<String, dynamic>> recentLogs,
    required String lang,
  }) async {
    final double totalMonthlyTL = subscriptions.fold(0, (sum, sub) {
      double price = (sub.currency == 'TL') ? sub.price : (sub.price * 34.5);
      if (sub.billingCycle == 'Yıllık') {
        price /= 12;
      } else if (sub.billingCycle == '6 Aylık') {
        price /= 6;
      } else if (sub.billingCycle == '3 Aylık') {
        price /= 3;
      } else if (sub.billingCycle == '2 Haftada Bir') {
        price = (price / 14) * 30;
      } else if (sub.billingCycle == 'Haftalık') {
        price = (price / 7) * 30;
      }
      return sum + price;
    });

    final subsText = subscriptions.isEmpty ? "Yok" : subscriptions.map((s) => '- ${s.name}: ${s.price} ${s.currency}').join('\n');
    final invText = investments.isEmpty ? "Yok" : investments.map((i) => '- ${i.symbol}: ${i.quantity} adet, Maliyet: ${i.buyPrice} ${i.currency}').join('\n');
    final cashText = cashAccounts.isEmpty ? "Yok" : cashAccounts.map((c) => '- ${c.name}: ${c.amount} ${c.currency}').join('\n');
    final logsText = recentLogs.isEmpty ? "Hareket yok" : recentLogs.map((l) => '[${l['timestamp']}] ${l['action_type']}: ${l['description']}').join('\n');

    final promptRule = (lang == 'EN') 
        ? 'You must respond ONLY in English.'
        : 'Sadece Türkçe konuşacaksın.';

    final prompt = '''
Sen SubsTrack AI'sın. Kullanıcının tüm aboneliklerini, yatırımlarını, nakit varlıklarını ve SON EYLEMLERİNİ (Loglar) analiz edip, STRICT JSON formatında bir finansal özet çıkaracaksın. ASLA JSON DIŞINDA BİR YORUM EKLEME. $promptRule

KULLANICI VERİLERİ:
- Aylık Abonelik Gideri: ₺${totalMonthlyTL.toStringAsFixed(2)}
- Abonelikler:\n$subsText
- Yatırımlar:\n$invText
- Banka / Nakit Varlıklar:\n$cashText
- Son Eylemleri (Finansal Günlük):\n$logsText

Senden KESİNLİKLE şu JSON formatını dönmeni istiyorum:
{
  "genel_ozet": "Kullanıcının son durumunu ve hareketlerini anlatan şık bir özet.",
  "tavsiye": "Son eylemlere ve harcamalara dayalı spesifik finansal/tasarruf tavsiyesi.",
  "gelecek_tahmini_1_yil": "1 yıl sonraki tahmini varlık / gider projeksiyonu.",
  "dikkat_ceken_nokta": "Sistemde fark ettiğin en kritik durum (ör: x aboneliği çok pahalı, y yatırımı yeni eklendi vb.)"
}
''';

    final messages = [
      {"role": "user", "content": prompt}
    ];

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_aiApiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": messages,
          // Removing JSON mode natively to avoid 400, strictly requesting it via prompt instead
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String jsonResponse = data['choices'][0]['message']['content'];
        
        // Clean markdown block if necessary
        jsonResponse = jsonResponse.replaceAll('```json', '').replaceAll('```', '').trim();
        
        try {
          return jsonDecode(jsonResponse) as Map<String, dynamic>;
        } catch (e) {
          // Fallback if parsing fails
          return {
            "genel_ozet": "Analiz tamamlandı.",
            "tavsiye": jsonResponse,
            "gelecek_tahmini_1_yil": "-",
            "dikkat_ceken_nokta": "Sistem geçici olarak detaylı analizi ayrıştıramadı."
          };
        }
      }
    } catch (e) {
      // Ignored
    }
    return null;
  }
}
