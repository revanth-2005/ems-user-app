import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../home/domain/entities/catalog_entities.dart';
import '../../domain/entities/host_entities.dart';
import '../providers/host_providers.dart';
import '../widgets/quota_limit_dialog.dart';

class EventManagementHubScreen extends HookConsumerWidget {
  final String eventId;

  const EventManagementHubScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0);
    final eventAsync = ref.watch(hostEventDetailProvider(eventId));

    return eventAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.getBg(context),
        appBar: AppBar(
          backgroundColor: AppColors.getSurface(context),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getTextPrimary(context), size: 18),
            onPressed: () => context.pop(),
          ),
          title: Text('Loading Event...', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: AppLoader()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.getBg(context),
        appBar: AppBar(
          backgroundColor: AppColors.getSurface(context),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getTextPrimary(context), size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Event Hub'),
        ),
        body: AppErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(hostEventDetailProvider(eventId)),
        ),
      ),
      data: (event) {
        if (event == null) {
          return Scaffold(
            backgroundColor: AppColors.getBg(context),
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getTextPrimary(context), size: 18),
                onPressed: () => context.pop(),
              ),
            ),
            body: const AppEmptyView(
              icon: Icons.event_busy_rounded,
              title: 'Event Not Found',
              subtitle: 'The selected hosted event could not be found or has been removed.',
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
                  color: AppColors.getTextPrimary(context), size: 18),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    _StatusBadge(status: event.status),
                    const SizedBox(width: 8),
                    Text(
                      event.isOnline ? 'Virtual Stream' : (event.venueCity ?? 'In-Person'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () {
                  ref.invalidate(hostEventDetailProvider(eventId));
                  ref.invalidate(hostAttendeeQueueProvider(eventId));
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: 'https://emsevents.app/events/${event.slug.isNotEmpty ? event.slug : event.id}',
                  ));
                  AppSnackbar.show(
                    context,
                    message: 'Event public link copied to clipboard!',
                    type: SnackbarType.success,
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppColors.getSurface(context),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _TabChip(label: 'Overview', icon: Icons.insights_rounded, isSelected: selectedTab.value == 0, onTap: () => selectedTab.value = 0),
                      _TabChip(label: 'Ticket Tiers (${event.ticketTypes.length})', icon: Icons.confirmation_number_outlined, isSelected: selectedTab.value == 1, onTap: () => selectedTab.value = 1),
                      _TabChip(
                        label: 'Approval Queue',
                        icon: Icons.people_alt_outlined,
                        badgeCount: event.pendingApprovalsCount,
                        isSelected: selectedTab.value == 2,
                        onTap: () => selectedTab.value = 2,
                      ),
                      _TabChip(label: 'Entry Scanner', icon: Icons.qr_code_scanner_rounded, isSelected: selectedTab.value == 3, onTap: () => selectedTab.value = 3),
                      _TabChip(label: 'Settings', icon: Icons.settings_outlined, isSelected: selectedTab.value == 4, onTap: () => selectedTab.value = 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (selectedTab.value) {
              0 => _OverviewTab(event: event),
              1 => _TicketTiersTab(event: event),
              2 => _AttendeeQueueTab(eventId: eventId),
              3 => _ScannerTab(eventId: eventId, event: event),
              _ => _SettingsTab(event: event),
            },
          ),
        );
      },
    );
  }
}

