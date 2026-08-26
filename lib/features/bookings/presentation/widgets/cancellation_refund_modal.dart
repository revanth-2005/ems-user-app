import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/booking_entities.dart';
import '../providers/booking_providers.dart';

/// BookMyShow-style Interactive Cancellation & Instant Refund Modal Dialog
class CancellationRefundModal extends HookConsumerWidget {
  final String targetId;
  final RefundTargetType targetType;
  final String fallbackTitle;
  final int fallbackPaidPaise;
  final DateTime? fallbackDate;

  const CancellationRefundModal({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.fallbackTitle,
    required this.fallbackPaidPaise,
    this.fallbackDate,
  });

  static Future<void> show({
    required BuildContext context,
    required String targetId,
    required RefundTargetType targetType,
    required String fallbackTitle,
    required int fallbackPaidPaise,
    DateTime? fallbackDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancellationRefundModal(
        targetId: targetId,
        targetType: targetType,
        fallbackTitle: fallbackTitle,
        fallbackPaidPaise: fallbackPaidPaise,
        fallbackDate: fallbackDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedReason = useState<String>(
      targetType == RefundTargetType.REGISTRATION
          ? 'Personal scheduling conflict'
          : 'Event venue / date relocated',
    );
    final customNotesController = useTextEditingController();
    final isCancelling = useState<bool>(false);
    final cancellationResult = useState<CancellationResult?>(null);

    final isDark = AppColors.isDark(context);

    // Fetch live refund quote
    final quoteAsync = targetType == RefundTargetType.REGISTRATION
        ? ref.watch(registrationRefundQuoteProvider(targetId))
        : ref.watch(bookingRefundQuoteProvider(targetId));

    final availableReasons = targetType == RefundTargetType.REGISTRATION
        ? [
            'Personal scheduling conflict',
            'Booked by mistake',
            'Travel / Transport issue',
            'Event date / time changed',
            'Other reason',
          ]
        : [
            'Event venue / date relocated',
            'Vendor service no longer required',
            'Budget / Plan changes',
            'Found alternative arrangement',
            'Other reason',
          ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: cancellationResult.value != null
              ? _buildSuccessView(
                  context,
                  cancellationResult.value!,
                )
              : quoteAsync.when(
                  loading: () => _buildLoadingState(context),
                  error: (err, _) => _buildFallbackState(
                    context: context,
                    ref: ref,
                    selectedReason: selectedReason,
                    customNotesController: customNotesController,
                    isCancelling: isCancelling,
                    cancellationResult: cancellationResult,
                    availableReasons: availableReasons,
                    isDark: isDark,
                  ),
                  data: (quote) => _buildQuoteDetailsState(
                    context: context,
                    ref: ref,
                    quote: quote,
                    selectedReason: selectedReason,
                    customNotesController: customNotesController,
                    isCancelling: isCancelling,
                    cancellationResult: cancellationResult,
                    availableReasons: availableReasons,
                    isDark: isDark,
                  ),
                ),
        ),
      ),
    );
  }

