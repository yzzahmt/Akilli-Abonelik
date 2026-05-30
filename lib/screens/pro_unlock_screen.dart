import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../services/ad_service.dart';
import '../providers/settings_provider.dart';

class ProUnlockScreen extends ConsumerStatefulWidget {
  const ProUnlockScreen({super.key});

  @override
  ConsumerState<ProUnlockScreen> createState() => _ProUnlockScreenState();
}

class _ProUnlockScreenState extends ConsumerState<ProUnlockScreen> {
  bool _isLoadingAd = false;

  @override
  Widget build(BuildContext context) {
    final watchCount = AdService.instance.rewardedWatchCount;
    final isDone = watchCount >= AdService.adsRequiredForPro;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Crown Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 64, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 24),
              
              // Titles
              Text(
                'SubsTrack Pro\'ya Geç',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
               Text(
                '3 kısa reklam izleyerek Pro özelliklerinin kilidini aç',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ Bu sadece geçici premiumdur, uygulamadan çıkış yaptığınızda premiumunuz iptal edilir.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.warningAmber,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Progress Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isWatched = index < watchCount;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isWatched ? const Color(0xFFFFD700) : AppColors.surface2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isWatched ? const Color(0xFFFFD700) : AppColors.borderSubtle,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isWatched
                          ? const Icon(Icons.check_rounded, color: Colors.black, size: 24)
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                '$watchCount / 3 reklam izlendi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 40),

              // Features List
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureRow('🚫', 'Reklamları Tamamen Kaldır'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('🎨', 'Özelleştirilebilir Ana Ekran Kartları'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('📈', 'Gelişmiş Kâr/Zarar Grafikleri'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('🌗', 'Koyu / Açık Tema Seçimi'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('📊', 'CSV Dışa Aktar'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('📅', 'Takvime Aktar'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('🧠', 'Akıllı Analizler & Grafikler'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('💸', 'Aylık Harcama Limiti Uyarısı'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('💾', 'Yedekleme & Geri Yükleme'),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Big Action Button
              if (isDone)
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.activeGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '🎉 Pro Aktif!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoadingAd ? null : _watchAd,
                    child: _isLoadingAd
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Reklam İzle ($watchCount/3)',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              const SizedBox(height: 16),
              if (!isDone)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface2,
                      foregroundColor: const Color(0xFFFFD700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFFFD700)),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _buyPremium,
                    child: Text(
                      'Sınırsız Premium Satın Al',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _watchAd() async {
    setState(() => _isLoadingAd = true);
    
    await AdService.instance.showRewardedAd(
      onRewarded: () {
        setState(() {
          _isLoadingAd = false;
        });
        
        if (AdService.instance.hasEnoughForPro) {
          // Unlock PRO
          ref.read(isPremiumProvider.notifier).togglePremium(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 SubsTrack Pro aktifleştirildi!'),
              backgroundColor: AppColors.activeGreen,
            ),
          );
        }
      },
      onFailed: () {
        setState(() => _isLoadingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reklam yüklenemedi. Lütfen tekrar deneyin.'),
            backgroundColor: AppColors.expensiveRed,
          ),
        );
      },
    );
  }

  Future<void> _buyPremium() async {
    // Burada RevenueCat satın alma işlemi yapılacaktır.
    // Lütfen main.dart içindeki Purchases.configure adımını tamamlayın.
    try {
      // Offerings offerings = await Purchases.getOfferings();
      // if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
      //   CustomerInfo customerInfo = await Purchases.purchasePackage(offerings.current!.availablePackages[0]);
      //   if (customerInfo.entitlements.all["pro"]?.isActive == true) {
      //     ref.read(isPremiumProvider.notifier).togglePremium(true);
      //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Sınırsız Premium aktifleştirildi!')));
      //   }
      // }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Play entegrasyonu (RevenueCat) kodları eklendi. API Key girmeniz bekleniyor.')),
      );
    } catch (e) {
      // print("Satın alma hatası: $e");
    }
  }
}
