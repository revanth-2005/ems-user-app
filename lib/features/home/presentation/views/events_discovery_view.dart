import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';

class EventsDiscoveryView extends HookConsumerWidget {
  const EventsDiscoveryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final selectedCategory = ref.watch(selectedEventCategoryProvider);
    final selectedMode = ref.watch(selectedEventModeProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    final categoriesAsync = ref.watch(eventCategoriesProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBg(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          'Discover Events',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.getTextPrimary(context),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // City Selector Menu
          PopupMenuButton<String>(
            initialValue: selectedCity,
            onSelected: (city) {
              ref.read(selectedCityProvider.notifier).state = city;
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: AppColors.getSurface(context),
            tooltip: 'Select City',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    selectedCity == 'All' ? 'All Cities' : selectedCity,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(eventsProvider);
          ref.invalidate(eventCategoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Search Bar ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.getBorder(context)),
                    boxShadow: AppColors.getCardShadow(context),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.getTextMuted(context), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: (val) {
                            ref.read(eventSearchQueryProvider.notifier).state = val.trim();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search concerts, workshops, summits...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.getTextMuted(context),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.getTextPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            searchController.clear();
                            ref.read(eventSearchQueryProvider.notifier).state = '';
                          },
                          child: Icon(Icons.close_rounded, color: AppColors.getTextMuted(context), size: 18),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Mode Segmented Pill Selector ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.getCardAlt(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeSegment(
                          title: 'All Events',
                          icon: Icons.grid_view_rounded,
                          isSelected: selectedMode == 'ALL',
                          onTap: () => ref.read(selectedEventModeProvider.notifier).state = 'ALL',
                        ),
                      ),
                      Expanded(
                        child: _ModeSegment(
                          title: 'In-Person',
                          icon: Icons.location_on_rounded,
                          isSelected: selectedMode == 'OFFLINE',
                          onTap: () => ref.read(selectedEventModeProvider.notifier).state = 'OFFLINE',
                        ),
                      ),
                      Expanded(
                        child: _ModeSegment(
                          title: 'Virtual',
                          icon: Icons.laptop_mac_rounded,
                          isSelected: selectedMode == 'ONLINE',
                          onTap: () => ref.read(selectedEventModeProvider.notifier).state = 'ONLINE',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Event Category Filter Chips ────────────────────────────────
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                loading: () => const SizedBox(height: 52),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = selectedCategory == null;
                            return GestureDetector(
                              onTap: () => ref.read(selectedEventCategoryProvider.notifier).state = null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.getSurface(context),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.getBorder(context),
                                  ),
                                ),
                                child: Text(
                                  '✨ All Categories',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ),
                            );
                          }

                          final cat = categories[index - 1];
                          final isSelected = selectedCategory == cat.id || selectedCategory == cat.slug;

                          return GestureDetector(
                            onTap: () {
                              ref.read(selectedEventCategoryProvider.notifier).state = isSelected ? null : cat.id;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.getSurface(context),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.getBorder(context),
                                ),
                              ),
                              child: Text(
                                cat.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.getTextPrimary(context),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Events Feed / Grid ─────────────────────────────────────────
            eventsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: AppLoader(message: 'Finding live events…')),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load events',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.refresh(eventsProvider),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Events Found',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your city, mode, or category filters to explore more experiences.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                ref.read(selectedEventCategoryProvider.notifier).state = null;
                                ref.read(selectedEventModeProvider.notifier).state = 'ALL';
                                ref.read(eventSearchQueryProvider.notifier).state = '';
                                searchController.clear();
                              },
                              child: const Text('Clear All Filters'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Split into Featured (1st item if no search) and Upcoming List
                final featuredEvent = (searchController.text.isEmpty && selectedCategory == null) ? events.first : null;
                final listEvents = featuredEvent != null ? events.skip(1).toList() : events;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Featured Hero Card
                      if (featuredEvent != null) ...[
                        Text(
                          'Featured Experience',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FeaturedHeroCard(event: featuredEvent),
                        const SizedBox(height: 24),
                      ],

                      if (listEvents.isNotEmpty) ...[
                        Text(
                          'Upcoming Events (${events.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...listEvents.map((evt) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _EventDiscoveryCard(event: evt),
                            )),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.getSurface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? AppColors.getCardShadow(context) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.getTextSecondary(context),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.getTextPrimary(context) : AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedHeroCard extends StatelessWidget {
  final PublicEvent event;

  const _FeaturedHeroCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/event/${event.id}'),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(
              url: event.coverImageUrl,
              categoryHint: event.category?.name ?? 'Event',
              titleHint: event.title,
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: event.isOnline ? const Color(0xFF3B82F6) : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.isOnline ? '🌐 VIRTUAL' : '📍 IN-PERSON',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormatter.formatEventDate(event.startDatetime)} • ${event.venueCity ?? "Live Online"}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.effectivePriceLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Get Passes →',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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

class _EventDiscoveryCard extends StatelessWidget {
  final PublicEvent event;

  const _EventDiscoveryCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/event/${event.id}'),
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
                    categoryHint: event.category?.name ?? 'Event',
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: event.isOnline
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.isOnline ? 'VIRTUAL' : 'IN-PERSON',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.venueCity ?? (event.isOnline ? 'Online' : 'India'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.formatEventDate(event.startDatetime),
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
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextMuted(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.effectivePriceLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Book Pass',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
