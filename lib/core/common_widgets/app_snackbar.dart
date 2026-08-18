import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Shows a floating SnackBar with consistent styling.
///
/// Usage:
/// ```dart
/// AppSnackbar.show(context, message: 'Saved!', type: SnackbarType.success);
/// ```
enum SnackbarType { info, success, error, warning }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = {
      SnackbarType.success: AppColors.accentEmerald,
      SnackbarType.error: AppColors.accentRose,
      SnackbarType.warning: AppColors.accentAmber,
      SnackbarType.info: AppColors.primary,
    };

    final icons = {
      SnackbarType.success: Icons.check_circle_rounded,
      SnackbarType.error: Icons.error_rounded,
      SnackbarType.warning: Icons.warning_amber_rounded,
      SnackbarType.info: Icons.info_rounded,
    };

    final color = colors[type]!;
    final icon = icons[type]!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction?.call();
                  },
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
