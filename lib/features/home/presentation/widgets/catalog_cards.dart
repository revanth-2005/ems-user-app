import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';
import 'follow_button.dart';

// ── 1. Bundled Package Card ──────────────────────────────────────────────────

class PackageCard extends StatelessWidget {
  final EventPackage package;
  final VoidCallback? onTap;

  const PackageCard({
    super.key,
    required this.package,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cityName =
        package.city?.isNotEmpty == true ? package.city! : 'Coimbatore';
    final originalPricePaise = (package.priceInPaise * 1.5).round();
    const discountPct = 33;

    final descriptionText = (package.description?.isNotEmpty == true)
        ? package.description!
        : (package.inclusions.isNotEmpty
            ? package.inclusions.join(' • ')
            : 'Everything you need to launch & grow your event.');

    return GestureDetector(
      onTap: onTap ?? () => context.push('/detail/package/${package.id}'),
      child: Container(
        height: 195,
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.getBorder(context),
            width: 1,
          ),
          boxShadow: AppColors.getCardShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // ── 1. Full-bleed Clear Background Image ─────────────────────────
            Positioned.fill(
              child: AppNetworkImage(
                url: package.coverImageUrl,
                categoryHint: package.categoryName,
                titleHint: package.name,
                fit: BoxFit.cover,
              ),
            ),

            // ── 2. Subtle Bottom Scrim for Price Readability Only ───────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 75,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. Card Content ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section: Title + Description + Location
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          package.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.85),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Subtitle / Description
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          descriptionText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.25,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.85),
                                blurRadius: 5,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location Badge Capsule
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 10.5,
                              color: Color(0xFFE50914),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cityName.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom section: Starts at + Price + Strikethrough + Discount %
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Starts at',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.85),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            CurrencyFormatter.formatPaise(package.priceInPaise),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.85),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          if (originalPricePaise > package.priceInPaise) ...[
                            const SizedBox(width: 6),
                            Text(
                              CurrencyFormatter.formatPaise(originalPricePaise),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.75),
                                decoration: TextDecoration.lineThrough,
                                decorationColor:
                                    Colors.white.withValues(alpha: 0.75),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.85),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8A141C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$discountPct% OFF',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2. Standalone Service Card ───────────────────────────────────────────────


class ServiceCard extends StatelessWidget {
  final StandaloneService service;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cityName = service.city?.isNotEmpty == true ? service.city! : 'India';

    return GestureDetector(
      onTap: onTap ?? () => context.push('/detail/service/${service.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: AppColors.getCardShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppNetworkImage(
                    url: service.coverImageUrl,
                    categoryHint: service.categoryName,
                    titleHint: service.name,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            service.categoryName.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Color(0xFFE50914)),
                            const SizedBox(width: 4),
                            Text(
                              cityName.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${service.organizerName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  if (service.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      service.description!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(context),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppColors.getBorder(context)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.pricingUnitLabel.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.getTextMuted(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatPaise(service.priceInPaise),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onTap ?? () => context.push('/detail/service/${service.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Details',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3. Organizer Directory Card ─────────────────────────────────────────────

class OrganizerCard extends ConsumerWidget {
  final OrganizerSummary organizer;
  final VoidCallback? onTap;

  const OrganizerCard({
    super.key,
    required this.organizer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cityName =
        organizer.city?.isNotEmpty == true ? organizer.city! : 'India';
    final hasBio = organizer.bio?.isNotEmpty == true &&
        organizer.bio!.trim().toLowerCase() !=
            organizer.effectiveName.trim().toLowerCase();

    final followedIds = ref.watch(followedOrganizerIdsProvider);
    final isActuallyFollowed =
        organizer.isFollowed || followedIds.contains(organizer.id);

    final followState = ref.watch(
      organizerFollowProvider(OrganizerFollowArgs(
        id: organizer.id,
        initialFollow: isActuallyFollowed,
        initialFollowerCount: organizer.followerCount,
      )),
    );

    return GestureDetector(
      onTap: onTap ??
          () => context.push(
              AppRoutes.organizerProfile.replaceAll(':id', organizer.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: (followState.isFollowed || isActuallyFollowed)
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.getBorder(context),
          ),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Row(
          children: [
            // Left Image Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 58,
                height: 58,
                child: organizer.effectiveAvatar != null
                    ? AppNetworkImage(
                        url: organizer.effectiveAvatar,
                        fit: BoxFit.cover,
                        titleHint: organizer.effectiveName,
                      )
                    : Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Center(
                          child: Text(
                            organizer.effectiveName.isNotEmpty
                                ? organizer.effectiveName[0].toUpperCase()
                                : 'O',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organizer.effectiveName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: AppColors.accentRose),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          cityName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextSecondary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.accentAmber),
                      const SizedBox(width: 2),
                      Text(
                        organizer.rating.toStringAsFixed(1),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${followState.followerCount} followers${organizer.packageCount > 0 ? " • ${organizer.packageCount} packages" : (organizer.serviceCount > 0 ? " • ${organizer.serviceCount} services" : (organizer.distanceKm != null ? " • ${organizer.distanceKm!.toStringAsFixed(1)} km" : ""))}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasBio) ...[
                    const SizedBox(height: 3),
                    Text(
                      organizer.bio!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.getTextSecondary(context),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Follow / Unfollow Action Button
            const SizedBox(width: 8),
            FollowButton(
              organizerId: organizer.id,
              organizerName: organizer.effectiveName,
              initialIsFollowed: isActuallyFollowed,
              initialFollowerCount: organizer.followerCount,
              isCompact: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 4. Public Live Event Card ────────────────────────────────────────────────

class PublicEventCard extends StatelessWidget {
  final PublicEvent event;
  final VoidCallback? onTap;

  const PublicEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cityName = event.venueCity?.isNotEmpty == true ? event.venueCity! : 'India';

    return GestureDetector(
      onTap: onTap ?? () => context.push('/detail/event/${event.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: AppColors.getCardShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppNetworkImage(
                    url: event.coverImageUrl,
                    categoryHint: event.category?.name ?? 'Live Event',
                    titleHint: event.title,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.mode == EventMode.ONLINE
                                ? 'ONLINE EVENT'
                                : 'IN-PERSON',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Color(0xFFE50914)),
                            const SizedBox(width: 4),
                            Text(
                              cityName.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        DateFormatter.formatDate(event.startDatetime),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppColors.getBorder(context)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TICKETS FROM',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.getTextMuted(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.minPricePaise == 0
                                ? 'Free Admission'
                                : CurrencyFormatter.formatPaise(event.minPricePaise),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: event.minPricePaise == 0
                                  ? AppColors.accentEmerald
                                  : AppColors.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Book Tickets',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
