import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../home/domain/entities/catalog_entities.dart';
import '../../domain/entities/host_entities.dart';
import '../providers/host_providers.dart';

class CreateEventScreen extends HookConsumerWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final venueController = useTextEditingController();
    final capacityController = useTextEditingController();
    final priceController = useTextEditingController();
    final selectedDate =
        useState(DateTime.now().add(const Duration(days: 14)));
    final isPublishing = useState(false);

    Future<void> handlePublish() async {
      if (titleController.text.trim().isEmpty ||
          venueController.text.trim().isEmpty) {
        AppSnackbar.show(
          context,
          message: 'Please enter event title and venue.',
          type: SnackbarType.error,
        );
        return;
      }

      isPublishing.value = true;
      final pricePaise =
          (double.tryParse(priceController.text.trim()) ?? 999) * 100;
      final capacity = int.tryParse(capacityController.text.trim()) ?? 500;

      final newEvent = HostEventItem(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        title: titleController.text.trim(),
        eventDate: selectedDate.value,
        venue: venueController.text.trim(),
        totalRegistrations: 0,
        checkedInCount: 0,
        totalCapacity: capacity,
        revenueInPaise: 0,
        isLive: true,
        coverImageUrl:
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop',
        ticketTiers: [
          TicketType(
            id: 'tkt_custom_01',
            name: 'General Admission',
            priceInPaise: pricePaise.round(),
            description: 'Standard Entry Pass',
            quantity: capacity,
          ),
        ],
      );

      await ref.read(hostedEventsProvider.notifier).createEvent(newEvent);
      isPublishing.value = false;

      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: 'Event published and ticketing is now live!',
          type: SnackbarType.success,
        );
        context.pop();
      }
    }

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
          'Create & Host Event',
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
            Text(
              'Public Event Details 🎟️',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fill in the event information to generate tickets and enable instant QR check-in.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  AppTextField(
                    label: 'Event Title',
                    hint: 'e.g. Electric Dreams EDM Festival',
                    controller: titleController,
                    prefixIcon: const Icon(Icons.festival_outlined,
                        color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Venue Name & Address',
                    hint: 'e.g. NSCI Dome, Worli, Mumbai',
                    controller: venueController,
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.value,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        selectedDate.value = picked;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lightCardAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Event Date',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateFormatter.formatDate(selectedDate.value),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_calendar_rounded,
                              size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Max Capacity',
                          hint: '1000',
                          controller: capacityController,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.people_outline_rounded,
                              color: AppColors.textMuted, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Base Ticket (₹)',
                          hint: '1499',
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.currency_rupee_rounded,
                              color: AppColors.textMuted, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            AppPrimaryButton(
              text: isPublishing.value ? 'Publishing…' : 'Publish & Launch Sales',
              isLoading: isPublishing.value,
              onPressed: isPublishing.value ? null : handlePublish,
            ),
          ],
        ),
      ),
    );
  }
}
