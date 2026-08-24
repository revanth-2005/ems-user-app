import 'package:flutter/material.dart';

class AppColors {
  // ── Dark Palette (Cinematic Netflix Dark) ──────────────────────────────────
  static const Color darkBg           = Color(0xFF0A0A0A);
  static const Color darkSurface      = Color(0xFF141414);
  static const Color darkCard         = Color(0xFF1A1A1A);
  static const Color darkCardAlt      = Color(0xFF262626);
  static const Color darkBorder       = Color(0xFF2E2E2E);
  static const Color darkCardBorder   = Color(0xFF2E2E2E);

  static const Color darkTextPrimary   = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFABABAB);
  static const Color darkTextMuted     = Color(0xFF737373);

  // ── Light Palette (Clean, High-End White) ──────────────────────────────────
  static const Color whiteBg          = Color(0xFFF7F8FA);
  static const Color whiteSurface     = Color(0xFFFFFFFF);
  static const Color whiteCard        = Color(0xFFFFFFFF);
  static const Color whiteCardAlt     = Color(0xFFF0F2F5);
  static const Color whiteBorder      = Color(0xFFE5E7EB);

  static const Color whiteTextPrimary   = Color(0xFF111827);
  static const Color whiteTextSecondary = Color(0xFF4B5563);
  static const Color whiteTextMuted     = Color(0xFF9CA3AF);

  // ── Backward-compatible static references (defaulting to dark) ───────────
  static const Color lightBg          = darkBg;
  static const Color lightSurface     = darkSurface;
  static const Color lightCard        = darkCard;
  static const Color lightCardAlt     = darkCardAlt;
  static const Color lightBorder      = darkBorder;

  static const Color textPrimary      = darkTextPrimary;
  static const Color textSecondary    = darkTextSecondary;
  static const Color textMuted        = darkTextMuted;

  // ── Primary Brand (Signature Red) ─────────────────────────────────────────
  static const Color primary          = Color(0xFFE50914);
  static const Color primaryDark      = Color(0xFFB20710);
  static const Color primaryLight     = Color(0xFFFF2B35);
  static const Color secondary        = Color(0xFFB20710);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFB20710), Color(0xFFE50914)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF1A0000), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardImageOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroOverlay = LinearGradient(
    colors: [Color(0x00000000), Color(0xE0000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Accents & Status ───────────────────────────────────────────────────────
  static const Color accent           = Color(0xFFE50914);
  static const Color success          = Color(0xFF10B981);
  static const Color warning          = Color(0xFFF59E0B);
  static const Color error            = Color(0xFFE50914);
  static const Color accentEmerald    = Color(0xFF10B981);
  static const Color accentAmber      = Color(0xFFF59E0B);
  static const Color accentRose       = Color(0xFFE50914);
  static const Color accentCyan       = Color(0xFF06B6D4);
  static const Color accentTeal       = Color(0xFF14B8A6);
  static const Color accentIndigo     = Color(0xFF6366F1);

  static const Color statusCompleted  = Color(0xFF10B981);
  static const Color statusRescheduled= Color(0xFFF59E0B);
  static const Color statusCancelled  = Color(0xFFE50914);
  static const Color statusPending    = Color(0xFFE50914);
  static const Color statusRequested  = Color(0xFFF59E0B);
  static const Color statusAccepted   = Color(0xFF10B981);

  // ── Dynamic Theme-Aware Context Helpers ────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBg(BuildContext context) =>
      isDark(context) ? darkBg : whiteBg;

  static Color getBackground(BuildContext context) =>
      isDark(context) ? darkBg : whiteBg;

  static Color getSurface(BuildContext context) =>
      isDark(context) ? darkSurface : whiteSurface;

  static Color getCard(BuildContext context) =>
      isDark(context) ? darkCard : whiteCard;

  static Color getCardAlt(BuildContext context) =>
      isDark(context) ? darkCardAlt : whiteCardAlt;

  static Color getBorder(BuildContext context) =>
      isDark(context) ? darkBorder : whiteBorder;

  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : whiteTextPrimary;

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : whiteTextSecondary;

  static Color getTextMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : whiteTextMuted;

  // ── Theme-aware Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFFE50914).withValues(alpha: 0.10),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> getCardShadow(BuildContext context) => isDark(context)
      ? cardShadow
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
}
