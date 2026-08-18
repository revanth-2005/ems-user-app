import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';

class EventDetailScreen extends HookConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final selectedTicket = useState<TicketType?>(null);
    final isRegistering = useState(false);

    Future<void> handleRegister() async {
      if (selectedTicket.value == null) return;
      isRegistering.value = true;
      await Future.delayed(const Duration(milliseconds: 700));
      isRegistering.value = false;

      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: 'Ticket confirmed! Added to your bookings.',
          type: SnackbarType.success,
        );
        context.go(AppRoutes.bookings);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: eventAsync.when(
        loading: () => const Center(child: AppLoader(message: 'Loading event…')),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          if (selectedTicket.value == null && event.ticketTypes.isNotEmpty) {
            selectedTicket.value = event.ticketTypes.first;
          }

          final currentTicket = selectedTicket.value ??
              (event.ticketTypes.isNotEmpty ? event.ticketTypes.first : null);

          return CustomScrollView(
            slivers: [
              // ── Hero Header ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.lightSurface,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        url: event.coverImageUrl,
                        categoryHint: event.category?.name ?? 'Live Event',
                        titleHint: event.title,
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

              // ── Content ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge row
                      Row(
                        children: [
                          AppStatusBadge(
                            label: event.mode == EventMode.ONLINE
                                ? 'Virtual Experience'
                                : 'Live In-Person',
                            status: BadgeStatus.accepted,
                          ),
                          const SizedBox(width: 8),
                          AppStatusBadge(
                            label: event.approvalMode == ApprovalMode.INSTANT
                                ? 'Instant Confirmation'
                                : 'Host Approval Required',
                            status: BadgeStatus.pending,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        event.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Hosted by ${event.hostName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.lightBorder),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.calendar_today_rounded,
                              title: DateFormatter.formatEventDate(
                                  event.startDatetime),
                              subtitle: DateFormatter.formatEventTime(
                                  event.startDatetime),
                            ),
                            const Divider(
                                height: 20, color: AppColors.lightBorder),
                            _InfoRow(
                              icon: Icons.location_on_rounded,
                              title: event.venueName ?? 'Online Link',
                              subtitle: event.venueAddress ??
                                  event.venueCity ??
                                  'Shared upon confirmation',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      if (event.description != null) ...[
                        Text(
                          'About this Event',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Ticket Types Selector
                      if (event.ticketTypes.isNotEmpty) ...[
                        Text(
                          'Select Pass',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...event.ticketTypes.map((t) {
                          final isSelected = currentTicket?.id == t.id;
                          return GestureDetector(
                            onTap: () => selectedTicket.value = t,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.06)
                                    : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.lightBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (t.description != null)
                                          Text(
                                            t.description!,
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    t.isFree
                                        ? 'FREE'
                                        : CurrencyFormatter.formatPaise(
                                            t.priceInPaise),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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
      bottomNavigationBar: eventAsync.valueOrNull == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                border: Border(
                  top: BorderSide(color: AppColors.lightBorder),
                ),
              ),
              child: SafeArea(
                child: AppPrimaryButton(
                  text: isRegistering.value
                      ? 'Confirming…'
                      : 'Register Now — ${selectedTicket.value?.isFree == true ? "FREE" : (selectedTicket.value != null ? CurrencyFormatter.formatPaise(selectedTicket.value!.priceInPaise) : "")}',
                  isLoading: isRegistering.value,
                  onPressed: isRegistering.value ? null : handleRegister,
                ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