// ── Tab 1: Overview & Metrics ─────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final HostEventItem event;

  const _OverviewTab({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy • hh:mm a');
    final percentFilled = event.maxCapacity > 0
        ? ((event.totalRegistrations / event.maxCapacity) * 100).clamp(0, 100).toInt()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Metric Highlights Grid
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total Sold',
                  value: '${event.totalRegistrations}',
                  subtitle: 'Capacity: ${event.maxCapacity}',
                  icon: Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Ticket Revenue',
                  value: CurrencyFormatter.formatPaise(event.revenueInPaise),
                  subtitle: '${event.ticketTypes.length} Tiers',
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Checked-In',
                  value: '${event.checkedInCount}',
                  subtitle: '${event.totalRegistrations - event.checkedInCount} Remaining',
                  icon: Icons.verified_user_outlined,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Pending Approvals',
                  value: '${event.pendingApprovalsCount}',
                  subtitle: event.approvalMode == ApprovalMode.APPROVAL_REQUIRED ? 'Requires Action' : 'Instant Confirm',
                  icon: Icons.hourglass_top_rounded,
                  color: event.pendingApprovalsCount > 0 ? const Color(0xFFF59E0B) : AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Capacity Progress Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(18),
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
                      'Registration Capacity Quota',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      '$percentFilled%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentFilled / 100.0,
                    minHeight: 8,
                    backgroundColor: AppColors.getCardAlt(context),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${event.totalRegistrations} passes issued of ${event.maxCapacity} maximum available seats.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Event Schedule & Venue Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.getBorder(context)),
              boxShadow: AppColors.getCardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date, Time & Location',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dateFormat.format(event.startDatetime),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      event.isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
                      size: 16,
                      color: event.isOnline ? const Color(0xFF3B82F6) : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        event.isOnline ? (event.meetingUrl ?? 'Google Meet Stream') : event.venue,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Ticket Tiers Manager ───────────────────────────────────────────────

class _TicketTiersTab extends HookConsumerWidget {
  final HostEventItem event;

  const _TicketTiersTab({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void showAddTierModal() {
      final nameCtrl = TextEditingController();
      final descCtrl = TextEditingController();
      final priceCtrl = TextEditingController();
      final qtyCtrl = TextEditingController();
      var isFree = false;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.getSurface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Ticket Tier',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(label: 'Tier Name *', hint: 'e.g. VIP Front-Row Pass', controller: nameCtrl),
                const SizedBox(height: 12),
                AppTextField(label: 'Description', hint: 'Access privileges and perks...', controller: descCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        value: isFree,
                        title: Text('Free Pass', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setModalState(() => isFree = v),
                      ),
                    ),
                    if (!isFree)
                      Expanded(
                        child: AppTextField(
                          label: 'Price (₹ INR) *',
                          hint: '499',
                          keyboardType: TextInputType.number,
                          controller: priceCtrl,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(label: 'Quantity Limit (Optional)', hint: '100', keyboardType: TextInputType.number, controller: qtyCtrl),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  text: 'Create Ticket Tier',
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final priceVal = isFree ? 0.0 : (double.tryParse(priceCtrl.text.trim()) ?? 0);
                    final qtyVal = int.tryParse(qtyCtrl.text.trim());

                    try {
                      await ref.read(hostRepositoryProvider).createTicketTier(
                            event.id,
                            CreateTicketTierRequest(
                              name: nameCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              priceInPaise: (priceVal * 100).round(),
                              quantity: qtyVal,
                            ),
                          );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ref.invalidate(hostEventDetailProvider(event.id));
                        AppSnackbar.show(context, message: 'Ticket tier created successfully!', type: SnackbarType.success);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.show(context, message: 'Failed to create tier: ${e.toString()}', type: SnackbarType.error);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Tier', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
        onPressed: showAddTierModal,
      ),
      body: event.ticketTypes.isEmpty
          ? const AppEmptyView(
              icon: Icons.confirmation_number_outlined,
              title: 'No Ticket Tiers Configured',
              subtitle: 'Tap "Add Tier" below to add free or paid admission passes.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              itemCount: event.ticketTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tier = event.ticketTypes[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorder(context)),
                    boxShadow: AppColors.getCardShadow(context),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_activity_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            if (tier.description != null && tier.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                tier.description!,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.getTextSecondary(context)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              tier.isFree ? 'Free Pass' : CurrencyFormatter.formatPaise(tier.priceInPaise),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: tier.isFree ? const Color(0xFF10B981) : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.getCardAlt(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Sold: ${tier.soldCount}${tier.quantity != null ? '/${tier.quantity}' : ''}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                          ),
                          if (tier.soldCount == 0)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Ticket Tier?'),
                                    content: Text('Are you sure you want to remove "${tier.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(hostRepositoryProvider).deleteTicketTier(tier.id);
                                  ref.invalidate(hostEventDetailProvider(event.id));
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ── Tab 3: Attendee Approval Queue ────────────────────────────────────────────

class _AttendeeQueueTab extends HookConsumerWidget {
  final String eventId;

  const _AttendeeQueueTab({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(hostAttendeeQueueProvider(eventId));
    final filterStatus = useState<String>('ALL');

    return queueAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (e, _) => AppErrorView(
        message: e.toString(),
        onRetry: () => ref.refresh(hostAttendeeQueueProvider(eventId)),
      ),
      data: (registrations) {
        final filtered = filterStatus.value == 'ALL'
            ? registrations
            : registrations.where((r) => r.status.toUpperCase() == filterStatus.value).toList();

        final pendingCount = registrations.where((r) => r.isPending).length;

        return Column(
          children: [
            // Filter Pills
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.getSurface(context),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QueueFilterChip(
                      label: 'All (${registrations.length})',
                      isSelected: filterStatus.value == 'ALL',
                      onTap: () => filterStatus.value = 'ALL',
                    ),
                    _QueueFilterChip(
                      label: 'Pending Review ($pendingCount)',
                      isSelected: filterStatus.value == 'PENDING',
                      badgeColor: const Color(0xFFF59E0B),
                      onTap: () => filterStatus.value = 'PENDING',
                    ),
                    _QueueFilterChip(
                      label: 'Confirmed',
                      isSelected: filterStatus.value == 'CONFIRMED',
                      onTap: () => filterStatus.value = 'CONFIRMED',
                    ),
                    _QueueFilterChip(
                      label: 'Checked In',
                      isSelected: filterStatus.value == 'CHECKED_IN',
                      onTap: () => filterStatus.value = 'CHECKED_IN',
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? const AppEmptyView(
                      icon: Icons.people_outline_rounded,
                      title: 'No Registrations in Queue',
                      subtitle: 'Registered ticket attendees will appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reg = filtered[index];
                        return _RegistrationCard(
                          registration: reg,
                          onApprove: () async {
                            final success = await ref.read(hostAttendeeQueueProvider(eventId).notifier).approve(
                                  reg.id,
                                  hostMessage: 'Welcome! Your pass has been approved.',
                                );
                            if (success && context.mounted) {
                              AppSnackbar.show(context, message: 'Attendee approved & tickets issued!', type: SnackbarType.success);
                            }
                          },
                          onDecline: () async {
                            final success = await ref.read(hostAttendeeQueueProvider(eventId).notifier).decline(
                                  reg.id,
                                  hostMessage: 'Sorry, capacity for this session is full.',
                                );
                            if (success && context.mounted) {
                              AppSnackbar.show(context, message: 'Registration declined.', type: SnackbarType.info);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Tab 4: Entry Scanner Tab ──────────────────────────────────────────────────

class _ScannerTab extends HookConsumerWidget {
  final String eventId;
  final HostEventItem event;

  const _ScannerTab({required this.eventId, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrInputCtrl = useTextEditingController();
    final isScanning = useState(false);
    final isBulkAdmitting = useState(false);
    final scanResult = useState<CheckInResponse?>(null);
    final statsAsync = ref.watch(hostGateStatsProvider(eventId));

    Future<void> performCheckIn(String code) async {
      if (code.trim().isEmpty) return;
      isScanning.value = true;
      try {
        final res = await ref.read(hostRepositoryProvider).checkInAttendee(eventId, code.trim());
        scanResult.value = res;
        if (res.success) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
        ref.invalidate(hostEventDetailProvider(eventId));
        ref.invalidate(hostGateStatsProvider(eventId));
      } catch (e) {
        scanResult.value = CheckInResponse(
          success: false,
          isDuplicate: false,
          message: 'Invalid or unrecognized entry QR token: $e',
        );
        HapticFeedback.heavyImpact();
      } finally {
        isScanning.value = false;
      }
    }

    Future<void> handleBulkAdmit(String regId, int count) async {
      isBulkAdmitting.value = true;
      try {
        final res = await ref.read(hostRepositoryProvider).bulkCheckIn(
              eventId,
              registrationId: regId,
              count: count,
            );
        if (!context.mounted) return;
        AppSnackbar.show(
          context,
          message: res.message,
          type: res.success ? SnackbarType.success : SnackbarType.error,
        );

        if (scanResult.value != null && scanResult.value!.groupSummary != null) {
          final old = scanResult.value!;
          scanResult.value = CheckInResponse(
            success: true,
            isDuplicate: false,
            message: '✅ All ${old.groupSummary!.totalPassesBooked} Group Passes Checked In',
            checkedInAt: DateTime.now(),
            ticketId: old.ticketId,
            ticketNumber: old.ticketNumber,
            registrationId: old.registrationId,
            attendee: old.attendee,
            ticketType: old.ticketType,
            groupSummary: CheckInGroupSummary(
              totalPassesBooked: old.groupSummary!.totalPassesBooked,
              checkedInPasses: old.groupSummary!.totalPassesBooked,
              remainingPasses: 0,
            ),
          );
        }

        ref.invalidate(hostGateStatsProvider(eventId));
        ref.invalidate(hostEventDetailProvider(eventId));
      } catch (e) {
        if (!context.mounted) return;
        AppSnackbar.show(
          context,
          message: 'Bulk admit failed: $e',
          type: SnackbarType.error,
        );
      } finally {
        isBulkAdmitting.value = false;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Live Gate Stats
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) {
              if (stats == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.getBorder(context)),
                  boxShadow: AppColors.getCardShadow(context),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gate Admitted',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.getTextSecondary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stats.totalCheckedIn} / ${stats.totalTicketsSold}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${stats.checkInPercentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Viewfinder Container
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scanResult.value == null
                    ? AppColors.primary
                    : (scanResult.value!.success
                        ? const Color(0xFF10B981)
                        : (scanResult.value!.isDuplicate
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444))),
                width: 2.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 44),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to Scan Ticket Passes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Scan Result Alert Box
          if (scanResult.value != null) ...[
            _ScanResultAlert(
              result: scanResult.value!,
              isBulkLoading: isBulkAdmitting.value,
              onBulkAdmit: (regId, count) => handleBulkAdmit(regId, count),
            ),
            const SizedBox(height: 16),
          ],

          // Manual QR Token Entry
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.getBorder(context)),
              boxShadow: AppColors.getCardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Entry / Scanner Gun',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'QR Pass Token',
                  hint: 'e.g. EMSQR-FEF4F4-REG123-1-9A8B7C',
                  controller: qrInputCtrl,
                  prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                ),
                const SizedBox(height: 14),
                AppPrimaryButton(
                  text: isScanning.value ? 'Verifying...' : 'Verify & Check In Attendee',
                  isLoading: isScanning.value,
                  onPressed: isScanning.value ? null : () => performCheckIn(qrInputCtrl.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 5: Event Settings Tab ─────────────────────────────────────────────────

class _SettingsTab extends HookConsumerWidget {
  final HostEventItem event;

  const _SettingsTab({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleCtrl = useTextEditingController(text: event.title);
    final venueCtrl = useTextEditingController(text: event.venueName);
    final isSaving = useState(false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.getBorder(context)),
              boxShadow: AppColors.getCardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Event Settings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(label: 'Event Title', controller: titleCtrl),
                const SizedBox(height: 12),
                if (event.isOffline) AppTextField(label: 'Venue Name', controller: venueCtrl),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  text: isSaving.value ? 'Saving...' : 'Save Settings',
                  isLoading: isSaving.value,
                  onPressed: isSaving.value
                      ? null
                      : () async {
                          isSaving.value = true;
                          try {
                            await ref.read(hostedEventsProvider.notifier).updateEvent(
                              event.id,
                              {
                                'title': titleCtrl.text.trim(),
                                if (event.isOffline) 'venueName': venueCtrl.text.trim(),
                              },
                            );
                            if (context.mounted) {
                              AppSnackbar.show(context, message: 'Event settings updated!', type: SnackbarType.success);
                              ref.invalidate(hostEventDetailProvider(event.id));
                            }
                          } finally {
                            isSaving.value = false;
                          }
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Lifecycle & Actions
          if (event.isDraft)
            AppPrimaryButton(
              text: '🚀 Launch & Publish Event Now',
              backgroundColor: AppColors.primary,
              onPressed: () async {
                // 1. Proactive Quota Check
                final userSub = ref.read(userEventSubscriptionProvider).valueOrNull;
                if (userSub != null && userSub.usage.isLimitReached) {
                  await showQuotaLimitDialog(
                    context,
                    currentPlanName: userSub.subscription?.plan?.name ?? 'Basic Event Host',
                    maxAllowed: userSub.usage.maxActiveEvents ?? 5,
                  );
                  return;
                }

                try {
                  await ref.read(hostedEventsProvider.notifier).publishEvent(event.id);
                  if (context.mounted) {
                    AppSnackbar.show(context, message: 'Event published and live!', type: SnackbarType.success);
                    ref.invalidate(hostEventDetailProvider(event.id));
                    ref.read(userEventSubscriptionProvider.notifier).refresh();
                  }
                } catch (e) {
                  if (context.mounted) {
                    if (isSubscriptionQuotaError(e)) {
                      showQuotaLimitDialog(
                        context,
                        message: e.toString(),
                        currentPlanName: userSub?.subscription?.plan?.name ?? 'Basic Event Host',
                        maxAllowed: userSub?.usage.maxActiveEvents ?? 5,
                      );
                    } else {
                      AppSnackbar.show(context, message: 'Failed to publish event: ${e.toString().replaceAll('Exception: ', '').replaceAll('NetworkException: ', '')}', type: SnackbarType.error);
                    }
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

// ── Shared UI Sub-Widgets ─────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        bg = const Color(0xFF10B981);
        fg = Colors.white;
        label = 'PUBLISHED';
        break;
      case 'LIVE':
        bg = const Color(0xFF3B82F6);
        fg = Colors.white;
        label = 'LIVE NOW';
        break;
      case 'COMPLETED':
        bg = const Color(0xFF8B5CF6);
        fg = Colors.white;
        label = 'COMPLETED';
        break;
      case 'PENDING_APPROVAL':
        bg = const Color(0xFFF59E0B);
        fg = Colors.white;
        label = 'UNDER REVIEW';
        break;
      default:
        bg = Colors.grey.shade700;
        fg = Colors.white;
        label = 'DRAFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
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
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getCardAlt(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.getTextSecondary(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.getTextPrimary(context),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QueueFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _QueueFilterChip({
    required this.label,
    required this.isSelected,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getCardAlt(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : (badgeColor ?? AppColors.getTextPrimary(context)),
          ),
        ),
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final HostRegistration registration;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  const _RegistrationCard({
    required this.registration,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  registration.userName.isNotEmpty ? registration.userName[0].toUpperCase() : 'A',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      '${registration.ticketTypeName} • ${registration.quantity} Pass(es)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.getTextSecondary(context)),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: registration.status),
            ],
          ),
          if (registration.userEmail.isNotEmpty || registration.userPhone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${registration.userEmail} ${registration.userPhone.isNotEmpty ? '• ${registration.userPhone}' : ''}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.getTextSecondary(context)),
            ),
          ],
          if (registration.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onDecline,
                    child: Text('Decline', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onApprove,
                    child: Text('Approve Pass', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanResultAlert extends StatelessWidget {
  final CheckInResponse result;
  final bool isBulkLoading;
  final void Function(String registrationId, int count) onBulkAdmit;

  const _ScanResultAlert({
    required this.result,
    required this.isBulkLoading,
    required this.onBulkAdmit,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;
    String statusTitle;

    if (result.success) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.1);
      border = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
      statusTitle = '🟢 ENTRY VERIFIED & CHECKED IN';
    } else if (result.isDuplicate) {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
      border = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_rounded;
      statusTitle = '🔴 REJECT: DUPLICATE SCAN ATTEMPT!';
    } else {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.1);
      border = const Color(0xFFEF4444);
      icon = Icons.cancel_rounded;
      statusTitle = '🔴 INVALID ENTRY PASS';
    }

    final hasGroup = result.groupSummary != null && result.groupSummary!.totalPassesBooked > 1;
    final remainingCount = result.groupSummary?.remainingPasses ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: border, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: border,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          if (result.attendeeName != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  result.attendeeName!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                if (result.ticketTypeName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result.ticketTypeName!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Group Booking Summary
          if (hasGroup) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Booked: ${result.groupSummary!.totalPassesBooked}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Admitted: ${result.groupSummary!.checkedInPasses}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                  ),
                  Text(
                    'Remaining: ${result.groupSummary!.remainingPasses}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: remainingCount > 0 ? const Color(0xFF3B82F6) : AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 1-Tap Bulk Check-In Quick Action
          if (result.success && remainingCount > 0 && result.registrationId != null) ...[
            const SizedBox(height: 12),
            AppPrimaryButton(
              text: isBulkLoading
                  ? 'Admitting Group…'
                  : '⚡ Admit Remaining $remainingCount Passes',
              isLoading: isBulkLoading,
              onPressed: isBulkLoading
                  ? null
                  : () => onBulkAdmit(result.registrationId!, remainingCount),
            ),
          ],
        ],
      ),
    );
  }
}
