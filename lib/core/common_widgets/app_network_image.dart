import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import 'app_loader.dart';

/// Project-level wrapper for images with:
/// 1. Automatic URL normalization (routing MinIO/LAN URLs via ApiConstants serverHost:6006)
/// 2. Live HTTP decoding using Image.network so live API images render immediately
/// 3. Curated aesthetic fallbacks when URL is null or unreachable
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

  /// Normalizes any backend-provided media URL, routing MinIO URLs through
  /// the local ADB reverse proxy (port 6008) so connected mobile devices can fetch them.
  static String? normalizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();

    // MinIO endpoint (port 6006 or /ems-media/ path) -> route via reverse proxy on port 6008
    if (trimmed.contains(':6006') || trimmed.contains('/ems-media/')) {
      final emsMediaIndex = trimmed.indexOf('/ems-media/');
      if (emsMediaIndex != -1) {
        final path = trimmed.substring(emsMediaIndex);
        return 'http://${ApiConstants.serverHost}:6008$path';
      }
    }

    // Relative paths
    if (trimmed.startsWith('/ems-media/')) {
      return 'http://${ApiConstants.serverHost}:6008$trimmed';
    }
    if (trimmed.startsWith('ems-media/')) {
      return 'http://${ApiConstants.serverHost}:6008/$trimmed';
    }
    if (trimmed.startsWith('packages/') ||
        trimmed.startsWith('services/') ||
        trimmed.startsWith('events/')) {
      return 'http://${ApiConstants.serverHost}:6008/ems-media/$trimmed';
    }

    // External CDN / Cloud images (Unsplash, Cloudinary, Google, etc.)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

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
      imageWidget = Image.network(
        normalized,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return AppShimmerBox(
            width: width ?? double.infinity,
            height: height ?? 120,
            borderRadius: borderRadius,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildPlaceholder(width, height);
        },
      );
    } else {
      imageWidget = errorWidget ?? _buildPlaceholder(width, height);
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  /// Curated high-resolution aesthetic event imagery matched to event categories
  static String getCategoryStockFallback(String? categoryHint, String? titleHint) {
    final hint = '${categoryHint ?? ''} ${titleHint ?? ''}'.toLowerCase();
    if (hint.contains('wedding') || hint.contains('marriage')) {
      return 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=800&q=80';
    } else if (hint.contains('cater') || hint.contains('food') || hint.contains('dining')) {
      return 'https://images.unsplash.com/photo-1555244162-803834f70033?auto=format&fit=crop&w=800&q=80';
    } else if (hint.contains('corporate') || hint.contains('conference') || hint.contains('business') || hint.contains('workshop')) {
      return 'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=800&q=80';
    } else if (hint.contains('birthday') || hint.contains('party') || hint.contains('cake')) {
      return 'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?auto=format&fit=crop&w=800&q=80';
    } else if (hint.contains('music') || hint.contains('concert') || hint.contains('dj') || hint.contains('band')) {
      return 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=800&q=80';
    } else if (hint.contains('decor') || hint.contains('stage') || hint.contains('floral')) {
      return 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=800&q=80';
    } else if (hint.contains('photo') || hint.contains('shoot') || hint.contains('video')) {
      return 'https://images.unsplash.com/photo-1537633552985-df8429e8048b?auto=format&fit=crop&w=800&q=80';
    }
    return 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=80';
  }

  Widget _buildPlaceholder(double? w, double? h) {
    // For card cover images & banners, show a themed high-res stock photo
    if (w == null || w >= 80 || h == null || h >= 80) {
      final stockUrl = getCategoryStockFallback(categoryHint, titleHint);
      return Image.network(
        stockUrl,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildLetterPlaceholder(w, h),
      );
    }

    return _buildLetterPlaceholder(w, h);
  }

  Widget _buildLetterPlaceholder(double? w, double? h) {
    final hasTitle = titleHint?.trim().isNotEmpty == true;
    final initial = hasTitle ? titleHint!.trim()[0].toUpperCase() : '';

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (initial.isNotEmpty &&
                (w == null || w >= 48) &&
                (h == null || h >= 48)) ...[
              Container(
                width: (w != null && w < 80) ? 28 : 36,
                height: (w != null && w < 80) ? 28 : 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: (w != null && w < 80) ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                Icons.image_outlined,
                color: AppColors.primary.withValues(alpha: 0.5),
                size: (w != null && w < 60) ? 20 : 28,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

