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

  /// Normalizes any backend-provided media URL (replacing LAN IPs or relative paths
  /// with the reachable ApiConstants server host and port).
  static String? normalizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    var trimmed = rawUrl.trim();

    // Already an external CDN image (e.g. Unsplash, Google, Cloudinary)
    if (trimmed.startsWith('https://') &&
        !trimmed.contains(':6006') &&
        !trimmed.contains(':3001')) {
      return trimmed;
    }

    // MinIO endpoint on port 6006 or /ems-media/ path
    if (trimmed.contains(':6006') || trimmed.contains('/ems-media/')) {
      final emsMediaIndex = trimmed.indexOf('/ems-media/');
      if (emsMediaIndex != -1) {
        final path = trimmed.substring(emsMediaIndex);
        return 'http://${ApiConstants.serverHost}:6006$path';
      }
    }

    // Relative paths
    if (trimmed.startsWith('/ems-media/')) {
      return 'http://${ApiConstants.serverHost}:6006$trimmed';
    }
    if (trimmed.startsWith('ems-media/')) {
      return 'http://${ApiConstants.serverHost}:6006/$trimmed';
    }
    if (trimmed.startsWith('packages/') ||
        trimmed.startsWith('services/') ||
        trimmed.startsWith('events/')) {
      return 'http://${ApiConstants.serverHost}:6006/ems-media/$trimmed';
    }

    // Replace generic host patterns (192.168.x.x, 10.0.2.2, 127.0.0.1) with ApiConstants.serverHost
    final regex = RegExp(
        r'http:\/\/(?:192\.168\.\d+\.\d+|10\.0\.2\.2|127\.0\.0\.1|localhost)(?::(\d+))?');
    if (regex.hasMatch(trimmed)) {
      trimmed = trimmed.replaceFirstMapped(regex, (match) {
        final port = match.group(1) ?? ApiConstants.serverPort;
        return 'http://${ApiConstants.serverHost}:$port';
      });
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeUrl(url);
    final hasUrl = normalized != null && normalized.isNotEmpty;

    Widget imageWidget;
    if (hasUrl) {
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
          debugPrint('⚠️ [IMAGE ERROR] Failed to load: $normalized ($error)');
          return errorWidget ?? _buildThematicFallback(width, height);
        },
      );
    } else {
      imageWidget = errorWidget ?? _buildThematicFallback(width, height);
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildThematicFallback(double? w, double? h) {
    final fallbackUrl = _getCuratedFallbackImage(categoryHint, titleHint);

    return Image.network(
      fallbackUrl,
      width: w,
      height: h,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.accent.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.event_seat_rounded,
                color: AppColors.primary, size: 28),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.8),
              const Color(0xFF8B5CF6).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration_rounded,
                  color: Colors.white, size: 28),
              if (titleHint?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    titleHint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  static String _getCuratedFallbackImage(
      String? categoryHint, String? titleHint) {
    final text = '${categoryHint ?? ''} ${titleHint ?? ''}'.toLowerCase();

    if (text.contains('cater') ||
        text.contains('food') ||
        text.contains('dining') ||
        text.contains('cake') ||
        text.contains('chef')) {
      return 'https://images.unsplash.com/photo-1555244162-803834f70033?w=800&auto=format&fit=crop';
    }
    if (text.contains('wed') ||
        text.contains('marri') ||
        text.contains('stage') ||
        text.contains('mandap') ||
        text.contains('decor')) {
      return 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop';
    }
    if (text.contains('dj') ||
        text.contains('music') ||
        text.contains('sound') ||
        text.contains('band') ||
        text.contains('concert')) {
      return 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&auto=format&fit=crop';
    }
    if (text.contains('photo') ||
        text.contains('shoot') ||
        text.contains('film') ||
        text.contains('camera')) {
      return 'https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=800&auto=format&fit=crop';
    }
    if (text.contains('birth') ||
        text.contains('party') ||
        text.contains('celebrat')) {
      return 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=800&auto=format&fit=crop';
    }
    if (text.contains('corpor') ||
        text.contains('confer') ||
        text.contains('work')) {
      return 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=800&auto=format&fit=crop';
    }

    return 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800&auto=format&fit=crop';
  }
}
