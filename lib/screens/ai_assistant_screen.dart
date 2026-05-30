import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/subscription_provider.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/market_service.dart';
import '../constants/app_colors.dart';
import '../models/investment_model.dart';
import '../models/cash_account_model.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  List<Investment> _investments = [];
  List<CashAccount> _cashAccounts = [];

  List<String> _getSuggestedQueries(String lang) {
    return [
      AppTranslations.translate(lang, 'ai_suggestion_1'),
      AppTranslations.translate(lang, 'ai_suggestion_2'),
      AppTranslations.translate(lang, 'ai_suggestion_3'),
      AppTranslations.translate(lang, 'ai_suggestion_4'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    final lang = ref.read(languageProvider);
    _messages.add({
      'role': 'ai',
      'text': AppTranslations.translate(lang, 'ai_greeting')
    });
  }

  Future<void> _loadData() async {
    final invs = await DBService.instance.getAllInvestments();
    final cash = await DBService.instance.getAllCashAccounts();
    
    // Fetch live quotes
    for (int i = 0; i < invs.length; i++) {
      final quote = await MarketService.fetchQuote(invs[i].symbol);
      if (!quote.containsKey('error') && quote['price'] != null) {
        invs[i] = invs[i].copyWith(currentPrice: quote['price'] as double);
      }
    }
    
    if (mounted) {
      setState(() {
        _investments = invs;
        _cashAccounts = cash;
      });
    }
  }

  void _sendMessage(String text, String lang) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
      _queryController.clear();
    });

    _scrollToBottom();

    final subState = ref.read(subscriptionProvider);
    final response = await AIService.chatWithAI(
      messages: _messages,
      subscriptions: subState.subscriptions,
      investments: _investments,
      cashAccounts: _cashAccounts,
      lang: lang,
    );

    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final suggestedQueries = _getSuggestedQueries(lang);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF00F2FE)),
            const SizedBox(width: 8),
            Text(
              'SubsTrack AI',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFD700),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Suggestions
          if (_messages.length == 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestedQueries.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _sendMessage(suggestedQueries[index], lang),
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          suggestedQueries[index],
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ).animate().fade(delay: (index * 100).ms).slideX();
                  },
                ),
              ),
            ),
            
          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.accentPurple : AppColors.surface1,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                        bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(20),
                      ),
                      border: !isUser ? Border.all(color: AppColors.borderMedium) : null,
                    ),
                    child: Text(
                      msg['text']!,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ).animate().fade().scaleXY(begin: 0.9, end: 1.0, duration: 200.ms),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFF00F2FE)),
            ),
            
          // Input Area
          Container(
            padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(
              color: AppColors.surface1,
              border: Border(top: BorderSide(color: AppColors.borderMedium)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppTranslations.translate(lang, 'ai_input_hint'),
                      hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (val) => _sendMessage(val, lang),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_queryController.text, lang),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF7C6AF7), Color(0xFF00F2FE)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
