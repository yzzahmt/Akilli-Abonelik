import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';

class PremiumSplashScreen extends StatefulWidget {
  final Function(bool isKvkkAccepted) onInitializationComplete;

  const PremiumSplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen> with SingleTickerProviderStateMixin {
  bool _isKvkkAccepted = false;
  late AnimationController _exitController;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initializeApp();
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      // Run initialization tasks in parallel
      await Future.wait([
        DBService.instance.database,
        NotificationService.instance.init(),
        AdService.init(),
      ]);

      // Check KVKK status
      final prefs = await SharedPreferences.getInstance();
      _isKvkkAccepted = prefs.getBool('is_kvkk_accepted') ?? false;
    } catch (e) {
      debugPrint('Splash screen initialization error: $e');
    }

    final elapsedTime = DateTime.now().difference(startTime);
    const minDuration = Duration(milliseconds: 2800);

    // Enforce minimum splash screen duration for premium animation feel
    if (elapsedTime < minDuration) {
      await Future.delayed(minDuration - elapsedTime);
    }

    if (mounted) {
      await _exitController.forward();
      widget.onInitializationComplete(_isKvkkAccepted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _exitController,
          curve: Curves.easeInOutCubic,
        ),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.05).animate(
          CurvedAnimation(
            parent: _exitController,
            curve: Curves.easeInOutCubic,
          ),
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Premium Gradient Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF060913),
                        Color(0xFF0B1123),
                        Color(0xFF080C18),
                      ],
                    ),
                  ),
                ),
              ),

              // Glowing Ambient Light in the Center
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentPurple.withOpacity(0.08),
                  ),
                  child: Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD700).withOpacity(0.03),
                      ),
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(duration: 2.seconds, begin: 0.8, end: 1.2, curve: Curves.easeInOutSine),
              ),

              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container with Glassmorphic Border and Glow
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            AppColors.accentPurple.withOpacity(0.4),
                            const Color(0xFFFFD700).withOpacity(0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPurple.withOpacity(0.25),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(29),
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                        .animate()
                        .fade(duration: 800.ms, curve: Curves.easeOut)
                        .scaleXY(
                          begin: 0.5,
                          end: 1.0,
                          duration: 1000.ms,
                          curve: Curves.elasticOut,
                        )
                        .then(delay: 200.ms)
                        // Metallic Shine Sweep
                        .shimmer(
                          duration: 1800.ms,
                          color: Colors.white.withOpacity(0.25),
                          angle: 45,
                        ),

                    const SizedBox(height: 32),

                    // App Title
                    Text(
                      'SubsTrack',
                      style: GoogleFonts.orbitron(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.textPrimary,
                      ),
                    )
                        .animate()
                        .fade(delay: 500.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutCubic)
                        .then(delay: 100.ms)
                        // Elegant Title Shimmer
                        .shimmer(
                          duration: 1200.ms,
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                        ),

                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      'Abonelik Takip Asistanı',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        color: AppColors.textSecondary,
                      ),
                    )
                        .animate()
                        .fade(delay: 850.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOutCubic),
                  ],
                ),
              ),

              // Premium Branding / Loading indicator at bottom
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sleek customized line progress indicator
                      SizedBox(
                        width: 80,
                        height: 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: const LinearProgressIndicator(
                            backgroundColor: Color(0x11FFFFFF),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                          ),
                        ),
                      )
                          .animate()
                          .fade(delay: 1200.ms, duration: 500.ms),
                      const SizedBox(height: 16),
                      Text(
                        'Y A Z I F Y',
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      )
                          .animate()
                          .fade(delay: 1400.ms, duration: 500.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
