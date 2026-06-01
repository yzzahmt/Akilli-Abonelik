import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kvkk_screen.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'dart:math' as math;
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _sequenceController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _initServicesAndPlay();
  }

  Future<void> _initServicesAndPlay() async {
    try {
      await Future.wait([
        DBService.instance.database,
        NotificationService.init(),
        AdService.init(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );
    } catch (e) {
      debugPrint('Splash screen initialization error: $e');
    }

    if (mounted) {
      await _sequenceController.forward();
      _navigate();
    }
  }

  void _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final bool kvkk = prefs.getBool('kvkk_accepted') ?? false;
    final bool onboarding = prefs.getBool('onboarding_done') ?? false;

    if (!mounted) return;

    if (!kvkk) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const KvkkScreen(),
        transitionDuration: Duration.zero,
      ));
    } else if (!onboarding) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OnboardingScreen(onComplete: () {
          Navigator.pushReplacement(context, PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionDuration: Duration.zero,
          ));
        }),
        transitionDuration: Duration.zero,
      ));
    } else {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionDuration: Duration.zero,
      ));
    }
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sequenceController,
      builder: (context, child) {
        final time = _sequenceController.value * 4200;

        // Adım 2: 400-700ms bg fade in & light point appear
        final bgOpacity = _getVal(time, 400, 700, 0.0, 1.0);
        final lightPointOpacity = _getVal(time, 400, 700, 0.0, 1.0);

        // Adım 3: 700-1200ms grow to 60px circle
        final baseSize = _getVal(time, 700, 1200, 4.0, 120.0);
        final baseGlow = _getVal(time, 700, 1200, 0.0, 40.0);

        // Adım 4: 1200-1800ms morph to rounded square
        final radius = _getVal(time, 1200, 1800, 60.0, 24.0);
        final sScale = _getVal(time, 1200, 1800, 0.0, 1.0);

        // Adım 5: 1800-2400ms logo crossfade
        final logoOpacity = _getVal(time, 1800, 2400, 0.0, 1.0);
        
        // Adım 6: 2400-3000ms "SubsTrack" slides down
        final titleOpacity = _getVal(time, 2400, 3000, 0.0, 1.0);
        final titleOffset = _getVal(time, 2400, 3000, -20.0, 0.0);

        // Adım 7: 3000-3400ms subtitle fade in, YAZIFY letter spacing
        final subtitleOpacity = _getVal(time, 3000, 3400, 0.0, 1.0);
        final yazifySpacing = _getVal(time, 3000, 3400, 0.0, 8.0);
        final yazifyOpacity = _getVal(time, 3000, 3400, 0.0, 1.0);

        // Adım 8: 3400-3800ms purple bar fill
        final barFill = _getVal(time, 3400, 3800, 0.0, 1.0);

        // Adım 9: 3800-4200ms slide out
        final screenSlide = _getVal(time, 3800, 4200, 0.0, -MediaQuery.of(context).size.height);

        return Transform.translate(
          offset: Offset(0, screenSlide),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                if (bgOpacity > 0)
                  Opacity(
                    opacity: bgOpacity,
                    child: Container(color: const Color(0xFF0A0D1A)),
                  ),

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (baseSize > 0)
                              Container(
                                width: baseSize,
                                height: baseSize,
                                decoration: BoxDecoration(
                                  color: logoOpacity < 1.0 ? const Color(0xFF6C5CE7) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(radius),
                                  boxShadow: logoOpacity < 1.0 && baseGlow > 0 ? [
                                    BoxShadow(
                                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.8),
                                      blurRadius: baseGlow,
                                      spreadRadius: baseGlow / 4,
                                    )
                                  ] : null,
                                ),
                                child: Center(
                                  child: Transform.scale(
                                    scale: sScale,
                                    child: Opacity(
                                      opacity: 1.0 - logoOpacity,
                                      child: const Text(
                                        'S',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            if (lightPointOpacity > 0 && baseSize < 10)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),

                            if (logoOpacity > 0)
                              Opacity(
                                opacity: logoOpacity,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _rotationController,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _rotationController.value * 2 * math.pi,
                                          child: CustomPaint(
                                            size: const Size(124, 124),
                                            painter: GradientBorderPainter(
                                              radius: 24,
                                              strokeWidth: 3,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        color: Colors.black,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Image.asset(
                                          'assets/app_icon.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (time >= 2400)
                        Transform.translate(
                          offset: Offset(0, titleOffset),
                          child: Opacity(
                            opacity: titleOpacity,
                            child: Text(
                              'SubsTrack',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (time >= 3000)
                        Opacity(
                          opacity: subtitleOpacity,
                          child: Text(
                            'Abonelik Takip Asistanı',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFB0B3BE),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (time >= 3000)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: yazifyOpacity,
                          child: Text(
                            'YAZIFY',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: yazifySpacing,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (time >= 3400)
                          Container(
                            width: 120,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: barFill,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C5CE7),
                                  borderRadius: BorderRadius.circular(2),
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
        );
      },
    );
  }

  double _getVal(double time, double startMs, double endMs, double startVal, double endVal) {
    if (time <= startMs) return startVal;
    if (time >= endMs) return endVal;
    final t = (time - startMs) / (endMs - startMs);
    final curve = Curves.easeInOut.transform(t);
    return startVal + (endVal - startVal) * curve;
  }
}

class GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;

  GradientBorderPainter({required this.radius, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF6C5CE7),
          Color(0x006C5CE7),
          Color(0xFF6C5CE7),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
