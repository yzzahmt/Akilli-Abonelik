import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../providers/subscription_provider.dart';
import '../services/database_service.dart';
import '../services/market_service.dart';
import '../services/activity_tracker.dart';
import '../services/ai_service.dart';
import '../providers/settings_provider.dart';
import '../utils/translations.dart';

class SpendingChartScreen extends ConsumerStatefulWidget {
  const SpendingChartScreen({super.key});

  @override
  ConsumerState<SpendingChartScreen> createState() => _SpendingChartScreenState();
}

class _SpendingChartScreenState extends ConsumerState<SpendingChartScreen> {
  bool _isLoading = true;
  double _totalProfit = 0;
  double _totalLoss = 0;
  double _totalMonthlySubs = 0;
  List<Map<String, dynamic>> _profitItems = [];
  List<Map<String, dynamic>> _lossItems = [];
  Map<String, double> _categoryData = {};
  
  bool _isAiLoading = false;
  Map<String, dynamic>? _aiInsights;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final state = ref.read(subscriptionProvider);
    double subscriptionLoss = 0;
    double monthlySubs = 0;
    List<Map<String, dynamic>> lossList = [];
    Map<String, double> categories = {};
    
    for (var sub in state.subscriptions) {
      if (sub.isActive) {
        double monthlyCost = sub.priceInTL;
        if (sub.billingCycle == 'Yıllık') {
          monthlyCost /= 12;
        } else if (sub.billingCycle == '6 Aylık') {
          monthlyCost /= 6;
        } else if (sub.billingCycle == '3 Aylık') {
          monthlyCost /= 3;
        } else if (sub.billingCycle == '2 Haftada Bir') {
          monthlyCost = (monthlyCost / 14) * 30;
        } else if (sub.billingCycle == 'Haftalık') {
          monthlyCost = (monthlyCost / 7) * 30;
        }

        subscriptionLoss += monthlyCost;
        monthlySubs += monthlyCost;
        lossList.add({
          'name': sub.name,
          'amount': monthlyCost,
          'emoji': sub.emoji,
          'type': 'Abonelik',
        });
        
        categories[sub.category] = (categories[sub.category] ?? 0) + monthlyCost;
      }
    }

    final invs = await DBService.instance.getAllInvestments();
    double investmentProfit = 0;
    List<Map<String, dynamic>> profitList = [];

    for (var inv in invs) {
      try {
        final quote = await MarketService.fetchQuote(inv.symbol);
        if (!quote.containsKey('error') && quote['price'] != null) {
          double currentPrice = quote['price'] as double;
          double currentValue = currentPrice * inv.quantity;
          double profit = currentValue - inv.totalBuyCost;

          if (profit > 0) {
            investmentProfit += profit;
            profitList.add({
              'name': inv.symbol,
              'amount': profit,
              'emoji': '📈',
              'type': 'Yatırım Kârı',
            });
          } else if (profit < 0) {
            subscriptionLoss += profit.abs();
            lossList.add({
              'name': inv.symbol,
              'amount': profit.abs(),
              'emoji': '📉',
              'type': 'Yatırım Zararı',
            });
          }
        }
      } catch (_) {}
    }

    profitList.sort((a, b) => b['amount'].compareTo(a['amount']));
    lossList.sort((a, b) => b['amount'].compareTo(a['amount']));

    if (mounted) {
      setState(() {
        _totalProfit = investmentProfit;
        _totalLoss = subscriptionLoss;
        _totalMonthlySubs = monthlySubs;
        _profitItems = profitList;
        _lossItems = lossList;
        _categoryData = categories;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAiInsights() async {
    setState(() => _isAiLoading = true);
    try {
      final subs = ref.read(subscriptionProvider).subscriptions;
      final invs = await DBService.instance.getAllInvestments();
      final cashAccounts = await DBService.instance.getAllCashAccounts();
      final logs = await ActivityTracker.getDetailedLogs(limit: 50);

      final lang = ref.read(languageProvider);
      
      final insights = await AIService.getFinancialSummaryAndInsights(
        subscriptions: subs,
        investments: invs,
        cashAccounts: cashAccounts,
        recentLogs: logs,
        lang: lang,
      );

      if (mounted) {
        setState(() {
          _aiInsights = insights;
          _isAiLoading = false;
        });
        await ActivityTracker.logAction("AI Analizi İstendi", "Kullanıcı finansal kokpit sayfasında yapay zeka analizini çalıştırdı.");
      }
    } catch (e) {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00F2FE))),
      );
    }

    final hasData = _totalProfit > 0 || _totalLoss > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Finansal Kokpit',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              if (!hasData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Text(
                      'Henüz hesaplanabilecek veri yok.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else ...[
                // Genel Bütçe Kartı
                _buildMainBudgetCard().animate().fadeIn().slideY(begin: 0.1),
                
                const SizedBox(height: 24),

