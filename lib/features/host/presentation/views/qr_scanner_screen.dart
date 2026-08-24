import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/host_entities.dart';
import '../providers/host_providers.dart';

class QrScannerScreen extends HookConsumerWidget {
  final String eventId;

  const QrScannerScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrInputController = useTextEditingController();
    final lastResult = useState<CheckInResponse?>(null);
    final isScanning = useState(false);
    final isBulkAdmitting = useState(false);
    final statsAsync = ref.watch(hostGateStatsProvider(eventId));

    Future<void> handleScan(String qrCode) async {
      if (qrCode.trim().isEmpty) return;
      isScanning.value = true;
      try {
        final result = await ref
            .read(hostRepositoryProvider)
            .checkInAttendee(eventId, qrCode.trim());
        lastResult.value = result;

        // Trigger vibration/haptic feedback
        if (result.success) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.heavyImpact();
        }

        // Refresh live gate stats & event details
        ref.invalidate(hostGateStatsProvider(eventId));
        ref.invalidate(hostEventDetailProvider(eventId));
      } catch (e) {
        lastResult.value = CheckInResponse(
          success: false,
          isDuplicate: false,
          message: 'Error validating pass: $e',
        );
        HapticFeedback.heavyImpact();
      } finally {
        isScanning.value = false;
      }
    }

    Future<void> handleBulkGroupCheckIn(String registrationId, int remainingCount) async {
      isBulkAdmitting.value = true;
      try {
        final res = await ref.read(hostRepositoryProvider).bulkCheckIn(
              eventId,
              registrationId: registrationId,
              count: remainingCount,
            );
        if (!context.mounted) return;
        AppSnackbar.show(
          context,
          message: res.message,
          type: res.success ? SnackbarType.success : SnackbarType.error,
        );

        // Update result group status
        if (lastResult.value != null && lastResult.value!.groupSummary != null) {
          final old = lastResult.value!;
          lastResult.value = CheckInResponse(
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
        title: Text(
          'Gate Entry Scanner',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => ref.invalidate(hostGateStatsProvider(eventId)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Live Gate Statistics Card ─────────────────────────────────
            statsAsync.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: AppLoader()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) {
                if (stats == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
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
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE GATE METRICS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.getTextSecondary(context),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          if (stats.duplicateAttempts > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${stats.duplicateAttempts} Duplicates Blocked',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StatMiniBox(
                              label: 'Checked In',
                              value: '${stats.totalCheckedIn}',
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatMiniBox(
                              label: 'Remaining',
                              value: '${stats.remainingAttendees}',
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatMiniBox(
                              label: 'Total Sold',
                              value: '${stats.totalTicketsSold}',
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatMiniBox(
                              label: 'Gate %',
                              value: '${stats.checkInPercentage.toStringAsFixed(0)}%',
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Camera Viewfinder Container ───────────────────────────────
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: lastResult.value == null
                      ? AppColors.primary
                      : (lastResult.value!.success
                          ? const Color(0xFF10B981)
                          : (lastResult.value!.isDuplicate
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444))),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          color: Colors.white70, size: 52),
                      const SizedBox(height: 10),
                      Text(
                        'Align Pass QR Code Inside Frame',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Scan Result Verification Card ─────────────────────────────
            if (lastResult.value != null) ...[
              _EnhancedScanResultCard(
                result: lastResult.value!,
                isBulkLoading: isBulkAdmitting.value,
                onBulkCheckIn: (regId, count) =>
                    handleBulkGroupCheckIn(regId, count),
              ),
              const SizedBox(height: 20),
            ],

            // ── Manual Payload Entry / Scanner Gun ─────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: AppColors.getCardShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual Verification & Testing Gun',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scan via barcode gun or paste the unique pass payload token.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'QR Pass Payload Token',
                    hint: 'e.g. EMSQR-FEF4F4-REG123-1-9A8B7C',
                    controller: qrInputController,
                    prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    text: isScanning.value ? 'Validating Token…' : 'Simulate Scan Pass',
                    isLoading: isScanning.value,
                    onPressed: isScanning.value
                        ? null
                        : () => handleScan(qrInputController.text),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Recent Gate Check-Ins Stream ──────────────────────────────
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) {
                if (stats == null || stats.recentCheckIns.isEmpty) {
                  return const SizedBox.shrink();
                }
                final timeFormat = DateFormat('hh:mm:ss a');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Gate Admissions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.getBorder(context)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.recentCheckIns.length.clamp(0, 5),
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.getBorder(context),
                        ),
                        itemBuilder: (context, idx) {
                          final item = stats.recentCheckIns[idx];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                            ),
                            title: Text(
                              '${item.attendeeName} (Pass #${item.ticketNumber})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            subtitle: Text(
                              '${item.ticketType} • ${item.checkedInAt != null ? timeFormat.format(item.checkedInAt!) : 'Just now'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatMiniBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatMiniBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EnhancedScanResultCard extends StatelessWidget {
  final CheckInResponse result;
  final bool isBulkLoading;
  final void Function(String registrationId, int count) onBulkCheckIn;

  const _EnhancedScanResultCard({
    required this.result,
    required this.isBulkLoading,
    required this.onBulkCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;
    String statusHeading;

    if (result.success) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.08);
      border = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
      statusHeading = '🟢 ALLOW ENTRY: VERIFIED';
    } else if (result.isDuplicate) {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.08);
      border = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_rounded;
      statusHeading = '🔴 REJECT: DUPLICATE SCAN ATTEMPT!';
    } else {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.08);
      border = const Color(0xFFEF4444);
      icon = Icons.cancel_rounded;
      statusHeading = '🔴 INVALID OR UNRECOGNIZED QR CODE';
    }

    final hasGroup = result.groupSummary != null &&
        result.groupSummary!.totalPassesBooked > 1;
    final remainingCount = result.groupSummary?.remainingPasses ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: border, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusHeading,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: border,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
            ),
          ),

          // Attendee Details
          if (result.attendee != null || result.attendeeName != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendee Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.attendeeName ?? 'Attendee',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      if (result.attendeeEmail != null &&
                          result.attendeeEmail!.isNotEmpty)
                        Text(
                          result.attendeeEmail!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                    ],
                  ),
                ),
                if (result.ticketTypeName != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      result.ticketTypeName!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _GroupMetric(
                    label: 'Total Booked',
                    value: '${result.groupSummary!.totalPassesBooked}',
                  ),
                  _GroupMetric(
                    label: 'Checked In',
                    value: '${result.groupSummary!.checkedInPasses}',
                    color: const Color(0xFF10B981),
                  ),
                  _GroupMetric(
                    label: 'Remaining',
                    value: '${result.groupSummary!.remainingPasses}',
                    color: remainingCount > 0
                        ? const Color(0xFF3B82F6)
                        : AppColors.getTextSecondary(context),
                  ),
                ],
              ),
            ),
          ],

          // Bulk Check-in Quick Action
          if (result.success &&
              remainingCount > 0 &&
              result.registrationId != null) ...[
            const SizedBox(height: 14),
            AppPrimaryButton(
              text: isBulkLoading
                  ? 'Admitting Group…'
                  : '⚡ Admit All Remaining $remainingCount Passes',
              isLoading: isBulkLoading,
              onPressed: isBulkLoading
                  ? null
                  : () => onBulkCheckIn(result.registrationId!, remainingCount),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _GroupMetric({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color ?? AppColors.getTextPrimary(context),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.getTextSecondary(context),
          ),
        ),
      ],
    );
  }
}
