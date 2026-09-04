import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import 'app_loader.dart';
import 'app_video_player.dart';

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
  static const String _cacheV = 'v=7';

  /// Normalizes any backend-provided media URL.
  /// Converts local IP URLs, old emsstorage URLs, and relative media paths
  /// to point to the active mediaBaseUrl and appends [_cacheV].
  static String? normalizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();

    // 1. Rewrite any port 6006 local IPs (e.g. http://192.168.0.36:6006/ems-media/...)
    if (trimmed.contains(':6006')) {
      final match = RegExp(r'https?://[^/]+(?::6006)?(/.*)').firstMatch(trimmed);
      if (match != null) {
        final path = match.group(1)!.split('?').first;
        return '${ApiConstants.mediaBaseUrl}$path?$_cacheV';
      }
    }

    // 2. If using old emsstorage domain, rewrite to active mediaBaseUrl
    if (trimmed.contains('emsstorage.webnoxdigital.com')) {
      final match = RegExp(r'https?://emsstorage\.webnoxdigital\.com(/.*)').firstMatch(trimmed);
      if (match != null) {
        final path = match.group(1)!.split('?').first;
        return '${ApiConstants.mediaBaseUrl}$path?$_cacheV';
      }
    }

    // 3. Relative /ems-media/ paths — prepend active mediaBaseUrl
    if (trimmed.startsWith('/ems-media/')) {
      final path = trimmed.split('?').first;
      return '${ApiConstants.mediaBaseUrl}$path?$_cacheV';
    }
    if (trimmed.startsWith('ems-media/')) {
      final path = trimmed.split('?').first;
      return '${ApiConstants.mediaBaseUrl}/$path?$_cacheV';
    }

    // 4. Subdirectory paths without ems-media prefix
    if (trimmed.startsWith('packages/') ||
        trimmed.startsWith('services/') ||
        trimmed.startsWith('events/') ||
        trimmed.startsWith('categories/') ||
        trimmed.startsWith('organizers/') ||
        trimmed.startsWith('users/')) {
      final path = trimmed.split('?').first;
      return '${ApiConstants.mediaBaseUrl}/ems-media/$path?$_cacheV';
    }
    if (trimmed.startsWith('/packages/') ||
        trimmed.startsWith('/services/') ||
        trimmed.startsWith('/events/') ||
        trimmed.startsWith('/categories/') ||
        trimmed.startsWith('/organizers/') ||
        trimmed.startsWith('/users/')) {
      final path = trimmed.split('?').first;
      return '${ApiConstants.mediaBaseUrl}/ems-media$path?$_cacheV';
    }

    // 5. Pass external absolute URLs (e.g. Google profile photos) through unchanged
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeUrl(url);
    final hasUrl = normalized != null && normalized.isNotEmpty;
    final cleanUrl = hasUrl ? normalized.toLowerCase().split('?').first : '';
    final isVideo = hasUrl &&
        (cleanUrl.endsWith('.mp4') ||
            cleanUrl.endsWith('.mov') ||
            cleanUrl.endsWith('.webm') ||
            cleanUrl.endsWith('.mkv') ||
            cleanUrl.endsWith('.m3u8') ||
            cleanUrl.contains('/video/'));

    Widget imageWidget;
    if (isVideo) {
      imageWidget = AppVideoThumbnail(
        videoUrl: normalized,
        fit: fit,
        width: width,
        height: height,
        borderRadius: borderRadius,
        categoryHint: categoryHint,
        titleHint: titleHint,
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

