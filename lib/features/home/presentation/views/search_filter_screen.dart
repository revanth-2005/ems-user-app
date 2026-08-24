import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';
import '../widgets/catalog_cards.dart';
import '../widgets/catalog_filter_modal.dart';

class SearchFilterScreen extends HookConsumerWidget {
  const SearchFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final activeTab = ref.watch(activeCatalogTabProvider);
    final searchQuery = ref.watch(catalogSearchQueryProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    final unifiedAsync = ref.watch(unifiedSearchProvider);
    final packagesAsync = ref.watch(packagesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final organizersAsync = ref.watch(organizersProvider);
    final eventsAsync = ref.watch(eventsProvider);

    final autocompleteAsync = searchQuery.trim().length >= 2
        ? ref.watch(autocompleteSuggestionsProvider(searchQuery.trim()))
        : const AsyncValue<AutocompleteResult>.data(AutocompleteResult());

    // Keep controller text in sync if provider was updated externally
    useEffect(() {
      if (searchController.text != searchQuery) {
        searchController.text = searchQuery;
      }
      return null;
    }, [searchQuery]);

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            // Search Input Bar
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.getCardAlt(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: searchQuery.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.getBorder(context),
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (val) {
                    ref.read(catalogSearchQueryProvider.notifier).state = val;
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.getTextPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: activeTab == CatalogTab.ALL
                        ? 'Search packages, services, vendors, events…'
                        : activeTab == CatalogTab.PACKAGES
                            ? 'Search packages, wedding setups…'
                            : activeTab == CatalogTab.SERVICES
                                ? 'Search DJs, catering, photogs…'
                                : activeTab == CatalogTab.ORGANIZERS
                                    ? 'Search event planners & studios…'
                                    : 'Search concerts, workshops, parties…',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.getTextMuted(context),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 16, color: AppColors.getTextMuted(context)),
                            onPressed: () {
                              searchController.clear();
                              ref
                                  .read(catalogSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // City Filter Button
            PopupMenuButton<String>(
              initialValue: selectedCity,
              onSelected: (city) {
                ref.read(selectedCityProvider.notifier).state = city;
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: AppColors.getSurface(context),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.getCardAlt(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.accentRose),
                    const SizedBox(width: 4),
                    Text(
                      selectedCity == 'All' ? 'All Cities' : selectedCity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down_rounded,
                        size: 18, color: AppColors.getTextSecondary(context)),
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
            const SizedBox(width: 4),

            // Filter Sheet Trigger Button
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (ref.watch(minPriceFilterProvider) != null ||
                          ref.watch(maxPriceFilterProvider) != null ||
                          ref.watch(selectedDateFilterProvider) != null ||
                          ref.watch(minRatingFilterProvider) != null ||
                          ref.watch(selectedPricingUnitFilterProvider) != null ||
                          ref.watch(selectedCategoryFilterProvider) != null)
                      ? AppColors.primary
                      : AppColors.getCardAlt(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (ref.watch(minPriceFilterProvider) != null ||
                            ref.watch(maxPriceFilterProvider) != null ||
                            ref.watch(selectedDateFilterProvider) != null ||
                            ref.watch(minRatingFilterProvider) != null ||
                            ref.watch(selectedPricingUnitFilterProvider) != null ||
                            ref.watch(selectedCategoryFilterProvider) != null)
                        ? AppColors.primary
                        : AppColors.getBorder(context),
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: (ref.watch(minPriceFilterProvider) != null ||
                          ref.watch(maxPriceFilterProvider) != null ||
                          ref.watch(selectedDateFilterProvider) != null ||
                          ref.watch(minRatingFilterProvider) != null ||
                          ref.watch(selectedPricingUnitFilterProvider) != null ||
                          ref.watch(selectedCategoryFilterProvider) != null)
                      ? Colors.white
                      : AppColors.getTextPrimary(context),
                ),
              ),
              onPressed: () => showCatalogFilterModal(context),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Tabs Header (5 Discovery Tabs: All, Packages, Services, Organizers, Events) ──
              Container(
                color: AppColors.getSurface(context),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    _buildTab(context, ref, CatalogTab.ALL, 'All', activeTab),
                    _buildTab(context, ref, CatalogTab.PACKAGES, 'Packages', activeTab),
                    _buildTab(context, ref, CatalogTab.SERVICES, 'Services', activeTab),
                    _buildTab(context, ref, CatalogTab.ORGANIZERS, 'Organizers', activeTab),
                    _buildTab(context, ref, CatalogTab.EVENTS, 'Events', activeTab),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.getBorder(context)),

              // ── Active Filters Bar (Chips) ────────────────────────────────
              _buildActiveFilterChips(context, ref),

              // ── Tab Content ──────────────────────────────────────────────────
              Expanded(
                child: Builder(
                  builder: (context) {
                    switch (activeTab) {
                      // ── 0. Unified Overview (All) ─────────────────────────
                      case CatalogTab.ALL:
                        return unifiedAsync.when(
                          loading: () => const Center(
                              child: AppLoader(message: 'Searching catalog…')),
                          error: (e, _) => AppErrorView(
                            message: e.toString(),
                            onRetry: () => ref.refresh(unifiedSearchProvider),
                          ),
                          data: (res) {
                            if (res.isEmpty) {
                              return const AppEmptyView(
                                title: 'No Results Found',
                                subtitle:
                                    'Try adjusting your search keywords, location, or filters.',
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(unifiedSearchProvider);
                              },
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                                children: [
                                  // 1. Packages Section
                                  if (res.packages.isNotEmpty) ...[
                                    _buildSectionHeader(
                                      context,
                                      title: 'Bundled Packages',
                                      count: res.totalPackages > 0 ? res.totalPackages : res.packages.length,
                                      onSeeAll: () {
                                        ref.read(activeCatalogTabProvider.notifier).state =
                                            CatalogTab.PACKAGES;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    ...res.packages.take(3).map((pkg) => Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: PackageCard(package: pkg),
                                        )),
                                    const SizedBox(height: 10),
                                  ],

                                  // 2. Services Section
                                  if (res.services.isNotEmpty) ...[
                                    _buildSectionHeader(
                                      context,
                                      title: 'Standalone Services',
                                      count: res.totalServices > 0 ? res.totalServices : res.services.length,
                                      onSeeAll: () {
                                        ref.read(activeCatalogTabProvider.notifier).state =
                                            CatalogTab.SERVICES;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    ...res.services.take(3).map((svc) => Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: ServiceCard(service: svc),
                                        )),
                                    const SizedBox(height: 10),
                                  ],

                                  // 3. Organizers Section
                                  if (res.organizers.isNotEmpty) ...[
                                    _buildSectionHeader(
                                      context,
                                      title: 'Event Planners & Studios',
                                      count: res.totalOrganizers > 0 ? res.totalOrganizers : res.organizers.length,
                                      onSeeAll: () {
                                        ref.read(activeCatalogTabProvider.notifier).state =
                                            CatalogTab.ORGANIZERS;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    ...res.organizers.take(3).map((org) => Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: OrganizerCard(organizer: org),
                                        )),
                                    const SizedBox(height: 10),
                                  ],

                                  // 4. Live Public Events Section
                                  if (res.events.isNotEmpty) ...[
                                    _buildSectionHeader(
                                      context,
                                      title: 'Public Live Events',
                                      count: res.totalEvents > 0 ? res.totalEvents : res.events.length,
                                      onSeeAll: () {
                                        ref.read(activeCatalogTabProvider.notifier).state =
                                            CatalogTab.EVENTS;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    ...res.events.take(3).map((evt) => Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: PublicEventCard(event: evt),
                                        )),
                                  ],
                                ],
                              ),
                            );
                          },
                        );

                      // ── 1. Bundled Packages ──────────────────────────────────
                      case CatalogTab.PACKAGES:
                        return packagesAsync.when(
                          loading: () => const Center(
                              child: AppLoader(message: 'Loading packages…')),
                          error: (e, _) => AppErrorView(
                            message: e.toString(),
                            onRetry: () => ref.refresh(packagesProvider),
                          ),
                          data: (pkgs) {
                            if (pkgs.isEmpty) {
                              return const AppEmptyView(
                                title: 'No Packages Found',
                                subtitle:
                                    'Try changing your location or category filters.',
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: pkgs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return PackageCard(package: pkgs[index]);
                              },
                            );
                          },
                        );

                      // ── 2. Standalone Services ───────────────────────────────
                      case CatalogTab.SERVICES:
                        return servicesAsync.when(
                          loading: () => const Center(
                              child: AppLoader(message: 'Loading services…')),
                          error: (e, _) => AppErrorView(
                            message: e.toString(),
                            onRetry: () => ref.refresh(servicesProvider),
                          ),
                          data: (svcs) {
                            if (svcs.isEmpty) {
                              return const AppEmptyView(
                                title: 'No Services Found',
                                subtitle:
                                    'Try clearing your search filters to find available talent.',
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: svcs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return ServiceCard(service: svcs[index]);
                              },
                            );
                          },
                        );

                      // ── 3. Verified Organizers Directory ─────────────────────
                      case CatalogTab.ORGANIZERS:
                        return organizersAsync.when(
                          loading: () => const Center(
                              child: AppLoader(message: 'Loading organizers…')),
                          error: (e, _) => AppErrorView(
                            message: e.toString(),
                            onRetry: () => ref.refresh(organizersProvider),
                          ),
                          data: (orgs) {
                            if (orgs.isEmpty) {
                              return const AppEmptyView(
                                title: 'No Organizers Found',
                                subtitle:
                                    'We could not find organizers matching your criteria.',
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: orgs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                return OrganizerCard(organizer: orgs[index]);
                              },
                            );
                          },
                        );

                      // ── 4. Public Live Events ────────────────────────────────
                      case CatalogTab.EVENTS:
                        return eventsAsync.when(
                          loading: () => const Center(
                              child: AppLoader(message: 'Loading live events…')),
                          error: (e, _) => AppErrorView(
                            message: e.toString(),
                            onRetry: () => ref.refresh(eventsProvider),
                          ),
                          data: (evts) {
                            if (evts.isEmpty) {
                              return const AppEmptyView(
                                title: 'No Live Events Found',
                                subtitle:
                                    'Check back soon for new public experiences.',
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: evts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return PublicEventCard(event: evts[index]);
                              },
                            );
                          },
                        );
                    }
                  },
                ),
              ),
            ],
          ),

          // ── 🔍 Instant Autocomplete / Typeahead Suggestion Dropdown ───────
          if (searchQuery.trim().length >= 2)
            autocompleteAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (auto) {
                if (auto.isEmpty) return const SizedBox();

                return Positioned(
                  top: 52,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(18),
                    color: AppColors.getSurface(context),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 340),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.getBorder(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          // Categories suggestions
                          if (auto.categories.isNotEmpty)
                            ...auto.categories.map((cat) => _buildSuggestionTile(
                                  context,
                                  icon: Icons.category_rounded,
                                  iconColor: AppColors.accentTeal,
                                  title: cat.name,
                                  subtitle: 'Category',
                                  onTap: () {
                                    ref.read(selectedCategoryFilterProvider.notifier).state = cat.id;
                                    ref.read(catalogSearchQueryProvider.notifier).state = '';
                                    searchController.clear();
                                  },
                                )),
                          // Packages suggestions
                          if (auto.packages.isNotEmpty)
                            ...auto.packages.map((pkg) => _buildSuggestionTile(
                                  context,
                                  icon: Icons.inventory_2_rounded,
                                  iconColor: AppColors.primary,
                                  title: pkg.name,
                                  subtitle: 'Package',
                                  onTap: () {
                                    ref.read(catalogSearchQueryProvider.notifier).state = pkg.name;
                                    ref.read(activeCatalogTabProvider.notifier).state = CatalogTab.PACKAGES;
                                  },
                                )),
                          // Services suggestions
                          if (auto.services.isNotEmpty)
                            ...auto.services.map((svc) => _buildSuggestionTile(
                                  context,
                                  icon: Icons.handyman_rounded,
                                  iconColor: AppColors.accentAmber,
                                  title: svc.name,
                                  subtitle: 'Service (${svc.pricingUnit})',
                                  onTap: () {
                                    ref.read(catalogSearchQueryProvider.notifier).state = svc.name;
                                    ref.read(activeCatalogTabProvider.notifier).state = CatalogTab.SERVICES;
                                  },
                                )),
                          // Organizers suggestions
                          if (auto.organizers.isNotEmpty)
                            ...auto.organizers.map((org) => _buildSuggestionTile(
                                  context,
                                  icon: Icons.business_rounded,
                                  iconColor: AppColors.accentRose,
                                  title: org.effectiveName,
                                  subtitle: 'Vendor / Organizer • ${org.city ?? "India"}',
                                  onTap: () {
                                    ref.read(catalogSearchQueryProvider.notifier).state = org.effectiveName;
                                    ref.read(activeCatalogTabProvider.notifier).state = CatalogTab.ORGANIZERS;
                                  },
                                )),
                          // Events suggestions
                          if (auto.events.isNotEmpty)
                            ...auto.events.map((evt) => _buildSuggestionTile(
                                  context,
                                  icon: Icons.confirmation_number_rounded,
                                  iconColor: AppColors.accentIndigo,
                                  title: evt.title,
                                  subtitle: 'Public Event • ${evt.mode.name}',
                                  onTap: () {
                                    ref.read(catalogSearchQueryProvider.notifier).state = evt.title;
                                    ref.read(activeCatalogTabProvider.notifier).state = CatalogTab.EVENTS;
                                  },
                                )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.getTextPrimary(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.getTextMuted(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.north_west_rounded,
        size: 14,
        color: AppColors.getTextMuted(context),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            children: [
              Text(
                'See All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(selectedCategoryFilterProvider);
    final minPrice = ref.watch(minPriceFilterProvider);
    final maxPrice = ref.watch(maxPriceFilterProvider);
    final rating = ref.watch(minRatingFilterProvider);
    final unit = ref.watch(selectedPricingUnitFilterProvider);
    final sort = ref.watch(catalogSortByProvider);

    final hasActive = cat != null ||
        minPrice != null ||
        maxPrice != null ||
        rating != null ||
        unit != null ||
        sort != 'priority';

    if (!hasActive) return const SizedBox.shrink();

    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          if (cat != null)
            _buildChip(
              context,
              label: 'Category Active',
              onClear: () =>
                  ref.read(selectedCategoryFilterProvider.notifier).state = null,
            ),
          if (minPrice != null || maxPrice != null)
            _buildChip(
              context,
              label: 'Budget Filter',
              onClear: () {
                ref.read(minPriceFilterProvider.notifier).state = null;
                ref.read(maxPriceFilterProvider.notifier).state = null;
              },
            ),
          if (rating != null)
            _buildChip(
              context,
              label: '⭐ $rating+',
              onClear: () =>
                  ref.read(minRatingFilterProvider.notifier).state = null,
            ),
          if (unit != null)
            _buildChip(
              context,
              label: unit,
              onClear: () =>
                  ref.read(selectedPricingUnitFilterProvider.notifier).state = null,
            ),
          if (sort != 'priority')
            _buildChip(
              context,
              label: 'Sorted: $sort',
              onClear: () =>
                  ref.read(catalogSortByProvider.notifier).state = 'priority',
            ),
          TextButton(
            onPressed: () {
              ref.read(selectedCategoryFilterProvider.notifier).state = null;
              ref.read(minPriceFilterProvider.notifier).state = null;
              ref.read(maxPriceFilterProvider.notifier).state = null;
              ref.read(minRatingFilterProvider.notifier).state = null;
              ref.read(selectedPricingUnitFilterProvider.notifier).state = null;
              ref.read(catalogSortByProvider.notifier).state = 'priority';
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accentRose,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref,
    CatalogTab tab,
    String title,
    CatalogTab activeTab,
  ) {
    final isSelected = tab == activeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(activeCatalogTabProvider.notifier).state = tab;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}

