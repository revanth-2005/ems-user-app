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
    final userName = user?.name.split(' ').first ?? 'there';
    final selectedCity = ref.watch(selectedCityProvider);
    final homeFeedAsync = ref.watch(homeFeedProvider);
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.items.length;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
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
                backgroundColor: AppColors.lightSurface,
                floating: true,
                pinned: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                titleSpacing: 20,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting 👋',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            user != null ? userName : 'Discover Events',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // City Selector Dropdown
                    PopupMenuButton<String>(
                      initialValue: selectedCity,
                      onSelected: (city) {
                        ref.read(selectedCityProvider.notifier).state = city;
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: AppColors.lightSurface,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              selectedCity == 'All' ? 'All Cities' : selectedCity,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 16, color: AppColors.primary),
                          ],
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
                    const SizedBox(width: 8),

                    // Cart Badge Button
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.cart),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.lightCardAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.lightBorder),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          if (cartCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '$cartCount',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                        color: AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightBorder),
                        boxShadow: AppColors.cardShadow,
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
                                color: AppColors.textMuted,
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

              // ── 4 Core Pillars Navigation Cards ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      // 1. Packages
                      _buildPillarCard(
                        emoji: '🎁',
                        title: 'Packages',
                        subtitle: 'Bundled Deals',
                        color: AppColors.accent,
                        onTap: () {
                          ref.read(activeCatalogTabProvider.notifier).state =
                              CatalogTab.PACKAGES;
                          context.go(AppRoutes.search);
                        },
                      ),
                      const SizedBox(width: 8),

                      // 2. Services
                      _buildPillarCard(
                        emoji: '🛠️',
                        title: 'Services',
                        subtitle: 'Solo Vendors',
                        color: AppColors.primary,
                        onTap: () {
                          ref.read(activeCatalogTabProvider.notifier).state =
                              CatalogTab.SERVICES;
                          context.go(AppRoutes.search);
                        },
                      ),
                      const SizedBox(width: 8),

                      // 3. Organizers
                      _buildPillarCard(
                        emoji: '🏢',
                        title: 'Organizers',
                        subtitle: 'KYC Verified',
                        color: AppColors.success,
                        onTap: () {
                          ref.read(activeCatalogTabProvider.notifier).state =
                              CatalogTab.ORGANIZERS;
                          context.go(AppRoutes.search);
                        },
                      ),
                      const SizedBox(width: 8),

                      // 4. Live Events
                      _buildPillarCard(
                        emoji: '🎟️',
                        title: 'Events',
                        subtitle: 'Live Tickets',
                        color: AppColors.accentAmber,
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

              // ── Categories Horizontal Strip ─────────────────────────────
              if (feed.categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Browse Categories',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
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
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: feed.categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final cat = feed.categories[index];
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(selectedCategoryFilterProvider.notifier)
                                    .state = cat.id;
                                context.go(AppRoutes.search);
                              },
                              child: Container(
                                width: 88,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.lightBorder),
                                  boxShadow: AppColors.cardShadow,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(cat.slug),
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat.name.split(' ').first,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
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

              // ── Featured Bundled Packages ────────────────────────────────
              if (feed.packages.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'All-inclusive verified vendor bundles',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
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
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: feed.packages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return PackageCard(package: feed.packages[index]);
                        },
                      ),
                    ],
                  ),
                ),

              // ── Standalone Services ──────────────────────────────────────
              if (feed.services.isNotEmpty)
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
                                  'Standalone Services',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Individual hire: DJs, Catering, Staging & more',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(activeCatalogTabProvider.notifier)
                                    .state = CatalogTab.SERVICES;
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
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: feed.services.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return ServiceCard(service: feed.services[index]);
                        },
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'KYC-approved event specialists and studios',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
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
                                  color: AppColors.primary,
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
                                  color: AppColors.primary,
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

  Widget _buildPillarCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 5),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug) {
      case 'decor-styling':
        return Icons.auto_awesome_rounded;
      case 'sound-dj':
        return Icons.graphic_eq_rounded;
      case 'catering-dining':
      case 'catering':
        return Icons.restaurant_rounded;
      case 'photography-film':
        return Icons.camera_alt_rounded;
      case 'venues-banquets':
        return Icons.apartment_rounded;
      case 'full-event-planners':
        return Icons.celebration_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
