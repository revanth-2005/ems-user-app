import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/organizer_entities.dart';
import '../providers/organizer_providers.dart';

class AvailabilityCalendarScreen extends HookConsumerWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(organizerAvailabilityProvider);
    final currentMonth = ref.watch(selectedCalendarMonthProvider);

    void showDateActionSheet(AvailabilitySlot slot) {
      final dateStr = DateFormatter.formatDate(slot.date);
      final noteCtrl = TextEditingController(text: 'Booked offline');

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              if (slot.isConfirmedBooking) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_rounded,
                          color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirmed Client Event',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade900,
                              ),
                            ),
                            Text(
                              slot.bookingTitle ?? 'Client Booking Slot Locked',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This date was automatically locked when you accepted the booking. It cannot be booked by other clients.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (slot.isBlocked) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block_rounded,
                          color: Colors.amber.shade900, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manually Blocked Date',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            Text(
                              slot.reason ?? 'Blackout window',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  text: 'Unblock Date (Make Available)',
                  onPressed: () async {
                    await ref
                        .read(organizerRepositoryProvider)
                        .toggleDateBlocked(slot.date);
                    ref.invalidate(organizerAvailabilityProvider);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      AppSnackbar.show(
                        context,
                        message: '$dateStr is now open for bookings.',
                        type: SnackbarType.success,
                      );
                    }
                  },
                ),
              ] else ...[
                Text(
                  'Block Out This Calendar Date',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Clients will see this date as unavailable for booking inquiries.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reason for Blackout (Optional)',
                    hintText: 'e.g. Offline booking, Personal leave',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  text: 'Block This Date 🔒',
                  onPressed: () async {
                    await ref.read(organizerRepositoryProvider).toggleDateBlocked(
                          slot.date,
                          reason: noteCtrl.text.trim(),
                        );
                    ref.invalidate(organizerAvailabilityProvider);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      AppSnackbar.show(
                        context,
                        message: '$dateStr is now blocked.',
                        type: SnackbarType.info,
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.getTextPrimary(context), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Availability Calendar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Month Switcher Bar ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: AppColors.getCardShadow(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      ref.read(selectedCalendarMonthProvider.notifier).state =
                          DateTime(currentMonth.year, currentMonth.month - 1);
                    },
                  ),
                  Text(
                    '${_monthName(currentMonth.month)} ${currentMonth.year}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      ref.read(selectedCalendarMonthProvider.notifier).state =
                          DateTime(currentMonth.year, currentMonth.month + 1);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Calendar Container ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: AppColors.getCardShadow(context),
              ),
              child: availabilityAsync.when(
                loading: () => const Center(child: AppLoader()),
                error: (e, _) => AppErrorView(message: e.toString()),
                data: (slots) {
                  const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final firstDayOffset =
                      DateTime(currentMonth.year, currentMonth.month, 1).weekday - 1;

                  return Column(
                    children: [
                      // Weekdays row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: weekdays
                            .map((d) => SizedBox(
                                  width: 36,
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: slots.length + firstDayOffset,
                        itemBuilder: (context, index) {
                          if (index < firstDayOffset) {
                            return const SizedBox.shrink();
                          }
                          final slot = slots[index - firstDayOffset];
                          final isConfirmed = slot.isConfirmedBooking;
                          final isBlocked = slot.isBlocked && !isConfirmed;

                          Color bgColor = Colors.transparent;
                          Color borderColor = Colors.grey.shade200;
                          Color dotColor = Colors.transparent;

                          if (isConfirmed) {
                            bgColor = Colors.green.shade50;
                            borderColor = Colors.green.shade400;
                            dotColor = Colors.green.shade700;
                          } else if (isBlocked) {
                            bgColor = Colors.amber.shade50;
                            borderColor = Colors.amber.shade300;
                            dotColor = Colors.amber.shade800;
                          }

                          return GestureDetector(
                            onTap: () => showDateActionSheet(slot),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${slot.date.day}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isConfirmed
                                          ? Colors.green.shade900
                                          : isBlocked
                                              ? Colors.amber.shade900
                                              : AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Legend Bar ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegend(Colors.green.shade600, 'Confirmed'),
                  _buildLegend(Colors.amber.shade800, 'Blocked'),
                  _buildLegend(Colors.grey.shade400, 'Available'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '💡 Tap on any calendar date to block it out or view booking specifics.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[month];
  }
}
