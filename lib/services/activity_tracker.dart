import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class ActivityTracker {
  static const String _keyAppOpenCount = "app_open_count";
  static const String _keyLastLoginDate = "last_login_date";
  static const String _keySubAddedCount = "sub_added_count";

  // --- Detailed AI Tracking ---
  static Future<void> logAction(String actionType, String description) async {
    await DBService.instance.insertActivityLog(actionType, description);
  }

  static Future<List<Map<String, dynamic>>> getDetailedLogs({int limit = 50}) async {
    return await DBService.instance.getRecentActivityLogs(limit: limit);
  }
  // ----------------------------

  static Future<void> logAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    
    int openCount = prefs.getInt(_keyAppOpenCount) ?? 0;
    await prefs.setInt(_keyAppOpenCount, openCount + 1);

    await prefs.setString(_keyLastLoginDate, DateTime.now().toIso8601String());
    
    // Ayrıca veritabanına logla
    await logAction("Uygulama Girişi", "Kullanıcı uygulamayı açtı. (Toplam $openCount kere)");
  }

  static Future<void> logSubAdded(String subName, double price) async {
    final prefs = await SharedPreferences.getInstance();
    int addedCount = prefs.getInt(_keySubAddedCount) ?? 0;
    await prefs.setInt(_keySubAddedCount, addedCount + 1);
    
    await logAction("Abonelik Eklendi", "Kullanıcı '$subName' aboneliğini ekledi (Fiyat: $price)");
  }

  static Future<Map<String, dynamic>> getActivityStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "appOpenCount": prefs.getInt(_keyAppOpenCount) ?? 0,
      "lastLoginDate": prefs.getString(_keyLastLoginDate) ?? "Bilinmiyor",
      "subAddedCount": prefs.getInt(_keySubAddedCount) ?? 0,
    };
  }
}
