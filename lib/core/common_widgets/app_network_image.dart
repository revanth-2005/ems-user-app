import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_loader.dart';

/// Project-level wrapper for CachedNetworkImage with built-in shimmer
/// placeholder and error fallback icon. Screens should use this instead
/// of CachedNetworkImage directly.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    Widget imageWidget = hasUrl
        ? CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => AppShimmerBox(
              width: width ?? double.infinity,
              height: height ?? 120,
              borderRadius: borderRadius,
            ),
            errorWidget: (_, __, ___) =>
                errorWidget ?? _defaultError(width, height),
          )
        : (errorWidget ?? _defaultError(width, height));

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _defaultError(double? w, double? h) {
    return Container(
      width: w,
      height: h,
      color: const Color(0xFFEDE9FE),
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.primary, size: 32),
      ),
    );
  }
}