                // Özet Kartları
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Toplam Kâr', _totalProfit, AppColors.activeGreen, Icons.trending_up_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryCard('Toplam Gider/Zarar', _totalLoss, AppColors.expensiveRed, Icons.trending_down_rounded)),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 32),
                
                // Pasta Grafiği ve Kategoriler
                if (_categoryData.isNotEmpty) ...[
                  Text(
                    'Kategori Dağılımı (Abonelikler)',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 220,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: _buildCategorySections(),
                            ),
                          ).animate().scale(delay: 300.ms, duration: 600.ms, curve: Curves.easeOutBack),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _categoryData.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12, height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(e.key),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${e.key} (%${((e.value / _totalMonthlySubs) * 100).toStringAsFixed(0)})',
                                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ).animate().fadeIn(delay: 400.ms),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // AI Yorumlar Butonu
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2E004B), AppColors.surface1]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.5)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _isAiLoading ? null : _fetchAiInsights,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isAiLoading)
                              const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            else ...[
                              const Icon(Icons.auto_awesome, color: Color(0xFF00F2FE)),
                              const SizedBox(width: 12),
                              Text(
                                AppTranslations.translate(ref.watch(languageProvider), 'ai_deep_analysis'),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.2)),

                const SizedBox(height: 24),

                // Yapay Zeka Çıktısı (Eğer Yüklendiyse)
                if (_aiInsights != null)
                  _buildAiInsightCard().animate().fadeIn().slideY(),

                const SizedBox(height: 32),
                
                // Kâr Listesi
                if (_profitItems.isNotEmpty) ...[
                  Text(
                    'En Çok Kâr Getirenler',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ..._profitItems.take(5).map((item) => _buildListItem(item, AppColors.activeGreen)),
                  const SizedBox(height: 24),
                ],
                
                // Zarar Listesi
                if (_lossItems.isNotEmpty) ...[
                  Text(
                    'En Çok Kaybettirenler / En Yüksek Giderler',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ..._lossItems.take(5).map((item) => _buildListItem(item, AppColors.expensiveRed)),
                  const SizedBox(height: 40),
                ],
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainBudgetCard() {
    double net = _totalProfit - _totalLoss;
    bool isPositive = net >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.activeGreen : AppColors.expensiveRed).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: Column(
        children: [
          Text('Net Finansal Durum', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Text(
            '${isPositive ? '+' : ''}₺${NumberFormat('#,##0.00', 'tr_TR').format(net)}',
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: isPositive ? AppColors.activeGreen : AppColors.expensiveRed,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _totalLoss == 0 && _totalProfit == 0 ? 0.5 : (_totalProfit / (_totalProfit + _totalLoss)),
              minHeight: 8,
              backgroundColor: AppColors.expensiveRed.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(AppColors.activeGreen),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gider/Zarar: ₺${NumberFormat('#,##0.00', 'tr_TR').format(_totalLoss)}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
              Text('Kâr: ₺${NumberFormat('#,##0.00', 'tr_TR').format(_totalProfit)}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildCategorySections() {
    List<PieChartSectionData> sections = [];
    _categoryData.forEach((key, value) {
      final percentage = (value / _totalMonthlySubs) * 100;
      if (percentage > 2) {
        sections.add(
          PieChartSectionData(
            value: value,
            color: _getCategoryColor(key),
            title: '%${percentage.toStringAsFixed(0)}',
            radius: 40,
            titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }
    });
    return sections;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Eğlence': return Colors.purple;
      case 'Eğitim': return Colors.blue;
      case 'Araçlar': return Colors.orange;
      case 'Yazılım': return Colors.teal;
      case 'Oyun': return Colors.greenAccent;
      case 'Diğer': return Colors.grey;
      default: return Colors.primaries[category.hashCode % Colors.primaries.length];
    }
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₺${NumberFormat('#,##0.00', 'tr_TR').format(amount)}',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard() {
    final ai = _aiInsights!;
    final lang = ref.watch(languageProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface1.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: Color(0xFF00F2FE), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    AppTranslations.translate(lang, 'ai_title'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInsightRow(Icons.short_text, AppTranslations.translate(lang, 'ai_genel_ozet'), ai["genel_ozet"] ?? "-"),
              const Divider(color: AppColors.borderSubtle, height: 32),
              _buildInsightRow(Icons.lightbulb_outline, AppTranslations.translate(lang, 'ai_tavsiye'), ai["tavsiye"] ?? "-"),
              const Divider(color: AppColors.borderSubtle, height: 32),
              _buildInsightRow(Icons.trending_up, AppTranslations.translate(lang, 'ai_projeksiyon'), ai["gelecek_tahmini_1_yil"] ?? "-"),
              const Divider(color: AppColors.borderSubtle, height: 32),
              _buildInsightRow(Icons.warning_amber_rounded, AppTranslations.translate(lang, 'ai_kritik'), ai["dikkat_ceken_nokta"] ?? "-"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, Color valueColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item['emoji'],
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                Text(
                  item['type'],
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₺${NumberFormat('#,##0.00', 'tr_TR').format(item['amount'])}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
