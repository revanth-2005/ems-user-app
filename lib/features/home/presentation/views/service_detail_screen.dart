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
import '../../../../core/common_widgets/app_video_player.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';

class ServiceDetailScreen extends HookConsumerWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));
    final activeMediaIndex = useState(0);

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      body: serviceAsync.when(
        loading: () =>
            const Center(child: AppLoader(message: 'Loading service…')),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ),
        data: (srv) {
          if (srv == null) {
            return Center(
              child: Text(
                'Service not found',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            );
          }

          final List<PortfolioItem> mediaList = [];
          if (srv.coverImageUrl != null && srv.coverImageUrl!.isNotEmpty) {
            mediaList.add(PortfolioItem(
              mediaUrl: srv.coverImageUrl!,
              mediaType: 'image',
              caption: 'Service Cover Banner',
            ));
          }
          for (final item in srv.mediaItems) {
            if (!mediaList.any((m) => m.mediaUrl == item.mediaUrl)) {
              mediaList.add(item);
            }
          }

          final currentMedia = mediaList.isNotEmpty
              ? mediaList[activeMediaIndex.value.clamp(0, mediaList.length - 1)]
              : null;

          return CustomScrollView(
            slivers: [
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
                  background: GestureDetector(
                    onTap: () {
                      if (currentMedia != null) {
                        _showMediaLightbox(context, currentMedia);
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          url: currentMedia?.mediaUrl ?? srv.coverImageUrl,
                          categoryHint: srv.categoryName,
                          titleHint: srv.name,
                          fit: BoxFit.cover,
                        ),
                        if (currentMedia?.isVideo == true) ...[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
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
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        AppNetworkImage(
                                          url: item.mediaUrl,
                                          fit: BoxFit.cover,
                                        ),
                                        if (item.isVideo)
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow_rounded,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
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
                          AppStatusBadge(
                            label: srv.categoryName,
                            status: BadgeStatus.accepted,
                          ),
                          AppRatingChip(rating: srv.organizer.rating),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        srv.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 6),

                      GestureDetector(
                        onTap: () => context.push(
                            AppRoutes.organizerProfile.replaceAll(':id', srv.organizer.id)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Provided by ${srv.organizer.businessName}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 12, color: AppColors.primary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Pricing Card ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getCardAlt(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      srv.pricingUnitLabel.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.formatPaise(srv.priceInPaise),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    '${srv.priceInPaise > 0 ? ((srv.depositRequiredPaise / srv.priceInPaise) * 100).round() : 20}% Advance Deposit',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 24, color: AppColors.getBorder(context)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Advance Required Today',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatPaise(srv.depositRequiredPaise),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Lead Time Alert ──────────────────────────────────
                      if (srv.leadTimeDays > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 18, color: AppColors.warning),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Booking lead time: Requires at least ${srv.leadTimeDays} days advance notice.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Description ──────────────────────────────────────
                      if (srv.description != null && srv.description!.isNotEmpty) ...[
                        Text(
                          'Service Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          srv.description!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Cancellation Policy Card ─────────────────────────
                      Text(
                        'Cancellation Policy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.getBorder(context)),
                          boxShadow: AppColors.getCardShadow(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_user_outlined,
                                    size: 16, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'Free Cancellation up to 48 Hours Before Event',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Full refund of advance deposit if cancelled 48 hours prior to start time. 50% refund between 24-48 hours.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.getTextSecondary(context),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Organizer Summary Card ───────────────────────────
                      Text(
                        'Verified Provider',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.getBorder(context)),
                          boxShadow: AppColors.getCardShadow(context),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.business_rounded,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    srv.organizer.businessName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 14, color: AppColors.warning),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${srv.organizer.rating} • ${srv.organizer.city}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.getTextSecondary(context),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const AppStatusBadge(
                              label: 'KYC Verified',
                              status: BadgeStatus.accepted,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: serviceAsync.valueOrNull == null
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
                          'Starting from',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(
                              serviceAsync.valueOrNull!.priceInPaise),
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
                        text: 'Schedule & Book',
                        onPressed: () {
                          _showSlotPickerSheet(
                              context, ref, serviceAsync.valueOrNull!);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showSlotPickerSheet(BuildContext context, WidgetRef ref, dynamic srv) {
    final minLeadDays = (srv.leadTimeDays != null && srv.leadTimeDays > 0)
        ? srv.leadTimeDays as int
        : 1;
    DateTime pickedDate = DateTime.now().add(Duration(days: minLeadDays));
    String startTime = '10:00';
    String endTime = '18:00';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.getBorder(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Schedule Service Date & Time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select your event date (min $minLeadDays days lead time) and operational hours.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Selector
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.getCardAlt(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Date',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                              Text(
                                DateFormatter.formatDate(pickedDate),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: pickedDate,
                              firstDate: DateTime.now()
                                  .add(Duration(days: minLeadDays)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() {
                                pickedDate = picked;
                              });
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Time Window
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 10, minute: 0),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setModalState(() {
                                final h = time.hour.toString().padLeft(2, '0');
                                final m =
                                    time.minute.toString().padLeft(2, '0');
                                startTime = '$h:$m';
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.getCardAlt(context),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppColors.getBorder(context)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Start Time',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.getTextSecondary(context))),
                                Text(startTime,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.getTextPrimary(context))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 18, minute: 0),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setModalState(() {
                                final h = time.hour.toString().padLeft(2, '0');
                                final m =
                                    time.minute.toString().padLeft(2, '0');
                                endTime = '$h:$m';
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.getCardAlt(context),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppColors.getBorder(context)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('End Time',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.getTextSecondary(context))),
                                Text(endTime,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.getTextPrimary(context))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  AppPrimaryButton(
                    text: 'Add to Cart & Checkout',
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref.read(cartProvider.notifier).addService(
                            srv,
                            pickedDate,
                            startTime: startTime,
                            endTime: endTime,
                          );
                      if (context.mounted) {
                        AppSnackbar.show(
                          context,
                          message: '✓ ${srv.name} scheduled & added to cart!',
                          type: SnackbarType.success,
                        );
                        context.push(AppRoutes.cart);
                      }
                    },
                  ),
                ],
              ),
            );
          },
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
