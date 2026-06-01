// SubsTrack yeni özellik — Sol Drawer (Bölüm 4 & 6)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_colors.dart';
import '../providers/subscription_provider.dart';
import '../screens/investment_screen.dart';
import '../screens/spending_chart_screen.dart';
import '../screens/kvkk_screen.dart';
import '../screens/add_subscription_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/piggy_bank_screen.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  String _version = '2.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = '${info.version} (${info.buildNumber})';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final notifier = ref.read(subscriptionProvider.notifier);
    final totalMonth = notifier.totalThisMonth;

    return Drawer(
      backgroundColor: AppColors.surface1,
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          children: [
            // Üst alan — Logo + Bu ay harcama
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentPurple.withValues(alpha: 0.12),
                    AppColors.surface1,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: const Border(
                  bottom: BorderSide(
                    color: AppColors.borderSubtle,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SubsTrack',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bu ay harcama
                  Text(
                    'Bu ay harcama',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: totalMonth),
                    duration: const Duration(milliseconds: 800),
                    builder: (ctx, val, _) => Text(
                      '₺${NumberFormat('#,##0', 'tr_TR').format(val)}',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mini Sparkline (Bölüm 6)
                  SizedBox(
                    height: 30,
                    width: double.infinity,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              const FlSpot(0, 3),
                              const FlSpot(1, 1),
                              const FlSpot(2, 4),
                              const FlSpot(3, 2),
                              const FlSpot(4, 5),
                              const FlSpot(5, 3),
                            ],
                            isCurved: true,
                            color: AppColors.accentPurple,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.accentPurple.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                        minX: 0,
                        maxX: 5,
                        minY: 0,
                        maxY: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.subscriptions.length} aktif abonelik',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Menü öğeleri
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    outlineIcon: Icons.home_outlined,
                    label: 'Ana Sayfa',
                    isActive: true, // Şimdilik sadece Ana Sayfa aktif varsayılıyor
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.trending_up_rounded,
                    outlineIcon: Icons.trending_up_outlined,
                    label: 'Yatırım Takibi',
                    isNew: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const InvestmentScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_month_rounded,
                    outlineIcon: Icons.calendar_today_outlined,
                    label: 'Takvim',
                    isNew: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CalendarScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.repeat_rounded,
                    outlineIcon: Icons.repeat_outlined,
                    label: 'Abonelikler',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AddSubscriptionScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_rounded,
                    outlineIcon: Icons.bar_chart_outlined,
                    label: 'Harcama Grafiği',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SpendingChartScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.savings_rounded,
                    outlineIcon: Icons.savings_outlined,
                    label: 'Kumbara',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PiggyBankScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Alt alan — Ayarlar, KVKK, Hakkında
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    outlineIcon: Icons.settings_outlined,
                    label: 'Ayarlar',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const _SettingsPage()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.security_rounded,
                    outlineIcon: Icons.security_outlined,
                    label: 'KVKK / Gizlilik',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const KvkkScreen(isReadOnly: true)),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_rounded,
                    outlineIcon: Icons.info_outline_rounded,
                    label: 'Hakkında',
                    onTap: () {
                      Navigator.of(context).pop();
                      showAboutDialog(
                        context: context,
                        applicationName: 'SubsTrack',
                        applicationVersion: _version,
                        applicationIcon: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/app_icon.png',
                              width: 48, height: 48),
                        ),
                        children: [
                          Text(
                            'Abonelik ve yatırım takip uygulaması.\nTüm veriler cihazınızda saklanır.',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      'v$_version',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isNew;

  const _DrawerItem({
    required this.icon,
    required this.outlineIcon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(isActive ? icon : outlineIcon, 
          color: isActive ? AppColors.accentPurple : AppColors.textSecondary, 
          size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: isActive ? AppColors.accentPurple : AppColors.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: isNew
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'YENİ',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentPurple,
                ),
              ),
            )
          : null,
      horizontalTitleGap: 8,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// Settings sayfasına wrapper (izole navigator için)
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const SettingsScreen(),
    );
  }
}
