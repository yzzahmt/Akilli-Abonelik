import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/ai_assistant_button.dart';
import '../constants/app_colors.dart';
import '../providers/subscription_provider.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final subs = subState.subscriptions.where((s) => s.isActive).toList();
    final totalThisMonth = ref.watch(subscriptionProvider.notifier).totalThisMonth;
    final totalYear = totalThisMonth * 12;
    
    // Asgari ücret 2026 tahmin - example placeholder (e.g. 25000 TL)
    const double asgariUcret = 25000;
    final asgariUcretOrani = (totalYear / asgariUcret).toStringAsFixed(2);

    // En pahalı kategori
    final Map<String, double> categoryCosts = {};
    for (var s in subs) {
      final price = subState.rates[s.currency] != null 
          ? s.price * subState.rates[s.currency]!
          : s.priceInTL;
      categoryCosts[s.category] = (categoryCosts[s.category] ?? 0) + price;
    }
    
    String expCategory = 'Yok';
    double expCatCost = 0;
    if (categoryCosts.isNotEmpty) {
      final sortedCats = categoryCosts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      expCategory = sortedCats.first.key;
      expCatCost = sortedCats.first.value;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Akıllı Analizler', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          AIAssistantButton(),
        ],
      ),
      body: subs.isEmpty 
          ? const Center(child: Text('Yeterli veri yok', style: TextStyle(color: Colors.white)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInsightCard(
                    icon: Icons.category_rounded,
                    title: 'En Pahalı Kategorin',
                    subtitle: '$expCategory (₺${expCatCost.toStringAsFixed(0)}/ay)',
                    color: AppColors.accentPurple,
                  ),
                  const SizedBox(height: 16),
                  _buildInsightCard(
                    icon: Icons.monetization_on_rounded,
                    title: 'Yıllık Toplam Harcama',
                    subtitle: '₺${totalYear.toStringAsFixed(0)}',
                    description: 'Bu miktar asgari ücretin yaklaşık $asgariUcretOrani katına denk geliyor.',
                    color: AppColors.expensiveRed,
                  ),
                  const SizedBox(height: 16),
                  if (subs.length > 2)
                    _buildInsightCard(
                      icon: Icons.savings_rounded,
                      title: 'Tasarruf Potansiyeli',
                      subtitle: '₺${ref.read(subscriptionProvider.notifier).convertToTRY(subs.last.price, subs.last.currency).toStringAsFixed(0)}/ay',
                      description: 'Eğer "${subs.last.name}" aboneliğini iptal edersen, yılda ₺${(ref.read(subscriptionProvider.notifier).convertToTRY(subs.last.price, subs.last.currency) * 12).toStringAsFixed(0)} cebinde kalır.',
                      color: AppColors.activeGreen,
                    ),
                  const SizedBox(height: 32),
                  Text(
                    'Kategorilere Göre Dağılım',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value.toInt() >= categoryCosts.keys.length) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    categoryCosts.keys.elementAt(value.toInt()),
                                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        barGroups: List.generate(categoryCosts.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: categoryCosts.values.elementAt(i),
                                color: AppColors.accentPurple,
                                width: 22,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
