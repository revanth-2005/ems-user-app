import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/domain/entities/catalog_entities.dart';
import '../../../home/presentation/providers/catalog_providers.dart';
import '../../../home/presentation/widgets/follow_button.dart';

class FollowedOrganizersScreen extends HookConsumerWidget {
  const FollowedOrganizersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState<String>('');

    // Always fetch fresh followed organizers whenever the screen is opened
    useEffect(() {
      Future.microtask(() => ref.invalidate(followedOrganizersProvider));
      return null;
    }, const []);

    final followedAsync = ref.watch(followedOrganizersProvider);

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.getTextPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Followed Studios & Organizers',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getCardAlt(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: TextField(
                controller: searchController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Search followed vendors or cities...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.getTextMuted(context),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.primary),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            searchController.clear();
                            searchQuery.value = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (val) {
                  searchQuery.value = val.trim().toLowerCase();
                },
              ),
            ),
          ),
        ),
      ),
      body: followedAsync.when(
        loading: () => const AppLoader(message: 'Loading your followed vendors...'),
        error: (err, __) => AppErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(followedOrganizersProvider),
        ),
        data: (organizers) {
          final query = searchQuery.value;
          final filtered = query.isEmpty
              ? organizers
              : organizers.where((org) {
                  final nameMatch =
                      org.effectiveName.toLowerCase().contains(query);
                  final cityMatch =
                      org.city?.toLowerCase().contains(query) ?? false;
                  return nameMatch || cityMatch;
                }).toList();

          if (filtered.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(followedOrganizersProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.people_outline_rounded,
                            size: 38,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          query.isEmpty
                              ? 'No Followed Organizers Yet'
                              : 'No Matches Found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          query.isEmpty
                              ? 'Follow organizers to receive priority search recommendations and direct updates.'
                              : 'No followed vendors match "$query".',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (query.isNotEmpty) {
                              searchController.clear();
                              searchQuery.value = '';
                            } else {
                              ref.read(activeCatalogTabProvider.notifier).state =
                                  CatalogTab.ORGANIZERS;
                              context.push(AppRoutes.search);
                            }
                          },
                          icon: Icon(
                            query.isEmpty
                                ? Icons.explore_rounded
                                : Icons.clear_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            query.isEmpty ? 'Explore Organizers' : 'Clear Search',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(followedOrganizersProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final org = filtered[idx];
                return _FollowedOrganizerCard(organizer: org);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FollowedOrganizerCard extends ConsumerWidget {
  final OrganizerSummary organizer;

  const _FollowedOrganizerCard({required this.organizer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cityName =
        organizer.city?.isNotEmpty == true ? organizer.city! : 'India';

    return GestureDetector(
      onTap: () => context.push(
          AppRoutes.organizerProfile.replaceAll(':id', organizer.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppColors.getCardDecoration(
          context,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // Left Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 58,
                height: 58,
                child: organizer.effectiveAvatar != null
                    ? AppNetworkImage(
                        url: organizer.effectiveAvatar,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.avatarGradient,
                        ),
                        child: Center(
                          child: Text(
                            organizer.effectiveName.isNotEmpty
                                ? organizer.effectiveName[0].toUpperCase()
                                : 'O',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle Info
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
                      const SizedBox(width: 2),
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
                    '${organizer.followerCount} followers • ${organizer.packageCount} packages',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Right Follow Action Button
            const SizedBox(width: 8),
            FollowButton(
              organizerId: organizer.id,
              organizerName: organizer.effectiveName,
              initialIsFollowed: true,
              initialFollowerCount: organizer.followerCount,
              isCompact: true,
              onFollowChanged: (isFollowing) {
                if (!isFollowing) {
                  // Invalidate list so it removes immediately on unfollow
                  ref.invalidate(followedOrganizersProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
