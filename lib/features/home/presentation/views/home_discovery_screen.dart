import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../bookings/presentation/providers/booking_providers.dart';
import '../providers/catalog_providers.dart';
import '../widgets/catalog_cards.dart';

class HomeDiscoveryScreen extends HookConsumerWidget {
  const HomeDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final rawName = user?.name.split(' ').first ?? '';
    final displayName = rawName.isNotEmpty
        ? '${rawName[0].toUpperCase()}${rawName.substring(1)}'
        : 'Discover Events';
    final selectedCity = ref.watch(selectedCityProvider);
    final homeFeedAsync = ref.watch(homeFeedProvider);
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.items.length;

    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      body: homeFeedAsync.when(
        loading: () =>
            const Center(child: AppLoader(message: 'Loading experiences…')),
        error: (err, _) => AppErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(homeFeedProvider),
        ),
        data: (feed) {
          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppColors.getBg(context),
                floating: true,
                pinned: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                titleSpacing: 20,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        user != null ? displayName : 'Discover Events',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.getTextPrimary(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    // City Selector (Clean Icon)
                    PopupMenuButton<String>(
                      initialValue: selectedCity,
                      onSelected: (city) {
                        ref.read(selectedCityProvider.notifier).state = city;
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: AppColors.getSurface(context),
                      tooltip: 'Select City',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.getTextPrimary(context),
                          size: 26,
                        ),
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'All', child: Text('All Cities')),
                        PopupMenuItem(value: 'Mumbai', child: Text('Mumbai')),
                        PopupMenuItem(value: 'Coimbatore', child: Text('Coimbatore')),
                        PopupMenuItem(value: 'Chennai', child: Text('Chennai')),
                        PopupMenuItem(value: 'Bengaluru', child: Text('Bengaluru')),
                        PopupMenuItem(value: 'Delhi NCR', child: Text('Delhi NCR')),
                        PopupMenuItem(value: 'Hyderabad', child: Text('Hyderabad')),
                        PopupMenuItem(value: 'Goa', child: Text('Goa')),
                      ],
                    ),
                    const SizedBox(width: 4),

