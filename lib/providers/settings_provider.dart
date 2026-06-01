import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/purchase_service.dart';

class SettingsNotifier extends Notifier<String> {
  @override
  String build() {
    return 'Tümü';
  }

  void setCategory(String category) {
    state = category;
  }
}

final categoryFilterProvider = NotifierProvider<SettingsNotifier, String>(() {
  return SettingsNotifier();
});

class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    // PurchaseService'ten gelen değişiklikleri dinle
    _syncWithPurchaseService();
    return PurchaseService.instance.isPremium.value;
  }

  void _syncWithPurchaseService() {
    PurchaseService.instance.isPremium.addListener(() {
      state = PurchaseService.instance.isPremium.value;
    });
  }

  /// Google Play satın alma ile premium aktif et (kalıcı)
  Future<void> togglePermanentPremium(bool value) async {
    await PurchaseService.instance.savePremium(value);
    state = value;
  }

  /// Geçici premium (reklam izleyerek — oturum süresince)
  void togglePremium(bool value) {
    if (!PurchaseService.instance.isPremium.value) {
      state = value;
    }
  }
}

final isPremiumProvider = NotifierProvider<PremiumNotifier, bool>(() {
  return PremiumNotifier();
});

class SpendingLimitNotifier extends Notifier<double> {
  @override
  double build() {
    return 0.0; // 0 means no limit
  }

  void setLimit(double limit) {
    state = limit;
  }
}

final spendingLimitProvider = NotifierProvider<SpendingLimitNotifier, double>(() {
  return SpendingLimitNotifier();
});

class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    _loadLanguage();
    return 'TR';
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getString('app_language') ?? 'TR';
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
    } catch (_) {}
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});
