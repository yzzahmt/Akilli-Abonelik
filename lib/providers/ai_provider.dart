import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final aiProvider = NotifierProvider<AINotifier, String>(() {
  return AINotifier();
});

class AINotifier extends Notifier<String> {
  @override
  String build() {
    _init();
    return 'Groq';
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('ai_model') ?? 'Groq';
  }

  Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_model', model);
    state = model;
  }
}
