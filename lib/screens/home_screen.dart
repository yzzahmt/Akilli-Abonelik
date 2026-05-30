// SubsTrack yeni özellik — Sol Drawer + Swipe Kısayolları entegrasyonu (Bölüm 4 & 5)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/subscription_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/app_drawer.dart'; // SubsTrack yeni özellik — BURAYA EKLE
import '../widgets/ai_assistant_button.dart'; // SubsTrack yeni özellik — BURAYA EKLE
import '../services/ad_service.dart';
import '../services/database_service.dart'; // SubsTrack yeni özellik — BURAYA EKLE
import '../services/market_service.dart';
import '../utils/translations.dart';
import 'add_subscription_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'pro_unlock_screen.dart';
import 'spending_chart_screen.dart';
import 'investment_screen.dart';
import 'ai_assistant_screen.dart';
import '../services/activity_tracker.dart';
import '../services/notification_service.dart' as import_notification;

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
    ActivityTracker.logAppOpen();
    _loadBannerAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        import_notification.NotificationService.requestPermissionsWithRationale(context);
      }
    });
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
      // SubsTrack yeni özellik — Sol Drawer (Bölüm 4) — BURAYA EKLE
      drawer: const AppDrawer(),
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
                AdService.onScreenChanged(ref.read(isPremiumProvider));
              },
              backgroundColor: AppColors.surface1,
              selectedItemColor: AppColors.accentPurple,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
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
                    color: AppColors.accentPurple.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, a, __) => const AddSubscriptionScreen(),
                      transitionsBuilder: (_, anim, __, child) => SlideTransition(
                        position: Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                      transitionDuration: const Duration(milliseconds: 300),
                    )
                  );
                },
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.surface1,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 24),
                          ListTile(
                            leading: const Icon(Icons.repeat_rounded, color: AppColors.accentPurple),
                            title: Text('Abonelik Ekle', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.payment_rounded, color: AppColors.activeGreen),
                            title: Text('Manuel Ödeme Ekle', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                            onTap: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yakında eklenecek')));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.trending_up_rounded, color: AppColors.warningAmber),
                            title: Text('Yatırım Ekle', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvestmentScreen()));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.auto_awesome, color: Color(0xFF00F2FE)),
                            title: Text('Yapay Zeka Asistanı', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                            trailing: isPremium ? null : const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 16),
                            onTap: () {
                              Navigator.pop(ctx);
                              if (isPremium) {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AIAssistantScreen()));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu özellik PRO gerektirir.')));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.add, size: 28, color: Colors.white),
                ),
              ),
            )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(delay: 200.ms, duration: 1500.ms, begin: 1.0, end: 1.08)
          : null,
    );
  }
}

class _HomeTabBody extends ConsumerStatefulWidget {
  const _HomeTabBody();

  @override
  ConsumerState<_HomeTabBody> createState() => _HomeTabBodyState();
}

// SubsTrack yeni özellik — Swipe kısayolları için StatefulWidget (Bölüm 5)
class _HomeTabBodyState extends ConsumerState<_HomeTabBody> {
  final PageController _heroPageController = PageController();
  int _currentHeroPage = 0;
  double _investmentCost = 0;
  double _investmentTotal = 0;
  bool _showProArrow = false;

  @override
  void initState() {
    super.initState();
    _loadInvestments();
    _checkFirstTimeProArrow();
  }

