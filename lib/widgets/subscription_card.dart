import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/subscription.dart';
import '../constants/app_colors.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final double convertedPriceInTRY;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.convertedPriceInTRY,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSoon = _isDueSoon();
    final bool isExpensive = convertedPriceInTRY > 300;
    final Color accentColor = isSoon
        ? AppColors.warningAmber
        : isExpensive
            ? AppColors.expensiveRed
            : AppColors.activeGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Emoji Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    subscription.emoji.isNotEmpty ? subscription.emoji : '📱',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + renewal info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name.isNotEmpty ? subscription.name : 'Abonelik',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Her ayın ${subscription.renewalDay}\'inde',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Price + badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₺${convertedPriceInTRY.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSoon
                          ? '⚡ ${_daysUntilRenewal()} gün'
                          : isExpensive
                              ? '🔥 Pahalı'
                              : '✓ Aktif',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDueSoon() {
    final now = DateTime.now();
    final dueDay = subscription.renewalDay;
    final daysLeft = dueDay - now.day;
    return daysLeft >= 0 && daysLeft <= 5;
  }

  int _daysUntilRenewal() {
    final now = DateTime.now();
    return (subscription.renewalDay - now.day).clamp(0, 31);
  }
}
