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

  Widget _buildPlaceholder(double? w, double? h) {
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

