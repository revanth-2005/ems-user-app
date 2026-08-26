import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Primary pill-shaped gradient button.
/// Internally this is where a premium_ui_kit component would be integrated.
///
/// Usage:
/// ```dart
/// AppPrimaryButton(text: 'Continue', onPressed: () {})
/// ```
class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;
  final double? fontSize;
  final Color? backgroundColor;
  final Gradient? gradient;

  const AppPrimaryButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.fontSize,
    this.backgroundColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (gradient == null && backgroundColor != null && onPressed != null)
              ? backgroundColor
              : null,
          gradient: onPressed == null
              ? LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400])
              : (gradient ?? (backgroundColor == null ? AppColors.primaryGradient : null)),
          borderRadius: BorderRadius.circular(50),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: MaterialButton(
          onPressed: (isLoading || onPressed == null) ? null : onPressed,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: (fontSize != null ? fontSize! + 2 : 18)),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fontSize ?? 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

/// Outlined secondary button — purple border, transparent fill.
class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const AppSecondaryButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: (isLoading || onPressed == null) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onPressed == null
                ? Colors.grey.shade300
                : AppColors.primary,
            width: 1.8,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
          foregroundColor: AppColors.primary,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.primary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

