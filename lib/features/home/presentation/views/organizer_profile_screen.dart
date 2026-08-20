import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_rating_chip.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/common_widgets/app_video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';
import '../widgets/catalog_cards.dart';

/// Public Organizer Profile Screen displaying the organizer's studio details,
/// active packages, standalone services, portfolio gallery, and reviews.
class OrganizerProfileScreen extends HookConsumerWidget {
  final String organizerId;

  const OrganizerProfileScreen({super.key, required this.organizerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizerAsync = ref.watch(organizerDetailProvider(organizerId));

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      body: organizerAsync.when(
        loading: () =>
            const Center(child: AppLoader(message: 'Loading studio profile…')),
        error: (err, _) => AppErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(organizerDetailProvider(organizerId)),
        ),
        data: (org) {
          if (org == null) {
            return Scaffold(
              appBar: AppBar(backgroundColor: AppColors.getSurface(context)),
              body: Center(
                child: Text(
                  'Organizer profile not found.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
            );
          }

          return DefaultTabController(
            length: 4,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // App Bar
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: AppColors.getSurface(context),
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.getTextPrimary(context)),
                      onPressed: () => context.pop(),
                    ),
                    title: Text(
                      org.effectiveName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    centerTitle: true,
                  ),

                  // Header Info Profile Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.getBorder(context)),
                          boxShadow: AppColors.getCardShadow(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppNetworkImage(
                                  url: org.effectiveAvatar,
                                  titleHint: org.effectiveName,
                                  width: 64,
                                  height: 64,
                                  borderRadius: 20,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              org.businessName,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.getTextPrimary(context),
                                              ),
                                            ),
                                          ),
                                          AppRatingChip(rating: org.rating),
                                        ],
                                      ),
                                      if (org.displayName != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '@${org.displayName}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const AppStatusBadge(
                                            label: 'KYC Verified',
                                            status: BadgeStatus.accepted,
                                          ),
                                          if (org.city != null) ...[
                                            const SizedBox(width: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_rounded,
                                                  size: 13,
                                                  color: AppColors.accentRose,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  org.city!,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors
                                                        .getTextSecondary(context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (org.bio != null && org.bio!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                org.bio!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.getTextSecondary(context),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tab Navigation Bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.getTextMuted(context),
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        tabs: const [
                          Tab(text: 'Packages'),
                          Tab(text: 'Services'),
                          Tab(text: 'Portfolio'),
                          Tab(text: 'Reviews'),
                        ],
                      ),
                      backgroundColor: AppColors.getSurface(context),
                    ),
                  ),
                ];
              },

              // Tab Contents
              body: TabBarView(
                children: [
                  // Tab 1: Bundled Packages List
                  _OrganizerPackagesTab(organizerId: organizerId),

                  // Tab 2: Standalone Services List
                  _OrganizerServicesTab(organizerId: organizerId),

                  // Tab 3: Portfolio Items Grid
                  _OrganizerPortfolioTab(portfolioItems: org.portfolioItems),

                  // Tab 4: Reviews & Ratings
                  const _OrganizerReviewsTab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this._tabBar, {required this.backgroundColor});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor;
  }
}

class _OrganizerPackagesTab extends HookConsumerWidget {
  final String organizerId;

  const _OrganizerPackagesTab({required this.organizerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesProvider);

    return packagesAsync.when(
      loading: () => const Center(child: AppLoader(message: 'Loading packages…')),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (pkgs) {
        final orgPkgs = pkgs.where((p) => p.organizer.id == organizerId).toList();
        final displayList = orgPkgs.isNotEmpty ? orgPkgs : pkgs;

        if (displayList.isEmpty) {
          return const AppEmptyView(
            icon: Icons.inventory_2_outlined,
            title: 'No Bundled Packages',
            subtitle: 'This organizer has no active package listings currently.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: displayList.length,
          itemBuilder: (context, idx) {
            final pkg = displayList[idx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PackageCard(
                package: pkg,
                onTap: () => context.push(
                    AppRoutes.packageDetail.replaceAll(':id', pkg.id)),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrganizerServicesTab extends HookConsumerWidget {
  final String organizerId;

  const _OrganizerServicesTab({required this.organizerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return servicesAsync.when(
      loading: () => const Center(child: AppLoader(message: 'Loading services…')),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (srvs) {
        final orgSrvs = srvs.where((s) => s.organizer.id == organizerId).toList();
        final displayList = orgSrvs.isNotEmpty ? orgSrvs : srvs;

        if (displayList.isEmpty) {
          return const AppEmptyView(
            icon: Icons.design_services_outlined,
            title: 'No Standalone Services',
            subtitle: 'This organizer has no standalone service listings currently.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: displayList.length,
          itemBuilder: (context, idx) {
            final srv = displayList[idx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ServiceCard(
                service: srv,
                onTap: () => context.push(
                    AppRoutes.serviceDetail.replaceAll(':id', srv.id)),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrganizerPortfolioTab extends StatelessWidget {
  final List<PortfolioItem> portfolioItems;

  const _OrganizerPortfolioTab({required this.portfolioItems});

  @override
  Widget build(BuildContext context) {
    if (portfolioItems.isEmpty) {
      return const AppEmptyView(
        icon: Icons.collections_outlined,
        title: 'Portfolio Showcase',
        subtitle: 'No portfolio showcase media uploaded yet.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: portfolioItems.length,
      itemBuilder: (context, idx) {
        final item = portfolioItems[idx];
        return GestureDetector(
          onTap: () {
            _showMediaLightbox(context, item);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  url: item.mediaUrl,
                  fit: BoxFit.cover,
                ),
                if (item.isVideo) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VIDEO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                if (item.caption != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Text(
                        item.caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMediaLightbox(BuildContext context, PortfolioItem item) {
    if (item.isVideo) {
      showAppVideoPlayerDialog(
        context,
        item.mediaUrl,
        title: item.caption?.isNotEmpty == true
            ? item.caption!
            : 'Portfolio Video',
        caption: item.caption,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Portfolio Photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: AppNetworkImage(
                  url: item.mediaUrl,
                  fit: BoxFit.contain,
                ),
              ),
              if (item.caption != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    item.caption!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizerReviewsTab extends StatelessWidget {
  const _OrganizerReviewsTab();

  @override
  Widget build(BuildContext context) {
    final reviews = [
      {
        'author': 'Ananya Sharma',
        'rating': 5.0,
        'comment': 'Outstanding decor, prompt communication, and spotless execution!',
        'date': '2 weeks ago',
      },
      {
        'author': 'Vikram R.',
        'rating': 5.0,
        'comment': 'Managed our 500-guest reception smoothly without any hiccups. Highly recommended!',
        'date': '1 month ago',
      },
      {
        'author': 'Priya Nair',
        'rating': 4.8,
        'comment': 'Great catering quality and friendly staff.',
        'date': '2 months ago',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reviews.length,
      itemBuilder: (context, idx) {
        final rev = reviews[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.getBorder(context)),
            boxShadow: AppColors.getCardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rev['author'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  AppRatingChip(rating: (rev['rating'] as double)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                rev['comment'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.getTextSecondary(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                rev['date'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.getTextMuted(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
