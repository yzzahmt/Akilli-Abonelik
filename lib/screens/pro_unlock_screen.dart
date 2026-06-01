import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import '../providers/settings_provider.dart';

class ProUnlockScreen extends ConsumerStatefulWidget {
  const ProUnlockScreen({super.key});

  @override
  ConsumerState<ProUnlockScreen> createState() => _ProUnlockScreenState();
}

class _ProUnlockScreenState extends ConsumerState<ProUnlockScreen> {
  bool _isLoadingAd = false;
  String? _productPrice;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadPrice();

    // Satın alma servisini dinle
    PurchaseService.instance.isPremium.addListener(_onPremiumChange);
    PurchaseService.instance.isPurchasing.addListener(_onPurchasingChange);
    PurchaseService.instance.errorMessage.addListener(_onErrorChange);
  }

  @override
  void dispose() {
    PurchaseService.instance.isPremium.removeListener(_onPremiumChange);
    PurchaseService.instance.isPurchasing.removeListener(_onPurchasingChange);
    PurchaseService.instance.errorMessage.removeListener(_onErrorChange);
    super.dispose();
  }

  Future<void> _loadPrice() async {
    final price = await PurchaseService.instance.fetchPrice();
    if (mounted) setState(() => _productPrice = price);
  }

  void _onPremiumChange() {
    if (PurchaseService.instance.isPremium.value && mounted) {
      // Premium aktif oldu → provider'ı güncelle ve ekrandan çık
      ref.read(isPremiumProvider.notifier).togglePermanentPremium(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 SubsTrack Pro aktifleştirildi! Tüm özellikler açık.'),
          backgroundColor: AppColors.activeGreen,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _onPurchasingChange() {
    if (mounted) setState(() {});
  }

  void _onErrorChange() {
    final error = PurchaseService.instance.errorMessage.value;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.expensiveRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchCount = AdService.instance.rewardedWatchCount;
    final isDone = watchCount >= AdService.adsRequiredForPro;
    final isPurchasing = PurchaseService.instance.isPurchasing.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Satın alma geri yükle
          TextButton(
            onPressed: _isRestoring ? null : _restorePurchases,
            child: Text(
              'Geri Yükle',
              style: GoogleFonts.inter(
                color: _isRestoring ? AppColors.textMuted : AppColors.accentPurple,
                fontSize: 13,
              ),
            ),
          ),
        ],
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
                'Tek seferlik satın alma — Sonsuza kadar geçerli',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Divider
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0x22FFFFFF)),
              ),

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
                        _buildFeatureRow('🚫', 'Tüm Reklamları Kaldır'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('📊', 'Akıllı Analiz & Grafikler'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('🧠', 'Yapay Zeka Asistanı'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('📈', 'Gelişmiş Harcama Grafikleri'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('📋', 'CSV Dışa Aktar'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('📅', 'Takvime Aktar'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('💸', 'Aylık Harcama Limiti Uyarısı'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('💾', 'Yedekleme & Geri Yükleme'),
                        const SizedBox(height: 16),
                        _buildFeatureRow('🔁', 'Sonsuza Kadar Geçerli'),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Satın Al Butonu ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: isPurchasing ? null : _buyPremium,
                  child: isPurchasing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              _productPrice != null
                                  ? 'Pro\'ya Geç — $_productPrice'
                                  : 'Pro\'ya Geç',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Reklam İzleyerek Geçici Pro ──
              if (!isDone)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface2,
                      foregroundColor: AppColors.accentPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.accentPurple),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoadingAd ? null : _watchAd,
                    child: _isLoadingAd
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPurple),
                          )
                        : Text(
                            '📺 Reklam İzle ($watchCount/3) — Geçici Pro',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.activeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.activeGreen),
                  ),
                  child: Center(
                    child: Text(
                      '🎉 Geçici Pro Aktif (Bu oturum için)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.activeGreen,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Text(
                'Satın alma Google Play üzerinden güvenli şekilde gerçekleşir.\nİptal politikamız Google Play koşullarına tabidir.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
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
        const Icon(Icons.check_circle_rounded, color: AppColors.activeGreen, size: 18),
      ],
    );
  }

  /// Google Play satın alma başlat
  void _buyPremium() async {
    await PurchaseService.instance.buyPremium();
  }

  /// Önceki satın almaları geri yükle
  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);
    await PurchaseService.instance.restorePurchases();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isRestoring = false);
      final isPrem = PurchaseService.instance.isPremium.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPrem
              ? '✅ Premium geri yüklendi!'
              : 'Bu hesapta aktif premium bulunamadı.'),
          backgroundColor: isPrem ? AppColors.activeGreen : AppColors.textMuted,
        ),
      );
    }
  }

  /// Reklam izleyerek geçici Pro
  void _watchAd() async {
    setState(() => _isLoadingAd = true);

    await AdService.instance.showRewardedAd(
      onRewarded: () {
        setState(() {
          _isLoadingAd = false;
        });

        if (AdService.instance.hasEnoughForPro) {
          ref.read(isPremiumProvider.notifier).togglePremium(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Geçici SubsTrack Pro aktifleştirildi! (Bu oturum için)'),
              backgroundColor: AppColors.activeGreen,
            ),
          );
          Navigator.of(context).pop();
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
}
