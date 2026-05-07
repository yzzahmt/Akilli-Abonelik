import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_colors.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/subscription_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state_widget.dart';
import '../services/ad_service.dart';
import '../utils/translations.dart';
import 'add_subscription_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'pro_unlock_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTabBody(),
          CalendarScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPremium && _isAdLoaded && _bannerAd != null)
            Container(
              color: Colors.transparent,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface1,
              border: Border(
                top: BorderSide(
                  color: Color(0x0FFFFFFF),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: AppColors.surface1,
              selectedItemColor: AppColors.accentPurple,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: AppTranslations.translate(lang, 'home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.calendar_today_outlined),
                  activeIcon: const Icon(Icons.calendar_today_rounded),
                  label: AppTranslations.translate(lang, 'calendar'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings_rounded),
                  label: AppTranslations.translate(lang, 'settings'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C6AF7), Color(0xFF6C5CE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddSubscriptionScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add, size: 28),
              ),
            )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(delay: 200.ms, duration: 1500.ms, begin: 1.0, end: 1.08)
          : null,
    );
  }
}

class _HomeTabBody extends ConsumerWidget {
  const _HomeTabBody();

  String _formatCurrency(double value, String lang) {
    final symbol = lang == 'TR' ? '₺' : '\$';
    final format = NumberFormat.currency(locale: lang == 'TR' ? 'tr_TR' : 'en_US', symbol: symbol, decimalDigits: 2);
    return format.format(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionProvider);
    final notifier = ref.read(subscriptionProvider.notifier);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final lang = ref.watch(languageProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPurple));
    }

    // Days elapsed in current month
    final now = DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final progress = now.day / totalDaysInMonth;

    // Filtering logic
    final filteredSubs = state.subscriptions.where((sub) {
      if (selectedCategory == 'Tümü' || selectedCategory == 'All') return true;
      return sub.category == selectedCategory;
    }).toList();

    final Map<String, String> categoriesMap = {
      'Tümü': AppTranslations.translate(lang, 'all'),
      'Video': AppTranslations.translate(lang, 'video'),
      'Müzik': AppTranslations.translate(lang, 'music'),
      'Yapay Zeka': AppTranslations.translate(lang, 'ai'),
      'Bulut': AppTranslations.translate(lang, 'cloud'),
      'Oyun': AppTranslations.translate(lang, 'gaming'),
      'Eğitim': AppTranslations.translate(lang, 'education'),
      'Spor': AppTranslations.translate(lang, 'sports'),
      'Üretkenlik': AppTranslations.translate(lang, 'productivity'),
      'Güvenlik': AppTranslations.translate(lang, 'security'),
      'Diğer': AppTranslations.translate(lang, 'other'),
    };

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.accentPurple,
        backgroundColor: AppColors.surface1,
        onRefresh: () async => ref.read(subscriptionProvider.notifier).fetchFreshRates(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // [1] Custom AppBar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.accentPurple,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          lang == 'TR' ? '₺' : '\$',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppTranslations.translate(lang, 'app_title'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PRO ✓',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isPremium)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProUnlockScreen(),
                          ),
                        );
                      },
                      child: Text(
                        AppTranslations.translate(lang, 'upgrade_to_pro'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                      onPressed: () {},
                    ),
                ],
              ).animate().fade(),
              const SizedBox(height: 24),

              // Pro Feature: Spending Limit Banner
              if (isPremium && ref.watch(spendingLimitProvider) > 0) ...() {
                final limit = ref.watch(spendingLimitProvider);
                final total = notifier.totalThisMonth;
                if (total > limit) {
                  final overAmount = total - limit;
                  return [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.expensiveRed.withOpacity(0.15),
                        border: Border.all(color: AppColors.expensiveRed.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.expensiveRed),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lang == 'TR'
                                  ? '⚠️ Aylık limitinizi ₺${overAmount.toStringAsFixed(0)} aştınız!'
                                  : '⚠️ You exceeded your monthly limit by \$${overAmount.toStringAsFixed(0)}!',
                              style: GoogleFonts.inter(color: AppColors.expensiveRed, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ];
                } else if (total > limit * 0.8) {
                  return [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber.withOpacity(0.15),
                        border: Border.all(color: AppColors.warningAmber.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.warningAmber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lang == 'TR'
                                  ? 'Limite yaklaşıyorsunuz (₺${total.toStringAsFixed(0)} / ₺${limit.toStringAsFixed(0)})'
                                  : 'Approaching limit (\$${total.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)})',
                              style: GoogleFonts.inter(color: AppColors.warningAmber, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ];
                }
                return <Widget>[];
              }(),

              // [2] Hero Summary Card (glassmorphism)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.translate(lang, 'home_summary_title'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: notifier.totalThisMonth),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, val, child) {
                        return Text(
                          _formatCurrency(val, lang),
                          style: GoogleFonts.inter(
                            fontSize: 38,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppTranslations.translate(lang, 'home_summary_yearly')}: ${_formatCurrency(notifier.totalThisYear, lang)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${AppTranslations.translate(lang, 'home_summary_active')}: ${state.subscriptions.length}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: const Color(0x11FFFFFF),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0.0),

              const SizedBox(height: 22),

              // [3] Category filter chips (horizontal scroll)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: categoriesMap.keys.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return CategoryChip(
                      label: categoriesMap[cat]!,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(categoryFilterProvider.notifier).setCategory(cat);
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // [4] Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslations.translate(lang, 'subscriptions_list_header'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle, width: 1),
                    ),
                    child: Text(
                      '${filteredSubs.length}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // [5] Subscriptions List (ListView)
              if (filteredSubs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyStateWidget(
                    title: AppTranslations.translate(lang, 'no_subscriptions_yet'),
                    message: AppTranslations.translate(lang, 'add_first_subscription'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSubs.length,
                  itemBuilder: (context, index) {
                    final sub = filteredSubs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SubscriptionCard(
                        subscription: sub,
                        convertedPriceInTRY: notifier.convertToTRY(sub.price, sub.currency),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddSubscriptionScreen(subscriptionToEdit: sub),
                            ),
                          );
                        },
                      ),
                    ).animate().fade(duration: 250.ms).slideY(begin: 0.1, end: 0.0);
                  },
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