  // ── 1. Loading State ────────────────────────────────────────────────────────

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),
          const SizedBox(height: 30),
          const AppLoader(message: 'Calculating instant refund quote...'),
          const SizedBox(height: 12),
          Text(
            'Analyzing policy rules & remaining time window...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Active Quote State ───────────────────────────────────────────────────

  Widget _buildQuoteDetailsState({
    required BuildContext context,
    required WidgetRef ref,
    required RefundQuote quote,
    required ValueNotifier<String> selectedReason,
    required TextEditingController customNotesController,
    required ValueNotifier<bool> isCancelling,
    required ValueNotifier<CancellationResult?> cancellationResult,
    required List<String> availableReasons,
    required bool isDark,
  }) {
    final hasRefund = quote.refundAmountInPaise > 0;
    final isFullRefund = quote.eligibleRefundPct >= 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(context),
        const SizedBox(height: 14),

        // Header Title + Policy Badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetType == RefundTargetType.REGISTRATION
                        ? 'Cancel Event Pass'
                        : 'Cancel Vendor Booking',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    quote.itemName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isFullRefund
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : (hasRefund
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                        : const Color(0xFFEF4444).withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFullRefund
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : (hasRefund
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                          : const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
              ),
              child: Text(
                '${quote.eligibleRefundPct}% REFUND',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isFullRefund
                      ? const Color(0xFF10B981)
                      : (hasRefund
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Time Remaining Banner
        if (quote.hoursRemaining != null || quote.daysRemaining != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(
                  quote.hoursRemaining != null
                      ? '${quote.hoursRemaining!.toStringAsFixed(1)} hours until event start'
                      : '${quote.daysRemaining} days remaining before service date',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Financial Breakdown Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181A20) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getBorder(context),
            ),
          ),
          child: Column(
            children: [
              _buildPriceRow(
                context,
                label: 'Original Amount Paid',
                amountPaise: quote.totalPaidInPaise,
                isPrimary: false,
              ),
              const SizedBox(height: 10),
              _buildPriceRow(
                context,
                label: 'Cancellation Deduction (${100 - quote.eligibleRefundPct}%)',
                amountPaise: quote.cancellationFeeInPaise,
                isDeduction: true,
                isPrimary: false,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _buildPriceRow(
                context,
                label: 'Estimated Refund Amount',
                amountPaise: quote.refundAmountInPaise,
                isHighlight: true,
                isPrimary: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Policy Rule Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated Refund Policy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quote.policyDescription,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cancellation Reason
        Text(
          'Reason for Cancellation',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1E24) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getBorder(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedReason.value,
              isExpanded: true,
              dropdownColor: AppColors.getSurface(context),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: availableReasons
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedReason.value = val;
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                text: 'Keep Pass',
                onPressed: isCancelling.value ? null : () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppPrimaryButton(
                text: 'Confirm Cancel',
                isLoading: isCancelling.value,
                backgroundColor: const Color(0xFFEF4444),
                onPressed: () => _executeCancellation(
                  context: context,
                  ref: ref,
                  isCancelling: isCancelling,
                  cancellationResult: cancellationResult,
                  reason: selectedReason.value,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 3. Fallback Quote State (when offline or cached) ────────────────────────

  Widget _buildFallbackState({
    required BuildContext context,
    required WidgetRef ref,
    required ValueNotifier<String> selectedReason,
    required TextEditingController customNotesController,
    required ValueNotifier<bool> isCancelling,
    required ValueNotifier<CancellationResult?> cancellationResult,
    required List<String> availableReasons,
    required bool isDark,
  }) {
    return _buildQuoteDetailsState(
      context: context,
      ref: ref,
      quote: RefundQuote(
        targetId: targetId,
        targetType: targetType,
        itemName: fallbackTitle,
        targetDate: fallbackDate,
        totalPaidInPaise: fallbackPaidPaise,
        eligibleRefundPct: 100,
        refundAmountInPaise: fallbackPaidPaise,
        cancellationFeeInPaise: 0,
        policyDescription: 'Standard automated refund policy applies.',
      ),
      selectedReason: selectedReason,
      customNotesController: customNotesController,
      isCancelling: isCancelling,
      cancellationResult: cancellationResult,
      availableReasons: availableReasons,
      isDark: isDark,
    );
  }

  // ── 4. Success State View ───────────────────────────────────────────────────

  Widget _buildSuccessView(BuildContext context, CancellationResult result) {
    final hasRefund = result.refundAmountInPaise > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildDragHandle(context),
          const SizedBox(height: 24),

          // Green check animation circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                size: 38,
                color: Color(0xFF10B981),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Cancellation Confirmed',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            result.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.getTextSecondary(context),
              height: 1.4,
            ),
          ),

          if (hasRefund) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Refund Processed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(result.refundAmountInPaise),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  if (result.razorpayRefundId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Razorpay Refund ID',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                        Text(
                          result.razorpayRefundId!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              text: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Execution Logic ─────────────────────────────────────────────────

  Future<void> _executeCancellation({
    required BuildContext context,
    required WidgetRef ref,
    required ValueNotifier<bool> isCancelling,
    required ValueNotifier<CancellationResult?> cancellationResult,
    required String reason,
  }) async {
    isCancelling.value = true;
    try {
      if (targetType == RefundTargetType.REGISTRATION) {
        final res = await ref
            .read(myTicketsProvider.notifier)
            .cancelRegistration(targetId, reason: reason);
        cancellationResult.value = res;
      } else {
        final res = await ref
            .read(myBookingsProvider.notifier)
            .cancelBookingWithRefund(targetId, reason: reason);
        cancellationResult.value = res;
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: 'Cancellation failed: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      isCancelling.value = false;
    }
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────────

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context, {
    required String label,
    required int amountPaise,
    bool isDeduction = false,
    bool isHighlight = false,
    bool isPrimary = false,
  }) {
    final prefix = isDeduction ? '- ' : '';
    final color = isHighlight
        ? const Color(0xFF10B981)
        : (isDeduction
            ? const Color(0xFFEF4444)
            : AppColors.getTextPrimary(context));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isPrimary ? 14 : 12.5,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
            color: isPrimary
                ? AppColors.getTextPrimary(context)
                : AppColors.getTextSecondary(context),
          ),
        ),
        Text(
          '$prefix${CurrencyFormatter.formatPaise(amountPaise)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isPrimary ? 16 : 13,
            fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