  Future<void> _checkFirstTimeProArrow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool('has_shown_pro_arrow') ?? false;
      if (!hasShown && mounted) {
        setState(() {
          _showProArrow = true;
        });
        await prefs.setBool('has_shown_pro_arrow', true);
      }
    } catch (_) {}
  }

  Future<void> _loadInvestments() async {
    final invs = await DBService.instance.getAllInvestments();
    double cost = 0;
    double total = 0;
    for (var inv in invs) {
      cost += inv.totalBuyCost;
      try {
        final quote = await MarketService.fetchQuote(inv.symbol);
        double price = (quote['price'] as num?)?.toDouble() ?? inv.buyPrice;
        total += inv.quantity * price;
      } catch (_) {
        total += inv.totalBuyCost;
      }
    }
    if (mounted) {
      setState(() {
        _investmentCost = cost;
        _investmentTotal = total;
      });
    }
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value, String lang) {
    final symbol = lang == 'TR' ? '₺' : '\$';
    final format = NumberFormat.currency(
        locale: lang == 'TR' ? 'tr_TR' : 'en_US',
        symbol: symbol,
        decimalDigits: 2);
    return format.format(value);
  }

  // SubsTrack yeni özellik — Uzun basma menüsü (Bölüm 5)
  void _showSubscriptionContextMenu(
      BuildContext context, subscription, WidgetRef ref, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.borderMedium)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${subscription.emoji} ${subscription.name}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded,
                  color: AppColors.accentPurple),
              title: Text('Düzenle',
                  style:
                      GoogleFonts.inter(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AddSubscriptionScreen(
                      subscriptionToEdit: subscription),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.expensiveRed),
              title: Text('Sil',
                  style: GoogleFonts.inter(
                      color: AppColors.expensiveRed)),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(subscriptionProvider.notifier)
                    .deleteSubscription(subscription.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined,
                  color: AppColors.textSecondary),
              title: Text('Bildirimi Kapat',
                  style:
                      GoogleFonts.inter(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.of(ctx).pop();
                // notifyDaysBefore = 0 yaparak bildirimi kapat
                final updated =
                    subscription.copyWith(notifyDaysBefore: 0);
                await ref
                    .read(subscriptionProvider.notifier)
                    .updateSubscription(updated);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded,
                  color: AppColors.activeGreen),
              title: Text('Yenileme Tarihi',
                  style:
                      GoogleFonts.inter(color: AppColors.textPrimary)),
              subtitle: Text(
                'Her ayın ${subscription.renewalDay}. günü',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final notifier = ref.read(subscriptionProvider.notifier);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final lang = ref.watch(languageProvider);

    if (state.isLoading) {
      return const Center(
          child:
              CircularProgressIndicator(color: AppColors.accentPurple));
    }

    final now = DateTime.now();
    final totalDaysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    final progress = now.day / totalDaysInMonth;

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
      // SubsTrack yeni özellik — Swipe kısayolları (Bölüm 5)
      child: GestureDetector(
        onPanStart: (details) {
        },
        onPanEnd: (details) {
          final dx = details.velocity.pixelsPerSecond.dx;
          final dy = details.velocity.pixelsPerSecond.dy;
          final absDx = dx.abs();
          final absDy = dy.abs();

          // Yatay kaydırma (horizontal baskın)
          if (absDx > absDy && absDx > 300) {
            if (dx > 0) {
              // Sağa kaydır → Harcama Grafiği
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (_, a, __) =>
                    const SpendingChartScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
                transitionDuration:
                    const Duration(milliseconds: 300),
              ));
            } else {
              // Sola kaydır → Ayarlar
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (_, a, __) => Scaffold(
                  backgroundColor: AppColors.background,
                  body: const SettingsScreen(),
                ),
                transitionsBuilder: (_, anim, __, child) =>
                    SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1.0, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
                transitionDuration:
                    const Duration(milliseconds: 300),
              ));
            }
          }
        },
        child: RefreshIndicator(
          color: AppColors.accentPurple,
          backgroundColor: AppColors.surface1,
          onRefresh: () async =>
              ref.read(subscriptionProvider.notifier).fetchFreshRates(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // [1] Custom AppBar (hamburger ikonu eklendi — Bölüm 4)
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // SubsTrack yeni özellik — Hamburger ikonu (Bölüm 4)
                        Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu_rounded,
                                color: AppColors.textPrimary,
                                size: 22),
                            onPressed: () =>
                                Scaffold.of(ctx).openDrawer(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPurple
                                    .withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppTranslations.translate(
                              lang, 'app_title'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius:
                                  BorderRadius.circular(6),
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
                    Row(
                      children: [
                        const AIAssistantButton(),
                        const SizedBox(width: 8),
                        if (!isPremium)
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  if (_showProArrow) {
                                    setState(() => _showProArrow = false);
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProUnlockScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  AppTranslations.translate(
                                      lang, 'upgrade_to_pro'),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFD700),
                                  ),
                                ),
                              ),
                              if (_showProArrow)
                                Positioned(
                                  top: 40,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.arrow_upward_rounded, color: Colors.grey, size: 24),
                                        const SizedBox(height: 4),
                                        Text(
                                          lang == 'TR' ? 'Pro\'ya Geç' : 'Go Pro',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -8),
                                ),
                            ],
                          )
                        else
                          IconButton(
                            icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.textPrimary),
                            onPressed: () {},
                          ),
                      ],
                    ),
                  ],
                ).animate().fade(),
                const SizedBox(height: 24),

                // Pro Feature: Spending Limit Banner
                if (isPremium &&
                    ref.watch(spendingLimitProvider) > 0)
                  ...() {
                    final limit =
                        ref.watch(spendingLimitProvider);
                    final total = notifier.totalThisMonth;
                    if (total > limit) {
                      final overAmount = total - limit;
                      return [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.expensiveRed
                                .withValues(alpha: 0.15),
                            border: Border.all(
                                color: AppColors.expensiveRed
                                    .withValues(alpha: 0.5)),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.expensiveRed),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  lang == 'TR'
                                      ? '⚠️ Aylık limitinizi ₺${overAmount.toStringAsFixed(0)} aştınız!'
                                      : '⚠️ You exceeded your monthly limit by \$${overAmount.toStringAsFixed(0)}!',
                                  style: GoogleFonts.inter(
                                      color:
                                          AppColors.expensiveRed,
                                      fontWeight:
                                          FontWeight.bold),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.warningAmber
                                .withValues(alpha: 0.15),
                            border: Border.all(
                                color: AppColors.warningAmber
                                    .withValues(alpha: 0.5)),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.warningAmber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  lang == 'TR'
                                      ? 'Limite yaklaşıyorsunuz (₺${total.toStringAsFixed(0)} / ₺${limit.toStringAsFixed(0)})'
                                      : 'Approaching limit (\$${total.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)})',
                                  style: GoogleFonts.inter(
                                      color:
                                          AppColors.warningAmber,
                                      fontWeight:
                                          FontWeight.bold),
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

                // [2] Hero Summary Card
                Column(
                  children: [
                    SizedBox(
                      height: 190,
                      child: PageView(
                        controller: _heroPageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentHeroPage = index;
                          });
                        },
                        children: [
                          // Card 1: Subscriptions
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A1F35), Color(0xFF252B48)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.glassBorder, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF7C6AF7), Color(0xFF9D8FF9)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF7C6AF7),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppTranslations.translate(lang, 'home_summary_title'),
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
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
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.textSecondary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${AppTranslations.translate(lang, 'home_summary_yearly')}: ${_formatCurrency(notifier.totalThisYear, lang)}',
                                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                'Aktif: ${state.subscriptions.where((s) => s.isActive).length}',
                                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Card 2: Investments
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E2A38), Color(0xFF2C3E50)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.glassBorder, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF34D399), Color(0xFF059669)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF34D399),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                lang == 'TR' ? 'Toplam Yatırım Değeri' : 'Total Investment Value',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatCurrency(_investmentTotal, lang),
                                            style: GoogleFonts.inter(
                                              fontSize: 38,
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Icon(
                                                _investmentTotal >= _investmentCost ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                                size: 16,
                                                color: _investmentTotal >= _investmentCost ? AppColors.activeGreen : AppColors.expensiveRed,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                lang == 'TR' ? 'Net Kâr / Zarar:' : 'Net Profit / Loss:',
                                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${_investmentTotal >= _investmentCost ? '+' : ''}${_formatCurrency(_investmentTotal - _investmentCost, lang)}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: _investmentTotal >= _investmentCost ? AppColors.activeGreen : AppColors.expensiveRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Card 3: Total Wealth (Toplam Mal Varlığım)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C191E), Color(0xFF4A2B32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.glassBorder, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFBBF24),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            lang == 'TR' ? 'Toplam Mal Varlığım' : 'Total Wealth',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatCurrency(_investmentTotal, lang),
                                        style: GoogleFonts.inter(
                                          fontSize: 38,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.savings_rounded,
                                            size: 16,
                                            color: Color(0xFFFBBF24),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            lang == 'TR' ? 'Tüm yatırımların toplam değeri' : 'Total value of all investments',
                                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentHeroPage == index ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentHeroPage == index ? AppColors.accentPurple : AppColors.textMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0.0),

                const SizedBox(height: 22),

                // [3] Category filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: categoriesMap.keys.map((cat) {
                      final isSelected =
                          selectedCategory == cat;
                      return CategoryChip(
                        label: categoriesMap[cat]!,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(categoryFilterProvider
                                  .notifier)
                              .setCategory(cat);
                        },
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // [4] Section Header
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.translate(
                          lang, 'subscriptions_list_header'),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.borderSubtle,
                            width: 1),
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

                // [5] Subscriptions List
                if (filteredSubs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyStateWidget(
                      title: AppTranslations.translate(
                          lang, 'no_subscriptions_yet'),
                      message: AppTranslations.translate(
                          lang, 'add_first_subscription'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: filteredSubs.length,
                    itemBuilder: (context, index) {
                      final sub = filteredSubs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key('sub_${sub.id}'),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F2FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 24),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 32),
                          ),
                          secondaryBackground: Container(
                            decoration: BoxDecoration(
                              color: AppColors.expensiveRed,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(Icons.delete_rounded, color: Colors.white, size: 32),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Edit
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddSubscriptionScreen(subscriptionToEdit: sub),
                                ),
                              );
                              return false; // Don't delete from list
                            }
                            return true; // Delete
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              ref.read(subscriptionProvider.notifier).deleteSubscription(sub.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${sub.name} silindi'),
                                  backgroundColor: AppColors.surface1,
                                ),
                              );
                            }
                          },
                          child: GestureDetector(
                            onLongPress: () => _showSubscriptionContextMenu(context, sub, ref, lang),
                            onDoubleTap: () async {
                              await DBService.instance.toggleFavorite(sub.id!, true);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('⭐ ${sub.name} favorilere eklendi!', style: GoogleFonts.inter(color: Colors.white)),
                                  backgroundColor: AppColors.warningAmber,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: SubscriptionCard(
                              subscription: sub,
                              convertedPriceInTRY: notifier.convertToTRY(sub.price, sub.currency),
                              onTap: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (_, a, __) => AddSubscriptionScreen(subscriptionToEdit: sub),
                                    transitionsBuilder: (_, anim, __, child) => SlideTransition(
                                      position: Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(anim),
                                      child: child,
                                    ),
                                    transitionDuration: const Duration(milliseconds: 300),
                                  )
                                );
                              },
                            ),
                          ),
                        ),
                      ).animate().fade(duration: 250.ms).slideY(
                          begin: 0.1, end: 0.0);
                    },
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
