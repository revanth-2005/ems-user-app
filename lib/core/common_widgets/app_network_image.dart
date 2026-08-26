import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import 'app_loader.dart';

/// Project-level wrapper for images with:
/// 1. Automatic URL normalization — MinIO URLs are passed through unchanged (host preserved from API)
/// 2. Disk-cached decoding via CachedNetworkImage (background thread, no ANR on low-end devices)
/// 3. Letter-initial placeholder when URL is null or unreachable
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? errorWidget;
  final String? categoryHint;
  final String? titleHint;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.errorWidget,
    this.categoryHint,
    this.titleHint,
  });

  /// Cache-bust version — increment this whenever MinIO files are re-uploaded
  /// to force CachedNetworkImage to download fresh copies.
  static const String _cacheV = 'v=6';

  /// Normalizes any backend-provided media URL.
  /// For MinIO URLs (port 6006 or /ems-media/ paths), strips stale query params
  /// and appends [_cacheV] so stale disk-cached images are never served.
  /// The MinIO host from the API response is preserved as-is — do NOT rewrite
  /// it, as the API's MinIO host is the authoritative source of media files.
  static String? normalizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();

    // MinIO endpoint — strip old query params and append fresh cache-bust version
    if (trimmed.contains(':6006') || trimmed.contains('/ems-media/')) {
      final cleanPath = trimmed.split('?').first;
      return '$cleanPath?$_cacheV';
    }

    // Relative /ems-media/ paths — prepend active MinIO host
    if (trimmed.startsWith('/ems-media/')) {
      final path = trimmed.split('?').first;
      return 'http://${ApiConstants.serverHost}:6006$path?$_cacheV';
    }
    if (trimmed.startsWith('ems-media/')) {
      final path = trimmed.split('?').first;
      return 'http://${ApiConstants.serverHost}:6006/$path?$_cacheV';
    }
    if (trimmed.startsWith('packages/') ||
        trimmed.startsWith('services/') ||
        trimmed.startsWith('events/') ||
        trimmed.startsWith('categories/') ||
        trimmed.startsWith('organizers/') ||
        trimmed.startsWith('users/')) {
      final path = trimmed.split('?').first;
      return 'http://${ApiConstants.serverHost}:6006/ems-media/$path?$_cacheV';
    }
    if (trimmed.startsWith('/packages/') ||
        trimmed.startsWith('/services/') ||
        trimmed.startsWith('/events/') ||
        trimmed.startsWith('/categories/') ||
        trimmed.startsWith('/organizers/') ||
        trimmed.startsWith('/users/')) {
      final path = trimmed.split('?').first;
      return 'http://${ApiConstants.serverHost}:6006/ems-media$path?$_cacheV';
    }

    // Pass all other absolute URLs through unchanged
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeUrl(url);
    final hasUrl = normalized != null && normalized.isNotEmpty;
    final isVideo = hasUrl &&
        (normalized.toLowerCase().endsWith('.mp4') ||
            normalized.toLowerCase().endsWith('.mov'));

    Widget imageWidget;
    if (isVideo) {
      imageWidget = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentRose.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'VIDEO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (hasUrl) {
      imageWidget = CachedNetworkImage(
        imageUrl: normalized,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => AppShimmerBox(
          width: width ?? double.infinity,
          height: height ?? 120,
          borderRadius: borderRadius,
        ),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildLetterPlaceholder(context, width, height),
      );
    } else {
      imageWidget = errorWidget ?? _buildLetterPlaceholder(context, width, height);
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildLetterPlaceholder(BuildContext context, double? w, double? h) {
    final isDark = AppColors.isDark(context);
    final hasTitle = titleHint?.trim().isNotEmpty == true;
    final words = hasTitle
        ? titleHint!.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final initial = words.isNotEmpty
        ? (words.length == 1
            ? words[0][0].toUpperCase()
            : '${words[0][0]}${words[1][0]}'.toUpperCase())
        : '';

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (initial.isNotEmpty) ...[
              Container(
                width: (w != null && w < 65) ? 36 : 44,
                height: (w != null && w < 65) ? 36 : 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: (w != null && w < 65)
                        ? (initial.length > 1 ? 12 : 14)
                        : (initial.length > 1 ? 14 : 16),
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                Icons.business_rounded,
                color: AppColors.getTextMuted(context),
                size: (w != null && w < 60) ? 22 : 28,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

