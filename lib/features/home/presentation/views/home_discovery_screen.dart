import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../bookings/presentation/providers/booking_providers.dart';
import '../providers/catalog_providers.dart';
import '../widgets/catalog_cards.dart';
import '../widgets/ticket_selection_bottom_sheet.dart';

class HomeDiscoveryScreen extends HookConsumerWidget {
  const HomeDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // ── Top Section: Netflix-style Hero or Classic App Bar ─────────
              if (feed.events.isNotEmpty)
                SliverToBoxAdapter(
                  child: _NetflixEventHero(
                    events: feed.events,
                  ),
                )
              else
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: Color(0xFFE50914),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'INDIA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.storefront_outlined, size: 24),
                        tooltip: 'Host & Ticketing Studio',
                        color: AppColors.getTextPrimary(context),
                        onPressed: () {
                          ref.read(authStateProvider.notifier).switchPortal(ActivePortal.HOST);
                          context.push(AppRoutes.hostDashboard);
                        },
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.cart),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
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

              // ── 4 Core Pillars Navigation (Circular Icons + Label Below) ──
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore Categories',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Discover packages, services, organizers & events',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          // 1. Packages
                          _buildPillarCircle(
                            context: context,
                            icon: Icons.inventory_2_rounded,
                            title: 'Packages',
                            onTap: () {
                              ref
                                  .read(activeCatalogTabProvider.notifier)
                                  .state = CatalogTab.PACKAGES;
                              context.go(AppRoutes.search);
                            },
                          ),

                          // 2. Services
                          _buildPillarCircle(
                            context: context,
                            icon: Icons.design_services_rounded,
                            title: 'Services',
                            onTap: () {
                              ref
                                  .read(activeCatalogTabProvider.notifier)
                                  .state = CatalogTab.SERVICES;
                              context.go(AppRoutes.search);
                            },
                          ),

                          // 3. Organizers
                          _buildPillarCircle(
                            context: context,
                            icon: Icons.business_center_rounded,
                            title: 'Organizers',
                            onTap: () {
                              ref
                                  .read(activeCatalogTabProvider.notifier)
                                  .state = CatalogTab.ORGANIZERS;
                              context.go(AppRoutes.search);
                            },
                          ),

                          // 4. Live Events
                          _buildPillarCircle(
                            context: context,
                            icon: Icons.confirmation_number_rounded,
                            title: 'Events',
                            onTap: () {
                              ref
                                  .read(activeCatalogTabProvider.notifier)
                                  .state = CatalogTab.EVENTS;
                              context.go(AppRoutes.search);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View all',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFE50914),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Color(0xFFE50914),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 205,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: feed.packages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final screenWidth =
                                MediaQuery.of(context).size.width;
                            final cardWidth =
                                (screenWidth - 48).clamp(320.0, 360.0);
                            return SizedBox(
                              width: cardWidth,
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
}


// ── Netflix-style Full-bleed Hero Event Carousel ────────────────────────────

class _NetflixEventHero extends ConsumerStatefulWidget {
  final List<dynamic> events;

  const _NetflixEventHero({
    required this.events,
  });

  @override
  ConsumerState<_NetflixEventHero> createState() => _NetflixEventHeroState();
}

class _NetflixEventHeroState extends ConsumerState<_NetflixEventHero> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  String _formatHeroDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = days[dt.weekday - 1];
    return '$weekday, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final screenWidth = MediaQuery.of(context).size.width;
    final heroHeight = screenWidth * 1.25;
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-bleed hero container with floating transparent App Bar
        SizedBox(
          height: heroHeight,
          child: Stack(
            children: [
              // 1. PageView for events
              PageView.builder(
                controller: _pageController,
                itemCount: events.length,
                onPageChanged: (i) => _currentPageNotifier.value = i,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isOnline = event.mode.toString().contains('ONLINE');

                  return GestureDetector(
                    key: ValueKey(event.id),
                    onTap: () => context.push('/detail/event/${event.id}'),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover image with normalized URL and caching
                        AppNetworkImage(
                          key: ValueKey(event.coverImageUrl ?? event.id),
                          url: event.coverImageUrl,
                          categoryHint: event.category?.name ?? 'Event',
                          titleHint: event.title,
                          fit: BoxFit.cover,
                        ),

                        // Bottom Gradient overlay
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.25, 0.65, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.black.withValues(alpha: 0.98),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom overlay: Category + Title + (Mode & Date) + CTAs
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category / Genre label
                                if (event.category?.name != null) ...[
                                  Text(
                                    event.category!.name.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.8),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],

                                // Big title
                                Text(
                                  event.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.15,
                                    letterSpacing: -0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.8),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Mode Badge + Bullet + Date Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Mode badge (IN-PERSON / ONLINE)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isOnline
                                            ? AppColors.primary
                                            : Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.18),
                                          width: 0.6,
                                        ),
                                      ),
                                      child: Text(
                                        isOnline ? 'ONLINE EVENT' : 'IN-PERSON',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Dot separator
                                    Container(
                                      width: 3.5,
                                      height: 3.5,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Date
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12.5,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatHeroDate(event.startDatetime),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // Action buttons row (Circular Cart + Primary CTA + Circular Info aligned on the same horizontal line)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. 🛒 Cart Button (Round)
                                    _heroActionButton(
                                      icon: Icons.shopping_cart_outlined,
                                      label: 'Cart',
                                      onTap: () async {
                                        await ref
                                            .read(cartProvider.notifier)
                                            .addEvent(event);
                                        if (context.mounted) {
                                          AppSnackbar.show(
                                            context,
                                            message:
                                                '🛒 Added "${event.title}" to cart!',
                                            type: SnackbarType.success,
                                          );
                                        }
                                      },
                                    ),

                                    const SizedBox(width: 16),

                                    // 2. ▶ Book / Free Tickets (Primary White CTA - height 44 to match 44x44 circles)
                                    GestureDetector(
                                      onTap: () =>
                                          TicketSelectionBottomSheet.show(
                                              context, event),
                                      child: Container(
                                        height: 44,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 22),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.black,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              event.minPricePaise == 0
                                                  ? 'Free Tickets'
                                                  : 'Book Tickets',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // 3. ℹ Info Button (Round)
                                    _heroActionButton(
                                      icon: Icons.info_outline_rounded,
                                      label: 'Info',
                                      onTap: () => context
                                          .push('/detail/event/${event.id}'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 2. Top-down Gradient Overlay (ensures floating App Bar text/icons are crisp)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Floating Transparent App Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                    child: Row(
                      children: [
                        // Dynamic Location Badge for Active Carousel Event
                        ValueListenableBuilder<int>(
                          valueListenable: _currentPageNotifier,
                          builder: (context, currentPage, _) {
                            final currentEvent = events.isNotEmpty &&
                                    currentPage < events.length
                                ? events[currentPage]
                                : null;
                            final city =
                                (currentEvent?.venueCity?.isNotEmpty == true)
                                    ? currentEvent!.venueCity!
                                    : 'India';

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 13,
                                    color: Color(0xFFE50914),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    city.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Spacer(),

                        // Host Studio Quick Switch Button
                        IconButton(
                          icon: const Icon(Icons.storefront_outlined, size: 24),
                          tooltip: 'Host & Ticketing Studio',
                          color: Colors.white,
                          onPressed: () {
                            ref
                                .read(authStateProvider.notifier)
                                .switchPortal(ActivePortal.HOST);
                            context.push(AppRoutes.hostDashboard);
                          },
                        ),
                        const SizedBox(width: 4),

                        // Cart Badge Button
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.cart),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
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
                                          color: Colors.black,
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
                ),
              ),
            ],
          ),
        ),

        // Pagination dots with ValueListenableBuilder (zero full-widget rebuilds on swipe)
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: ValueListenableBuilder<int>(
            valueListenable: _currentPageNotifier,
            builder: (context, currentPage, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(events.length, (i) {
                  final active = i == currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _heroActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
