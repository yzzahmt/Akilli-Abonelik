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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Video':
        return Colors.blue;
      case 'Müzik':
        return Colors.green;
      case 'Yapay Zeka':
        return Colors.purple;
      case 'Bulut':
      case 'Bulut Depolama':
        return Colors.cyan;
      case 'Yazılım/Araçlar':
      case 'Üretkenlik':
        return Colors.orange;
      case 'Oyun':
        return Colors.redAccent;
      case 'Eğitim':
        return Colors.teal;
      default:
        return AppColors.borderSubtle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSoon = _isDueSoon();
    final bool isExpensive = convertedPriceInTRY > 500;
    final bool isMedium = convertedPriceInTRY >= 150 && convertedPriceInTRY <= 500;
    final bool isCheap = convertedPriceInTRY < 150;
    final bool isActive = subscription.isActive;

    // Kırmızı çerçeve <3 gün eşiği
    final Color borderColor = isSoon 
        ? AppColors.expensiveRed.withValues(alpha: 0.6) 
        : AppColors.borderSubtle;

    final categoryColor = _getCategoryColor(subscription.category);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isActive ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isSoon ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Sol renkli çizgi (Kategori)
              Positioned(
                left: 0,
                top: 20,
                bottom: 20,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4)),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 16, top: 16, bottom: 16),
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  subscription.name.isNotEmpty ? subscription.name : 'Abonelik',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (subscription.isFavorite == 1) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded, color: AppColors.warningAmber, size: 16),
                              ]
                            ],
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
                        
                        // Badge logic
                        if (!isActive)
                          _buildBadge('Pasif', AppColors.textMuted, Icons.pause_circle_filled_rounded)
                        else if (isSoon)
                          _buildBadge('${_daysUntilRenewal()} gün', AppColors.expensiveRed, Icons.warning_rounded)
                        else if (isExpensive)
                          _buildBadge('Pahalı', AppColors.expensiveRed, Icons.local_fire_department_rounded)
                        else if (isMedium)
                          _buildBadge('Orta', AppColors.warningAmber, Icons.remove_circle_outline_rounded)
                        else if (isCheap)
                          _buildBadge('Uygun', AppColors.activeGreen, Icons.check_circle_outline_rounded)
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  bool _isDueSoon() {
    final now = DateTime.now();
    final dueDay = subscription.renewalDay;
    final daysLeft = dueDay - now.day;
    return daysLeft >= 0 && daysLeft <= 3;
  }

  int _daysUntilRenewal() {
    final now = DateTime.now();
    return (subscription.renewalDay - now.day).clamp(0, 31);
  }
}
