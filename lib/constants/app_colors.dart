import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF080C18);
  static const Color surface1 = Color(0xFF0F1629);
  static const Color surface2 = Color(0xFF161D35);

  static const Color accentPurple = Color(0xFF7C6AF7);
  static const Color accentPurpleLight = Color(0xFF9D8FF9);

  static const Color activeGreen = Color(0xFF34D399);
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color expensiveRed = Color(0xFFF87171);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textMuted = Color(0xFF4A5568);

  static const Color borderSubtle = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color borderMedium = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)

  // Glassmorphism panels (rgba(255,255,255,0.04))
  static const Color glassBg = Color(0x0AFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  static BoxDecoration get backgroundGradient => const BoxDecoration(
        color: background,
      );

  static BoxDecoration get buttonGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C6AF7), Color(0xFF6C5CE7)],
        ),
      );
}
