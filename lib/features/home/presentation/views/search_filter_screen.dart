import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_rating_chip.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';

class SearchFilterScreen extends HookConsumerWidget {
  const SearchFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final activeTab = ref.watch(activeCatalogTabProvider);
    final searchQuery = ref.watch(catalogSearchQueryProvider);
    final packagesAsync = ref.watch(packagesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
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
                    hintText: 'Search packages, venues, DJs…',
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
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Tabs Header ──────────────────────────────────────────────────
          Container(
            color: AppColors.lightSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab(ref, CatalogTab.PACKAGES, 'Packages', activeTab),
                _buildTab(ref, CatalogTab.SERVICES, 'Services', activeTab),
                _buildTab(ref, CatalogTab.EVENTS, 'Live Events', activeTab),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightBorder),

          // ── Results List ─────────────────────────────────────────────────
          Expanded(
            child: Builder(
              builder: (context) {
                switch (activeTab) {
                  case CatalogTab.PACKAGES:
                    return packagesAsync.when(
                      loading: () => const Center(child: AppLoader()),
                      error: (e, _) => Center(child: Text(e.toString())),
                      data: (pkgs) {
                        final filtered = pkgs.where((p) {
                          final matchQuery = searchQuery.isEmpty ||
                              p.name
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()) ||
                              p.organizer.businessName
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase());
                          return matchQuery;
                        }).toList();

                        if (filtered.isEmpty) {
                          return const AppEmptyView(
                            title: 'No Packages Found',
                            subtitle: 'Try changing your search keywords.',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final pkg = filtered[index];
                            return GestureDetector(
                              onTap: () =>
                                  context.push('/detail/package/${pkg.id}'),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(18),
                                  border:
                                      Border.all(color: AppColors.lightBorder),
                                  boxShadow: AppColors.cardShadow,
                                ),
                                child: Row(
                                  children: [
                                    AppNetworkImage(
                                      url: pkg.coverImageUrl,
                                      width: 80,
                                      height: 80,
                                      borderRadius: 14,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pkg.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            pkg.organizer.businessName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            CurrencyFormatter.formatPaise(
                                                pkg.priceInPaise),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppRatingChip(
                                        rating: pkg.organizer.rating),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );

                  case CatalogTab.SERVICES:
                    return servicesAsync.when(
                      loading: () => const Center(child: AppLoader()),
                      error: (e, _) => Center(child: Text(e.toString())),
                      data: (srvs) {
                        final filtered = srvs.where((s) {
                          return searchQuery.isEmpty ||
                              s.name
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase());
                        }).toList();

                        if (filtered.isEmpty) {
                          return const AppEmptyView(
                            title: 'No Services Found',
                            subtitle: 'Try changing your search terms.',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final srv = filtered[index];
                            return GestureDetector(
                              onTap: () =>
                                  context.push('/detail/service/${srv.id}'),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(18),
                                  border:
                                      Border.all(color: AppColors.lightBorder),
                                  boxShadow: AppColors.cardShadow,
                                ),
                                child: Row(
                                  children: [
                                    AppNetworkImage(
                                      url: srv.coverImageUrl,
                                      width: 80,
                                      height: 80,
                                      borderRadius: 14,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            srv.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            srv.organizer.businessName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            CurrencyFormatter.formatPaise(
                                                srv.priceInPaise),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        size: 14, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );

                  case CatalogTab.EVENTS:
                  case CatalogTab.ORGANIZERS:
                    return eventsAsync.when(
                      loading: () => const Center(child: AppLoader()),
                      error: (e, _) => Center(child: Text(e.toString())),
                      data: (evts) {
                        final filtered = evts.where((e) {
                          return searchQuery.isEmpty ||
                              e.title
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase());
                        }).toList();

                        if (filtered.isEmpty) {
                          return const AppEmptyView(
                            title: 'No Events Found',
                            subtitle: 'Try searching for other keywords.',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final evt = filtered[index];
                            return GestureDetector(
                              onTap: () =>
                                  context.push('/detail/event/${evt.id}'),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(18),
                                  border:
                                      Border.all(color: AppColors.lightBorder),
                                  boxShadow: AppColors.cardShadow,
                                ),
                                child: Row(
                                  children: [
                                    AppNetworkImage(
                                      url: evt.coverImageUrl,
                                      width: 80,
                                      height: 80,
                                      borderRadius: 14,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            evt.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            evt.venueName ?? 'Online Event',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          AppStatusBadge(
                                            label: evt.mode == EventMode.ONLINE
                                                ? 'Online'
                                                : 'In-Person',
                                            status: BadgeStatus.accepted,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        size: 14, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            );
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
}