                    // Cart Badge Button (Clean Icon with Red Counter Badge)
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.cart),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.getTextPrimary(context),
                              size: 26,
                            ),
                            if (cartCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE50914),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? Colors.black : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$cartCount',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search & Discovery Bar ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.search),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.whiteCardAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : AppColors.whiteBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search packages, DJs, photographers, organizers…',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.getTextMuted(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 4 Core Pillars Navigation (Circular Icons + Label Below) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      // 1. Packages
                      _buildPillarCircle(
                        context: context,
                        icon: Icons.inventory_2_rounded,
                        title: 'Packages',
                        onTap: () {
                          ref.read(activeCatalogTabProvider.notifier).state =
                              CatalogTab.PACKAGES;
                          context.go(AppRoutes.search);
                        },
                      ),

                      // 2. Services
                      _buildPillarCircle(
                        context: context,
                        icon: Icons.design_services_rounded,
                        title: 'Services',
                        onTap: () {
                          ref.read(activeCatalogTabProvider.notifier).state =
                              CatalogTab.SERVICES;
                          context.go(AppRoutes.search);
                        },
                      ),

                      // 3. Organizers
                      _buildPillarCircle(
                        context: context,
                        icon: Icons.business_center_rounded,
                        title: 'Organizers',
                        onTap: () {
                          ref.read(activeCatalogTabProvider.notifier).state =
                              CatalogTab.ORGANIZERS;
                          context.go(AppRoutes.search);
                        },
                      ),

                      // 4. Live Events
                      _buildPillarCircle(
                        context: context,
                        icon: Icons.confirmation_number_rounded,
                        title: 'Events',
                        onTap: () {
                          ref.read(activeCatalogTabProvider.notifier).state =
                              CatalogTab.EVENTS;
                          context.go(AppRoutes.search);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── Featured Bundled Packages (Horizontal Carousel) ──────────
              if (feed.packages.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bundled Packages',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                                Text(
                                  'All-inclusive verified vendor bundles',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(activeCatalogTabProvider.notifier)
                                    .state = CatalogTab.PACKAGES;
                                context.go(AppRoutes.search);
                              },
                              child: Text(
                                'View all',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 360,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: feed.packages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 300,
                              child: PackageCard(package: feed.packages[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Categories Horizontal Strip ─────────────────────────────
              if (feed.categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Browse Categories',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go(AppRoutes.search),
                              child: Text(
                                'See all',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: feed.categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = feed.categories[index];
                            final shortName = _getCategoryDisplayName(cat.name);
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(selectedCategoryFilterProvider.notifier)
                                    .state = cat.id;
                                context.go(AppRoutes.search);
                              },
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : AppColors.whiteCardAlt,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.14)
                                        : AppColors.whiteBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.12)
                                            : AppColors.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(cat.slug),
                                        size: 12.5,
                                        color: isDark ? Colors.white : AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      shortName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextPrimary(context),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Verified Organizers Directory ────────────────────────────
              if (feed.organizers.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verified Organizers',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                                Text(
                                  'KYC-approved event specialists and studios',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(activeCatalogTabProvider.notifier)
                                    .state = CatalogTab.ORGANIZERS;
                                context.go(AppRoutes.search);
                              },
                              child: Text(
                                'View all',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: feed.organizers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return OrganizerCard(organizer: feed.organizers[index]);
                        },
                      ),
                    ],
                  ),
                ),

              // ── Public Events ───────────────────────────────────────────
              if (feed.events.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Live & Upcoming Events',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(activeCatalogTabProvider.notifier)
                                    .state = CatalogTab.EVENTS;
                                context.go(AppRoutes.search);
                              },
                              child: Text(
                                'View all',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: feed.events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return PublicEventCard(event: feed.events[index]);
                        },
                      ),
                    ],
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 36),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPillarCircle({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : AppColors.whiteCardAlt,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.whiteBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: isDark ? Colors.white : AppColors.getTextPrimary(context),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String name) {
    if (name.contains('&')) {
      return name.split('&')[0].trim();
    }
    if (name.contains('Events')) {
      return name.replaceAll('Events', '').trim();
    }
    return name.trim();
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'weddings':
      case 'wedding':
      case 'weddings-marriages':
        return Icons.favorite_rounded;
      case 'corporate':
      case 'corporate-events':
      case 'corporate-events-conferences':
        return Icons.business_center_rounded;
      case 'birthdays':
      case 'birthday':
      case 'birthdays-private-parties':
        return Icons.cake_rounded;
      case 'music-concerts':
      case 'music':
      case 'concerts':
      case 'sound-dj':
        return Icons.music_note_rounded;
      case 'catering-dining':
      case 'catering':
      case 'dining':
        return Icons.restaurant_rounded;
      case 'decor-styling':
      case 'decor':
      case 'decor-theme-design':
        return Icons.auto_awesome_rounded;
      case 'photography-film':
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'venues-banquets':
      case 'venues':
        return Icons.apartment_rounded;
      case 'full-event-planners':
      case 'planners':
        return Icons.celebration_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String slug) {
    switch (slug.toLowerCase()) {
      case 'weddings':
      case 'wedding':
      case 'weddings-marriages':
        return const Color(0xFFE91E63);
      case 'corporate':
      case 'corporate-events':
      case 'corporate-events-conferences':
        return const Color(0xFF1976D2);
      case 'birthdays':
      case 'birthday':
      case 'birthdays-private-parties':
        return const Color(0xFFFF9800);
      case 'music-concerts':
      case 'music':
      case 'concerts':
      case 'sound-dj':
        return const Color(0xFF9C27B0);
      case 'catering-dining':
      case 'catering':
      case 'dining':
        return const Color(0xFF4CAF50);
      case 'decor-styling':
      case 'decor':
      case 'decor-theme-design':
        return const Color(0xFF00BCD4);
      case 'photography-film':
      case 'photography':
        return const Color(0xFFE040FB);
      case 'venues-banquets':
      case 'venues':
        return const Color(0xFF3F51B5);
      case 'full-event-planners':
      case 'planners':
        return const Color(0xFFFF5722);
      default:
        return AppColors.primary;
    }
  }
}
