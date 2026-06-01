import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/app_colors.dart';
import '../utils/export_utils.dart';
import '../utils/translations.dart';
import '../services/notification_service.dart';
import '../services/backup_service.dart';
import 'insights_screen.dart';
import 'kvkk_screen.dart';
import 'ai_assistant_screen.dart';
import 'pro_unlock_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsOn = true;
  int _reminderDays = 1;
  String _currencyDisplayMode = 'TL + USD';
  bool _monthlySummaryOn = false; 
  String _appVersion = ''; 
  bool _showSplashAnimation = true;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showSplashAnimation = false);
    });
  }

  // SubsTrack yeni özellik — Gerçek versiyon (Bölüm 12)
  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    } catch (_) {
      if (mounted) setState(() => _appVersion = '2.0.0');
    }
  }

  void _shareApp(String lang) {
    final appText = lang == 'TR'
        ? '''📱 SubsTrack — Abonelik Takibi

Netflix, Spotify, YouTube Premium ve daha fazlasını tek uygulamada takip et!

✅ Aylık & yıllık harcamalarını gör
✅ Yenileme bildirimleri al
✅ Dolar bazlı abonelikleri otomatik dönüştür

🔗 Hemen indir: https://play.google.com/store/apps/details?id=com.yzzahmt.abonetakip'''
        : '''📱 SubsTrack — Subscription Tracker

Manage Netflix, Spotify, YouTube Premium and more in one app!

✅ See monthly & yearly spending
✅ Get renewal notifications
✅ Auto-convert USD-based subscriptions

🔗 Download now: https://play.google.com/store/apps/details?id=com.yzzahmt.abonetakip''';

    SharePlus.instance.share(
      ShareParams(text: appText, subject: AppTranslations.translate(lang, 'app_title')),
    );
  }

  void _showPremiumDialog(BuildContext context, String lang) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProUnlockScreen()),
    );
  }

  Widget _proFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.activeGreen, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  void _showProLockedSnackbar(String lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              lang == 'TR' ? 'Bu özellik SubsTrack Pro gerektirir.' : 'This feature requires SubsTrack Pro.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.accentPurple,
        action: SnackBarAction(
          label: lang == 'TR' ? 'Pro\'ya Geç' : 'Get Pro',
          textColor: Colors.white,
          onPressed: () => _showPremiumDialog(context, lang),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final usdRate = subState.rates['USD'] ?? 32.50;
    final isPremium = ref.watch(isPremiumProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _showSplashAnimation
          ? Center(
              child: const Icon(Icons.settings_rounded, size: 72, color: AppColors.accentPurple)
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 1200.ms)
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 700.ms, curve: Curves.easeOutBack)
                  .fade(duration: 300.ms),
            )
          : Stack(
              children: [
                SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.translate(lang, 'settings_title'),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        AppTranslations.translate(lang, 'settings_subtitle'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '⭐ PRO',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ).animate().fade().slideX(),
              const SizedBox(height: 18),

              // Premium Banner Card
              if (!isPremium)
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProUnlockScreen()),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C6AF7), Color(0xFF6C5CE7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPurple.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⭐ SubsTrack Pro',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang == 'TR'
                                    ? 'Reklamları kaldır, tüm özellikleri aç.'
                                    : 'Remove ads, unlock all features.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textPrimary.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textPrimary,
                            foregroundColor: AppColors.accentPurple,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProUnlockScreen()),
                          ),
                          child: Text(
                            lang == 'TR' ? 'Pro\'ya Geç' : 'Get Pro',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(duration: 350.ms)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'TR' ? 'SubsTrack Pro Aktif!' : 'SubsTrack Pro Active!',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            lang == 'TR' ? 'Tüm Pro özellikler kullanılabilir.' : 'All Pro features available.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fade(duration: 350.ms),

              const SizedBox(height: 24),

              // Language Settings
              _buildSectionTitle(AppTranslations.translate(lang, 'language')),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                ),
                child: ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.accentPurple),
                  title: Text(
                    AppTranslations.translate(lang, 'language'),
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: lang,
                      dropdownColor: AppColors.surface1,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: 'TR', child: Text('Türkçe')),
                        DropdownMenuItem(value: 'EN', child: Text('English')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(languageProvider.notifier).setLanguage(val);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),


              // Notification Settings
              _buildSectionTitle(AppTranslations.translate(lang, 'notifications')),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: Text(
                        AppTranslations.translate(lang, 'renewal_notifications'),
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      activeTrackColor: AppColors.accentPurple,
                      value: _notificationsOn,
                      onChanged: (val) {
                        setState(() {
                          _notificationsOn = val;
                        });
                      },
                    ),
                    if (_notificationsOn) ...[
                      const Divider(color: Color(0x11FFFFFF), height: 1),
                      ListTile(
                        title: Text(
                          AppTranslations.translate(lang, 'reminder_days_title'),
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _reminderDays,
                            dropdownColor: AppColors.surface1,
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                            items: [
                              DropdownMenuItem(value: 1, child: Text(lang == 'TR' ? '1 Gün' : '1 Day')),
                              DropdownMenuItem(value: 2, child: Text(lang == 'TR' ? '2 Gün' : '2 Days')),
                              DropdownMenuItem(value: 3, child: Text(lang == 'TR' ? '3 Gün' : '3 Days')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _reminderDays = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                    // SubsTrack yeni özellik — Bildirim test butonu (Bölüm 12)
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_active_rounded, color: AppColors.accentPurple),
                      title: Text(lang == 'TR' ? 'Test Bildirimi Gönder' : 'Send Test Notification',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      onTap: () async {
                        await NotificationService.showTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(lang == 'TR' ? '🔔 Test bildirimi gönderildi!' : '🔔 Test notification sent!'),
                              backgroundColor: AppColors.activeGreen,
                            ),
                          );
                        }
                      },
                    ),
                    // SubsTrack yeni özellik — Aylık özet switch (Bölüm 12)
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    SwitchListTile.adaptive(
                      title: Text(lang == 'TR' ? 'Aylık Özet Bildirimi' : 'Monthly Summary',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                      subtitle: Text(lang == 'TR' ? "Her ayın 1'inde harcama özeti" : "Spending summary on 1st",
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      activeTrackColor: AppColors.accentPurple,
                      value: _monthlySummaryOn,
                      onChanged: (val) async {
                        setState(() => _monthlySummaryOn = val);
                        if (val) {
                          await NotificationService.scheduleMonthlySummary();
                        } else {
                          await NotificationService.cancel(9999);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Currency Settings
              _buildSectionTitle(AppTranslations.translate(lang, 'currency_display_title')),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                ),
                child: ListTile(
                  title: Text(
                    AppTranslations.translate(lang, 'currency_display_title'),
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    lang == 'TR'
                        ? 'Güncel Kur: 1 USD ≈ ₺${usdRate.toStringAsFixed(2)}'
                        : 'Exchange Rate: 1 USD ≈ ₺${usdRate.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currencyDisplayMode,
                      dropdownColor: AppColors.surface1,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                      items: [
                        DropdownMenuItem(value: 'TL Only', child: Text(lang == 'TR' ? 'Sadece TL' : 'Only TL')),
                        DropdownMenuItem(value: 'TL + USD', child: Text(lang == 'TR' ? 'TL + USD' : 'TL + USD')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _currencyDisplayMode = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Pro Features Section
              _buildSectionTitle(AppTranslations.translate(lang, 'advanced_features')),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.insights_rounded,
                        color: isPremium ? AppColors.accentPurple : AppColors.textMuted,
                      ),
                      title: Row(
                        children: [
                          Text(AppTranslations.translate(lang, 'smart_insights'), style: GoogleFonts.inter(fontSize: 14, color: isPremium ? AppColors.textPrimary : AppColors.textMuted)),
                          const SizedBox(width: 6),
                          if (!isPremium) _buildProBadge(),
                        ],
                      ),
                      trailing: isPremium ? const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14) : const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                      onTap: () {
                        if (!isPremium) {
                          _showProLockedSnackbar(lang);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const InsightsScreen()),
                          );
                        }
                      },
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: isPremium ? AppColors.accentPurple : AppColors.textMuted,
                      ),
                      title: Row(
                        children: [
                          Text(AppTranslations.translate(lang, 'spending_limit'), style: GoogleFonts.inter(fontSize: 14, color: isPremium ? AppColors.textPrimary : AppColors.textMuted)),
                          const SizedBox(width: 6),
                          if (!isPremium) _buildProBadge(),
                        ],
                      ),
                      subtitle: isPremium && ref.watch(spendingLimitProvider) > 0 
                          ? Text('₺${ref.watch(spendingLimitProvider).toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))
                          : null,
                      trailing: isPremium ? null : const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                      onTap: () {
                        if (!isPremium) {
                          _showProLockedSnackbar(lang);
                        } else {
                          _showLimitDialog(context, ref, lang);
                        }
                      },
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.auto_awesome,
                        color: isPremium ? const Color(0xFF00F2FE) : AppColors.textMuted,
                      ),
                      title: Row(
                        children: [
                          Text(lang == 'TR' ? 'Yapay Zeka Asistanı' : 'AI Assistant', style: GoogleFonts.inter(fontSize: 14, color: isPremium ? AppColors.textPrimary : AppColors.textMuted)),
                          const SizedBox(width: 6),
                          if (!isPremium) _buildProBadge(),
                        ],
                      ),
                      trailing: isPremium ? const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14) : const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                      onTap: () {
                        if (!isPremium) {
                          _showProLockedSnackbar(lang);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const AIAssistantScreen()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Data Management
              _buildSectionTitle(AppTranslations.translate(lang, 'data_management')),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.file_download_rounded,
                        color: isPremium ? AppColors.accentPurple : AppColors.textMuted,
                      ),
                      title: Row(
                        children: [
                          Text(
                            AppTranslations.translate(lang, 'export_csv'),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isPremium ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (!isPremium) _buildProBadge(),
                        ],
                      ),
                      trailing: isPremium ? null : const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                      onTap: () async {
                        if (!isPremium) {
                          _showProLockedSnackbar(lang);
                        } else {
                          await ExportUtils.exportToCSV(subState.subscriptions);
                        }
                      },
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.calendar_month_rounded,
                        color: isPremium ? AppColors.accentPurple : AppColors.textMuted,
                      ),
                      title: Row(
                        children: [
                          Text(AppTranslations.translate(lang, 'export_calendar'), style: GoogleFonts.inter(fontSize: 14, color: isPremium ? AppColors.textPrimary : AppColors.textMuted)),
                          const SizedBox(width: 6),
                          if (!isPremium) _buildProBadge(),
                        ],
                      ),
                      trailing: isPremium ? null : const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                      onTap: () async {
                        if (!isPremium) {
                          _showProLockedSnackbar(lang);
                        } else {
                          await ExportUtils.exportToCalendar(subState.subscriptions);
                        }
                      },
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.backup_rounded,
                        color: isPremium ? AppColors.accentPurple : AppColors.textMuted,
                      ),
                      title: Row(
                        children: [
                          Text(AppTranslations.translate(lang, 'export_backup'), style: GoogleFonts.inter(fontSize: 14, color: isPremium ? AppColors.textPrimary : AppColors.textMuted)),
                          const SizedBox(width: 6),
                          if (!isPremium) _buildProBadge(),
                        ],
                      ),
                      trailing: isPremium ? null : const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                      onTap: () async {
                        if (!isPremium) {
                          _showProLockedSnackbar(lang);
                        } else {
                          await ExportUtils.exportBackupJSON(subState.subscriptions);
                        }
                      },
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore_rounded, color: AppColors.activeGreen),
                      title: Text(
                        lang == 'TR' ? 'Yedekten Yükle (JSON)' : 'Restore from JSON Backup',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        lang == 'TR' ? 'Tüm veriler birleştirilir' : 'Data is merged, not overwritten',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      onTap: () async {
                        final ok = await BackupService.import(context);
                        if (ok) ref.read(subscriptionProvider.notifier).fetchSubscriptions();
                      },
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.expensiveRed),
                      title: Text(
                        AppTranslations.translate(lang, 'clear_all_data'),
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              lang == 'TR' ? 'Emin misiniz?' : 'Are you sure?',
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              lang == 'TR' ? 'Tüm abonelikler kalıcı olarak silinecek.' : 'All subscriptions will be permanently deleted.',
                              style: GoogleFonts.inter(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text(lang == 'TR' ? 'Vazgeç' : 'Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  for (var sub in subState.subscriptions) {
                                    if (sub.id != null) {
                                      ref.read(subscriptionProvider.notifier).deleteSubscription(sub.id!);
                                    }
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(lang == 'TR' ? 'Tüm veriler temizlendi.' : 'All data cleared.'),
                                      backgroundColor: AppColors.expensiveRed,
                                    ),
                                  );
                                },
                                child: Text(lang == 'TR' ? 'Sil' : 'Delete', style: GoogleFonts.inter(color: AppColors.expensiveRed, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // About Section
              _buildSectionTitle(AppTranslations.translate(lang, 'about')),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                      title: Text(
                        AppTranslations.translate(lang, 'version'),
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      trailing: Text(
                        _appVersion.isNotEmpty ? 'v$_appVersion' : 'v2.0.0',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    // SubsTrack yeni özellik — KVKK tam ekran (Bölüm 10)
                    ListTile(
                      leading: const Icon(Icons.security_outlined, color: AppColors.accentPurple),
                      title: Text(lang == 'TR' ? 'KVKK / Gizlilik Politikası' : 'Privacy Policy (KVKK)',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const KvkkScreen(isReadOnly: true)),
                        );
                      },
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    // SubsTrack yeni özellik — Onboarding sıfırla (Bölüm 3)
                    ListTile(
                      leading: const Icon(Icons.restart_alt_rounded, color: AppColors.warningAmber),
                      title: Text(lang == 'TR' ? 'Tanıtımı Tekrar Göster' : 'Show Onboarding Again',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                      onTap: () async {
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('onboarding_done', false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(lang == 'TR'
                                    ? 'Tanıtım sıfırlandı. Uygulamayı yeniden başlatın.'
                                    : 'Onboarding reset. Restart the app.'),
                                backgroundColor: AppColors.warningAmber,
                              ),
                            );
                          }
                        } catch (_) {}
                      },
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: const Icon(Icons.star_outline_rounded, color: AppColors.warningAmber),
                      title: Text(
                        AppTranslations.translate(lang, 'rate_app'),
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(lang == 'TR' ? 'Play Store değerlendirme sayfası açılıyor...' : 'Opening Play Store page...'),
                            backgroundColor: AppColors.warningAmber,
                          ),
                        );
                      },
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: const Icon(Icons.share_outlined, color: AppColors.activeGreen),
                      title: Text(
                        AppTranslations.translate(lang, 'share_app'),
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                      onTap: () => _shareApp(lang),
                    ),
                    const Divider(color: Color(0x11FFFFFF), height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.accentPurple),
                      title: Text(
                        lang == 'TR' ? 'Gizlilik Politikası' : 'Privacy Policy',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.textMuted, size: 14),
                      onTap: () async {
                        final url = Uri.parse('https://yazify.agency/privacy/subs-track');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildYazifyButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      if (_showSplashAnimation)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: AppColors.background.withValues(alpha: 0.8),
              child: Center(
                child: const Icon(Icons.settings_rounded, color: AppColors.accentPurple, size: 60)
                    .animate()
                    .rotate(begin: 0, end: 1.0, duration: 600.ms, curve: Curves.easeInOutCubic)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(40, 40), duration: 600.ms, curve: Curves.easeInQuint)
                    .fade(end: 0, duration: 200.ms, delay: 400.ms),
              ),
            ).animate().fade(end: 0, duration: 250.ms, delay: 450.ms),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'PRO',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.accentPurple,
        ),
      ),
    );
  }

  void _showLimitDialog(BuildContext context, WidgetRef ref, String lang) {
    final controller = TextEditingController(
      text: ref.read(spendingLimitProvider) > 0 ? ref.read(spendingLimitProvider).toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          lang == 'TR' ? 'Aylık Harcama Limiti (TL)' : 'Monthly Spending Limit',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Örn: 500',
            hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang == 'TR' ? 'İptal' : 'Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              ref.read(spendingLimitProvider.notifier).setLimit(val);
              Navigator.of(ctx).pop();
            },
            child: Text(
              lang == 'TR' ? 'Kaydet' : 'Save',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYazifyButton() {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://www.yazify.net'), mode: LaunchMode.externalApplication),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              AppColors.accentPurple.withValues(alpha: 0.8),
              const Color(0xFF00F2FE), // Cyan
              AppColors.accentPurple.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurple.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D121F),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.rocket_launch_rounded,
                color: Color(0xFF00F2FE),
                size: 22,
              ).animate(onPlay: (c) => c.repeat())
               .shimmer(duration: 2.seconds, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DESIGNED & DEVELOPED BY',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFF00F2FE)],
                    ).createShader(bounds),
                    child: Text(
                      'YAZIFY.NET',
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        letterSpacing: 3,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.auto_awesome,
                color: AppColors.accentPurple,
                size: 20,
              ).animate(onPlay: (c) => c.repeat())
               .scale(duration: 1500.ms, begin: const Offset(1, 1), end: const Offset(1.3, 1.3), curve: Curves.easeInOut)
               .then()
               .scale(duration: 1500.ms, begin: const Offset(1.3, 1.3), end: const Offset(1, 1), curve: Curves.easeInOut),
            ],
          ),
        ),
      ).animate()
       .fadeIn(duration: 1.seconds)
       .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic)
       .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.1)),
    );
  }
}
