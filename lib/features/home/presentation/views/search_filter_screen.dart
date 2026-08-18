import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/catalog_providers.dart';
import '../widgets/catalog_cards.dart';

class SearchFilterScreen extends HookConsumerWidget {
  const SearchFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final activeTab = ref.watch(activeCatalogTabProvider);
    final searchQuery = ref.watch(catalogSearchQueryProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);
    final selectedPricingUnit = ref.watch(selectedPricingUnitFilterProvider);

    final categoriesAsync = ref.watch(categoriesProvider);
    final packagesAsync = ref.watch(packagesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final organizersAsync = ref.watch(organizersProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
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
                  color: AppColors.lightCardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (val) {
                    ref.read(catalogSearchQueryProvider.notifier).state = val;
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: activeTab == CatalogTab.PACKAGES
                        ? 'Search packages, wedding setups…'
                        : activeTab == CatalogTab.SERVICES
                            ? 'Search DJs, catering, photogs…'
                            : activeTab == CatalogTab.ORGANIZERS
                                ? 'Search event planners & studios…'
                                : 'Search concerts, workshops, parties…',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.textMuted),
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
              color: AppColors.lightSurface,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.lightCardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightBorder),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded,
                        size: 18, color: AppColors.textSecondary),
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
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Tabs Header (4 Discovery Tabs) ───────────────────────────────
          Container(
            color: AppColors.lightSurface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildTab(ref, CatalogTab.PACKAGES, 'Packages', activeTab),
                _buildTab(ref, CatalogTab.SERVICES, 'Services', activeTab),
                _buildTab(ref, CatalogTab.ORGANIZERS, 'Organizers', activeTab),
                _buildTab(ref, CatalogTab.EVENTS, 'Events', activeTab),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightBorder),

          // ── Category & Pricing Filter Strip ──────────────────────────────
          Container(
            color: AppColors.lightSurface,
            height: 48,
            child: categoriesAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (categories) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    // "All Categories" chip
                    _buildCategoryChip(
                      label: 'All Categories',
                      isSelected: selectedCategoryId == null,
                      onTap: () {
                        ref
                            .read(selectedCategoryFilterProvider.notifier)
                            .state = null;
                        ref
                            .read(selectedSubCategoryFilterProvider.notifier)
                            .state = null;
                      },
                    ),
                    const SizedBox(width: 8),

                    // Individual Categories
                    ...categories.map((cat) {
                      final isSelected = selectedCategoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryChip(
                          label: cat.name,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(selectedCategoryFilterProvider.notifier)
                                .state = isSelected ? null : cat.id;
                            ref
                                .read(selectedSubCategoryFilterProvider.notifier)
                                .state = null;
                          },
                        ),
                      );
                    }),

                    // Unit filters for services tab
                    if (activeTab == CatalogTab.SERVICES) ...[
                      const VerticalDivider(width: 16, color: AppColors.lightBorder),
                      _buildCategoryChip(
                        label: 'All Units',
                        isSelected: selectedPricingUnit == null,
                        onTap: () {
                          ref
                              .read(selectedPricingUnitFilterProvider.notifier)
                              .state = null;
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        label: 'Fixed Rate',
                        isSelected: selectedPricingUnit == 'FIXED',
                        onTap: () {
                          ref
                              .read(selectedPricingUnitFilterProvider.notifier)
                              .state = selectedPricingUnit == 'FIXED' ? null : 'FIXED';
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        label: 'Per Hour',
                        isSelected: selectedPricingUnit == 'PER_HOUR',
                        onTap: () {
                          ref
                              .read(selectedPricingUnitFilterProvider.notifier)
                              .state = selectedPricingUnit == 'PER_HOUR' ? null : 'PER_HOUR';
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        label: 'Per Head',
                        isSelected: selectedPricingUnit == 'PER_HEAD',
                        onTap: () {
                          ref
                              .read(selectedPricingUnitFilterProvider.notifier)
                              .state = selectedPricingUnit == 'PER_HEAD' ? null : 'PER_HEAD';
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.lightBorder),

          // ── Tab Content ──────────────────────────────────────────────────
          Expanded(
            child: Builder(
              builder: (context) {
                switch (activeTab) {
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
                      data: (srvs) {
                        if (srvs.isEmpty) {
                          return const AppEmptyView(
                            title: 'No Standalone Services Found',
                            subtitle:
                                'Try adjusting your search keywords or filters.',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: srvs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return ServiceCard(service: srvs[index]);
                          },
                        );
                      },
                    );

                  // ── 3. Organizers Directory ──────────────────────────────
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
                                'No verified organizers matching your criteria.',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: orgs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return OrganizerCard(organizer: orgs[index]);
                          },
                        );
                      },
                    );

                  // ── 4. Live Events ───────────────────────────────────────
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
    );
  }

  Widget _buildTab(
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
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.lightCardAlt,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
