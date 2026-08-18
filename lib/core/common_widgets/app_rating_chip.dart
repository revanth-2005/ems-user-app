import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppRatingChip extends StatelessWidget {
  final double rating;
  final int? reviewsCount;

  const AppRatingChip({
    super.key,
    required this.rating,
    this.reviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentAmber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.accentAmber.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: AppColors.accentAmber,
          ),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (reviewsCount != null) ...[
            const SizedBox(width: 3),
            Text(
              '($reviewsCount)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
