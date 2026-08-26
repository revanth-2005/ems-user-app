import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_rating_chip.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../bookings/presentation/providers/booking_providers.dart';
import '../../../bookings/presentation/widgets/add_to_cart_dialog.dart';
import '../../../../core/common_widgets/app_video_player.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';
import '../widgets/full_package_specs_sheet.dart';

class PackageDetailScreen extends HookConsumerWidget {
  final String packageId;

  const PackageDetailScreen({super.key, required this.packageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageAsync = ref.watch(packageDetailProvider(packageId));
    final selectedDate =
        useState(DateTime.now().add(const Duration(days: 14)));
    final activeMediaIndex = useState(0);

    Future<void> pickEventDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime.now().add(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (ctx, child) {
          return Theme(
            data: Theme.of(context),
            child: child!,
          );
        },
      );

      if (picked != null) {
        selectedDate.value = picked;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      body: packageAsync.when(
        loading: () =>
            const Center(child: AppLoader(message: 'Loading package…')),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ),
        data: (pkg) {
          if (pkg == null) {
            return Center(
              child: Text(
                'Package not found',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            );
          }

          final List<PortfolioItem> mediaList = [];
          if (pkg.coverImageUrl != null && pkg.coverImageUrl!.isNotEmpty) {
            mediaList.add(PortfolioItem(
              mediaUrl: pkg.coverImageUrl!,
              mediaType: 'image',
              caption: 'Package Cover Banner',
            ));
          }
          for (final item in pkg.mediaItems) {
            if (!mediaList.any((m) => m.mediaUrl == item.mediaUrl)) {
              mediaList.add(item);
            }
          }

          final currentMedia = mediaList.isNotEmpty
              ? mediaList[activeMediaIndex.value.clamp(0, mediaList.length - 1)]
              : null;

          return CustomScrollView(
            slivers: [
              // ── Hero Header ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.getSurface(context),
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: AppColors.getCardShadow(context),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.getTextPrimary(context)),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: currentMedia?.isVideo == true
                      ? AppInlineVideoPlayer(
                          key: ValueKey(currentMedia!.mediaUrl),
                          videoUrl: currentMedia.mediaUrl,
                          title: currentMedia.caption?.isNotEmpty == true
                              ? currentMedia.caption!
                              : pkg.name,
                          caption: currentMedia.caption,
                          autoPlay: true,
                          looping: true,
                          onExpandFullscreen: () =>
                              _showMediaLightbox(context, currentMedia),
                        )
                      : GestureDetector(
                          onTap: () {
                            if (currentMedia != null) {
                              _showMediaLightbox(context, currentMedia);
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppNetworkImage(
                                url: currentMedia?.mediaUrl ?? pkg.coverImageUrl,
                                categoryHint: pkg.categoryName,
                                titleHint: pkg.name,
                                fit: BoxFit.cover,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // ── Details Body ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Gallery Thumbnail Switcher Strip ─────────────────
                      if (mediaList.length > 1) ...[
                        SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: mediaList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (ctx, idx) {
                              final item = mediaList[idx];
                              final isSelected =
                                  activeMediaIndex.value == idx;
                              return GestureDetector(
                                onTap: () => activeMediaIndex.value = idx,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.getBorder(context),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: AppNetworkImage(
                                      url: item.mediaUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppStatusBadge(
                            label: 'Verified Vendor Package',
                            status: BadgeStatus.accepted,
                          ),
                          AppRatingChip(rating: pkg.organizer.rating),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        pkg.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 6),

                      GestureDetector(
                        onTap: () => context.push(
                            AppRoutes.organizerProfile.replaceAll(':id', pkg.organizer.id)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Organized by ${pkg.organizer.businessName}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 12, color: AppColors.getTextPrimary(context)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date selector card
                      GestureDetector(
                        onTap: pickEventDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.getBorder(context)),
                            boxShadow: AppColors.getCardShadow(context),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Event Date',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                    Text(
                                      DateFormatter.formatDate(
                                          selectedDate.value),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Change',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // View Full Package Specs Button Card
                      GestureDetector(
                        onTap: () => showFullPackageSpecs(context, pkg),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.getCardAlt(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.getBorder(context)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment_outlined,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'View Full Package Specs >',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: AppColors.getTextPrimary(context), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      if (pkg.description != null) ...[
                        Text(
                          'Package Overview',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pkg.description!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Line items / inclusions
                      if (pkg.lineItems.isNotEmpty) ...[
                        Text(
                          'What’s Included',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...pkg.lineItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusCompleted
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: AppColors.statusCompleted,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: packageAsync.valueOrNull == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                border: Border(
                  top: BorderSide(color: AppColors.getBorder(context)),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Price',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(
                              packageAsync.valueOrNull!.priceInPaise),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Add to Cart',
                        onPressed: () {
                          final currentPkg = packageAsync.valueOrNull;
                          if (currentPkg == null) return;
                          showAddToCartDialog(
                            context: context,
                            title: currentPkg.name,
                            leadTimeDays: 7,
                            onConfirm: (eventDateStr, startTime, endTime) async {
                              final date =
                                  DateTime.tryParse(eventDateStr) ?? selectedDate.value;
                              await ref
                                  .read(cartProvider.notifier)
                                  .addPackage(
                                    currentPkg,
                                    date,
                                    startTime: startTime,
                                    endTime: endTime,
                                  );
                              if (context.mounted) {
                                AppSnackbar.show(
                                  context,
                                  message:
                                      '✓ Added to Cart for $eventDateStr!',
                                  type: SnackbarType.success,
                                );
                                context.push(AppRoutes.cart);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showMediaLightbox(BuildContext context, PortfolioItem item) {
    if (item.isVideo) {
      showAppVideoPlayerDialog(
        context,
        item.mediaUrl,
        title: item.caption?.isNotEmpty == true
            ? item.caption!
            : 'Video Showcase',
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
                  'Media Preview',
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
              if (item.caption != null && item.caption!.isNotEmpty)
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
