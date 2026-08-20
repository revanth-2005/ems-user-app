import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/constants/app_colors.dart';
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

    final packagesAsync = ref.watch(packagesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final organizersAsync = ref.watch(organizersProvider);
    final eventsAsync = ref.watch(eventsProvider);

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
                  border: Border.all(color: AppColors.getBorder(context)),
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
                    hintText: activeTab == CatalogTab.PACKAGES
                        ? 'Search packages, wedding setups…'
                        : activeTab == CatalogTab.SERVICES
                            ? 'Search DJs, catering, photogs…'
                            : activeTab == CatalogTab.ORGANIZERS
                                ? 'Search event planners & studios…'
                                : 'Search concerts, workshops, parties…',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
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
                          ref.watch(minRatingFilterProvider) != null)
                      ? AppColors.primary
                      : AppColors.getCardAlt(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (ref.watch(minPriceFilterProvider) != null ||
                            ref.watch(maxPriceFilterProvider) != null ||
                            ref.watch(selectedDateFilterProvider) != null ||
                            ref.watch(minRatingFilterProvider) != null)
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
                          ref.watch(minRatingFilterProvider) != null)
                      ? Colors.white
                      : AppColors.getTextPrimary(context),
                ),
              ),
              onPressed: () => showCatalogFilterModal(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Tabs Header (4 Discovery Tabs) ───────────────────────────────
          Container(
            color: AppColors.getSurface(context),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildTab(context, ref, CatalogTab.PACKAGES, 'Packages', activeTab),
                _buildTab(context, ref, CatalogTab.SERVICES, 'Services', activeTab),
                _buildTab(context, ref, CatalogTab.ORGANIZERS, 'Organizers', activeTab),
                _buildTab(context, ref, CatalogTab.EVENTS, 'Events', activeTab),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.getBorder(context)),

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
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}
