import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/organizer_providers.dart';

class AvailabilityCalendarScreen extends HookConsumerWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(organizerAvailabilityProvider);
    final currentMonth = ref.watch(selectedCalendarMonthProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Availability Calendar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month switcher
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.textPrimary),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textPrimary),
                    onPressed: () {
                      ref.read(selectedCalendarMonthProvider.notifier).state =
                          DateTime(currentMonth.year, currentMonth.month + 1);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calendar Grid
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: availabilityAsync.when(
                loading: () => const Center(child: AppLoader()),
                error: (e, _) => AppErrorView(message: e.toString()),
                data: (slots) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final isBlocked = slot.isBlocked;
                      return GestureDetector(
                        onTap: () {
                          AppSnackbar.show(
                            context,
                            message: isBlocked
                                ? 'Day marked available'
                                : 'Day marked blocked',
                            type: SnackbarType.info,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBlocked
                                ? AppColors.accentRose.withValues(alpha: 0.12)
                                : AppColors.statusCompleted
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isBlocked
                                  ? AppColors.accentRose
                                  : AppColors.statusCompleted
                                      .withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${slot.date.day}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isBlocked
                                      ? AppColors.accentRose
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isBlocked
                                      ? AppColors.accentRose
                                      : AppColors.statusCompleted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                    color: AppColors.statusCompleted, label: 'Available'),
                const SizedBox(width: 24),
                _LegendItem(color: AppColors.accentRose, label: 'Blocked / Booked'),
              ],
            ),
          ],
        ),
      ),
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
