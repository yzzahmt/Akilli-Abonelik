// SubsTrack yeni özellik — Onboarding Ekranı (Bölüm 3)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.subscriptions_rounded,
      iconColor: Color(0xFF7C6AF7),
      gradient: [Color(0xFF7C6AF7), Color(0xFF9D8FF9)],
      title: 'SubsTrack\'e hoş geldin',
      description:
          'Tüm aboneliklerini ve yatırımlarını tek yerden yönet. Hiçbir ödemeyi kaçırma.',
      tag: '00',
    ),
    _OnboardingPage(
      icon: Icons.workspace_premium_rounded,
      iconColor: Color(0xFFFFD700),
      gradient: [Color(0xFFFFD700), Color(0xFFF59E0B)],
      title: 'Ücretsiz Premium Fırsatı!',
      description:
          'Ana ekranın sağ üstündeki Pro butonuna tıkla, sadece 3 kısa reklam izleyerek sınırlı süreli Premium özellikleri ücretsiz aç!',
      tag: '01',
    ),
    _OnboardingPage(
      icon: Icons.menu_open_rounded,
      iconColor: Color(0xFF34D399),
      gradient: [Color(0xFF34D399), Color(0xFF10B981)],
      title: 'Sol menü ile hızlı erişim',
      description:
          'Sol kenardan sağa kaydır → yan menü açılır. Buradan Ana Sayfa, Grafikler, Abonelikler ve Yatırımlara geçebilirsin.',
      tag: '02',
    ),
    _OnboardingPage(
      icon: Icons.swipe_rounded,
      iconColor: Color(0xFFFBBF24),
      gradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      title: 'Kaydırma kısayolları',
      description:
          '1 Parmak Sağa/Sola → Grafik / Ayarlar\n'
          '2 Parmak Sıkıştır (Pinch) → Kumbara 🪙\n'
          '2 Parmak Genişlet (Expand) → Grafik 📈\n'
          '2 Parmak Yukarı/Aşağı → Yatırım 📊 / Takvim 📅',
      tag: '03',
    ),
    _OnboardingPage(
      icon: Icons.add_circle_rounded,
      iconColor: Color(0xFF818CF8),
      gradient: [Color(0xFF818CF8), Color(0xFF6366F1)],
      title: 'Hızlı abonelik ekle',
      description:
          'Sağ alttaki + butonuna dokun. Hazır şablonlardan seç veya kendin ekle. Haftalık/aylık/yıllık dönem seçebilirsin.',
      tag: '04',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      iconColor: Color(0xFFF87171),
      gradient: [Color(0xFFF87171), Color(0xFFEF4444)],
      title: 'Hiçbir ödemeyi kaçırma',
      description:
          'Abonelik yenilenmesinden 1, 3 veya 7 gün önce sana hatırlatma gönderiyoruz. Ayarlardan özelleştirebilirsin.',
      tag: '05',
    ),
    _OnboardingPage(
      icon: Icons.verified_rounded,
      iconColor: Color(0xFF34D399),
      gradient: [Color(0xFF34D399), Color(0xFF059669)],
      title: 'Her şey hazır! 🎉',
      description:
          'Verileriniz yalnızca telefonunda saklanır, sunucuya gönderilmez. Gizliliğin bizim için önceliklidir.',
      tag: '06',
      isLast: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
    } catch (_) {}
    if (!mounted) return;
    widget.onComplete();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() => _completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.gradient[0].withValues(alpha: 0.06),
                  AppColors.background,
                  page.gradient[1].withValues(alpha: 0.03),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Üst bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/app_icon.png',
                              width: 28,
                              height: 28,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SubsTrack',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      // Skip
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: _skip,
                          child: Text(
                            'Geç',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),

                // Dot indikatörü ve buton
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      // Noktalar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPage == index ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? page.iconColor
                                  : AppColors.textMuted,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // İleri / Başlayalım butonu
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: page.gradient,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: page.iconColor.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _nextPage,
                            child: Text(
                              _currentPage == _pages.length - 1
                                  ? 'Başlayalım 🚀'
                                  : 'İleri',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tag (01, 02, ...)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: p.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.iconColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              p.tag,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: p.iconColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // İkon alanı
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: p.gradient
                    .map((c) => c.withValues(alpha: 0.15))
                    .toList(),
              ),
              border: Border.all(
                color: p.iconColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(p.icon, size: 52, color: p.iconColor),
          ),
          const SizedBox(height: 36),

          // Başlık
          Text(
            p.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Açıklama
          Text(
            p.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final List<Color> gradient;
  final String title;
  final String description;
  final String tag;
  final bool isLast;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.title,
    required this.description,
    required this.tag,
    this.isLast = false,
  });
}
