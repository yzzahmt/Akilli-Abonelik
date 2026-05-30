// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final aiApiKey = "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";

  final List<Map<String, dynamic>> formattedMessages = [
    {"role": "system", "content": "Sen test yapan bota benziyorsun."},
    {"role": "user", "content": "Tüm aboneliklerime %30 zam gelirse aylık bütçem ne olur?"}
  ];

  try {
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $aiApiKey',
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": formattedMessages,
      }),
    );
    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");
  } catch (e) {
    print("Error: $e");
  }
}
