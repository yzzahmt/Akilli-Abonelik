import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isTemporary = false;
  bool _isPermanent = false;

  @override
  bool build() {
    _loadPermanentPremium();
    return _isTemporary || _isPermanent;
  }

  Future<void> _loadPermanentPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPermanent = prefs.getBool('is_permanent_premium') ?? false;
      state = _isTemporary || _isPermanent;
    } catch (_) {}
  }

  Future<void> togglePermanentPremium(bool value) async {
    _isPermanent = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_permanent_premium', value);
    } catch (_) {}
    state = _isTemporary || _isPermanent;
  }

  void setTemporaryPremium(bool value) {
    _isTemporary = value;
    state = _isTemporary || _isPermanent;
  }

  void togglePremium(bool value) {
    _isTemporary = value;
    state = _isTemporary || _isPermanent;
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
