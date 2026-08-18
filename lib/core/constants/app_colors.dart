import 'package:flutter/material.dart';

class AppColors {
  // ── Background Layers ──────────────────────────────────────────────────────
  static const Color lightBg        = Color(0xFFF5F3FF); // soft lavender page bg
  static const Color lightSurface   = Color(0xFFFFFFFF); // white surface / nav bar
  static const Color lightCard      = Color(0xFFFFFFFF); // white card surface
  static const Color lightCardAlt   = Color(0xFFF0EDFF); // muted lavender alt card
  static const Color lightBorder    = Color(0xFFE8E4F8); // subtle lavender border

  // ── Keep dark tokens for backward compat (organizer accent surfaces) ───────
  static const Color darkBg         = Color(0xFFF5F3FF);
  static const Color darkSurface    = Color(0xFFFFFFFF);
  static const Color darkCard       = Color(0xFFFFFFFF);
  static const Color darkCardAlt    = Color(0xFFF0EDFF);
  static const Color darkCardBorder = Color(0xFFE8E4F8);

  // ── Primary Brand ─────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF6C63FF); // reference violet-blue
  static const Color primaryDark    = Color(0xFF5B4FCF); // deeper violet
  static const Color primaryLight   = Color(0xFF8B7FF5); // lighter violet
  static const Color secondary      = Color(0xFFA855F7); // purple-500

  // ── Gradient definitions ───────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B4FCF), Color(0xFF8B7FF5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
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

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary        = Color(0xFF1A1A2E); // near-black
  static const Color textSecondary      = Color(0xFF7B7B9A); // medium gray-violet
  static const Color textMuted          = Color(0xFFADADC9); // light gray-violet

  // backward-compat aliases
  static const Color darkTextPrimary    = textPrimary;
  static const Color darkTextSecondary  = textSecondary;
  static const Color darkTextMuted      = textMuted;

  // ── Accents ───────────────────────────────────────────────────────────────
  static const Color accent         = Color(0xFFF43F5E); // rose accent
  static const Color success        = Color(0xFF10B981); // emerald green
  static const Color warning        = Color(0xFFF59E0B); // amber
  static const Color error          = Color(0xFFEF4444); // red
  static const Color accentEmerald  = Color(0xFF10B981);
  static const Color accentAmber    = Color(0xFFF59E0B);
  static const Color accentRose     = Color(0xFFF43F5E);
  static const Color accentCyan     = Color(0xFF06B6D4);

  // ── Status colours ────────────────────────────────────────────────────────
  static const Color statusCompleted    = Color(0xFF10B981);
  static const Color statusRescheduled  = Color(0xFFF59E0B);
  static const Color statusCancelled    = Color(0xFFF43F5E);
  static const Color statusPending      = Color(0xFF6C63FF);
  static const Color statusRequested    = Color(0xFFF59E0B);
  static const Color statusAccepted     = Color(0xFF10B981);

  // ── Shared shadow ─────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
