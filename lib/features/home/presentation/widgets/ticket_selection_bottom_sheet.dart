import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/razorpay_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../../../bookings/presentation/providers/booking_providers.dart';
import '../../../bookings/presentation/widgets/entry_qr_dialog.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';

class TicketSelectionBottomSheet extends HookConsumerWidget {
  final PublicEvent event;

  const TicketSelectionBottomSheet({
    super.key,
    required this.event,
  });

  static Future<void> show(BuildContext context, PublicEvent event) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TicketSelectionBottomSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableTiers = event.ticketTypes.isNotEmpty
        ? event.ticketTypes
        : [
            TicketType(
              id: 'gen_free',
              name: 'General Admission',
              description: 'Standard event access',
              priceInPaise: event.minPricePaise,
              quantity: 100,
            )
          ];

    final defaultTier = availableTiers.firstWhere(
      (t) => !t.isSoldOut,
      orElse: () => availableTiers.first,
    );

    final selectedTier = useState<TicketType>(defaultTier);
    final quantity = useState<int>(1);
    final attendeeNoteController = useTextEditingController();
    final isProcessing = useState<bool>(false);

    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final currentTier = selectedTier.value;
    final maxAllowedQty = currentTier.availableQuantity.clamp(1, 10);

    useOnAppLifecycleStateChange((previous, current) {
      if (current == AppLifecycleState.resumed && isProcessing.value) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (isProcessing.value) {
            isProcessing.value = false;
          }
        });
      }
    });

    // Calculate Fees & Taxes
    final subtotal = currentTier.priceInRupees * quantity.value;
    final gst = currentTier.isFree ? 0.0 : (subtotal * 0.18);
    final convenienceFee = currentTier.isFree ? 0.0 : (15.0 + (subtotal * 0.02) * 1.18);
    final totalPayable = currentTier.isFree ? 0.0 : (subtotal + gst + convenienceFee);

    Future<void> handleCheckout() async {
      if (isProcessing.value) return;

      if (currentUser == null) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Please sign in to register or book tickets.',
            type: SnackbarType.info,
          );
          context.push('/auth/login');
        }
        return;
      }

      isProcessing.value = true;

      try {
        final catalogRepo = ref.read(catalogRepositoryProvider);

        if (currentTier.isFree) {
          // ── Free Registration Flow ──────────────────────────────────────────
          final res = await catalogRepo.registerForEvent(
            eventId: event.id,
            ticketTypeId: currentTier.id,
            quantity: quantity.value,
            attendeeNote: attendeeNoteController.text.trim().isNotEmpty
                ? attendeeNoteController.text.trim()
                : null,
          );

          ref.invalidate(myTicketsProvider);
          ref.invalidate(eventDetailProvider(event.id));

          if (context.mounted) {
            Navigator.of(context).pop();

            AppSnackbar.show(
              context,
              message: '🎉 Pass confirmed! Added to My Tickets.',
              type: SnackbarType.success,
            );

            // Construct pass and show QR code immediately
            final pass = EventTicketPass.fromJson({
              'registrationId': res['registrationId'] ?? res['id'] ?? 'reg_${DateTime.now().millisecondsSinceEpoch}',
              'quantity': quantity.value,
              'status': 'CONFIRMED',
              'event': event.toJson(),
              'ticketType': currentTier.toJson(),
              'qrCodeData': res['qrCodeToken'] ?? 'EMS-PASS-${event.id}',
              'accessLink': res['accessLink'] ?? event.meetingUrl,
            });

            EntryQrDialog.show(context, pass);
          }
        } else {
          // ── Paid Razorpay Checkout Flow ─────────────────────────────────────
          final orderRes = await catalogRepo.createTicketOrder(
            eventId: event.id,
            ticketTypeId: currentTier.id,
            quantity: quantity.value,
            attendeeNote: attendeeNoteController.text.trim().isNotEmpty
                ? attendeeNoteController.text.trim()
                : null,
          );

          final razorpay = ref.read(razorpayServiceProvider);

          await razorpay.startEventTicketPaymentFlow(
            key: orderRes.key,
            gatewayOrderId: orderRes.gatewayOrderId,
            amountInPaise: orderRes.amountInPaise > 0
                ? orderRes.amountInPaise
                : (totalPayable * 100).toInt(),
            userEmail: currentUser.email,
            userPhone: currentUser.phone,
            userName: currentUser.name,
            eventTitle: event.title,
            onSuccess: (verifyData) async {
              isProcessing.value = false;
              ref.invalidate(myTicketsProvider);
              ref.invalidate(eventDetailProvider(event.id));

              if (context.mounted) {
                Navigator.of(context).pop();

                AppSnackbar.show(
                  context,
                  message: '🎟️ Payment successful! Pass issued.',
                  type: SnackbarType.success,
                );

                final pass = EventTicketPass.fromJson({
                  'registrationId': orderRes.registrationId,
                  'quantity': orderRes.quantity,
                  'totalAmountPaise': orderRes.amountInPaise,
                  'status': 'CONFIRMED',
                  'event': event.toJson(),
                  'ticketType': currentTier.toJson(),
                  'qrCodeData': 'EMSQR-${orderRes.registrationId}-1',
                  'accessLink': event.meetingUrl,
                });

                EntryQrDialog.show(context, pass);
              }
            },
            onError: (err, isCancelled) {
              isProcessing.value = false;
              if (!isCancelled && context.mounted) {
                AppSnackbar.show(
                  context,
                  message: 'Payment failed: $err',
                  type: SnackbarType.error,
                );
              }
            },
          );
        }
      } catch (e) {
        isProcessing.value = false;
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: e.toString().replaceAll('Exception: ', ''),
            type: SnackbarType.error,
          );
        }
      } finally {
        if (currentTier.isFree) {
          isProcessing.value = false;
        }
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Passes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.getTextMuted(context),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 20),

          // Main Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Select Tier
                  Text(
                    '1. Choose Pass Tier',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...availableTiers.map((tier) {
                    final isSelected = selectedTier.value.id == tier.id;
                    final isSoldOut = tier.isSoldOut || tier.availableQuantity <= 0;

                    return GestureDetector(
                      onTap: isSoldOut
                          ? null
                          : () {
                              selectedTier.value = tier;
                              if (quantity.value > tier.availableQuantity) {
                                quantity.value = tier.availableQuantity.clamp(1, 10);
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSoldOut
                              ? AppColors.getCardAlt(context).withValues(alpha: 0.5)
                              : (isSelected
                                  ? AppColors.primary.withValues(alpha: 0.06)
                                  : AppColors.getSurface(context)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.getBorder(context),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSoldOut
                                  ? AppColors.getTextMuted(context)
                                  : (isSelected
                                      ? AppColors.primary
                                      : AppColors.getTextMuted(context)),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        tier.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isSoldOut
                                              ? AppColors.getTextMuted(context)
                                              : AppColors.getTextPrimary(context),
                                        ),
                                      ),
                                      if (tier.remainingCount != null && tier.remainingCount! <= 10 && !isSoldOut) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${tier.remainingCount} left',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (tier.description != null)
                                    Text(
                                      tier.description!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              isSoldOut
                                  ? 'SOLD OUT'
                                  : (tier.isFree ? 'FREE' : CurrencyFormatter.formatPaise(tier.priceInPaise)),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isSoldOut
                                    ? AppColors.getTextMuted(context)
                                    : (tier.isFree ? const Color(0xFF10B981) : AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Step 2: Quantity Counter Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2. Quantity',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          Text(
                            'Max $maxAllowedQty per booking',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getCardAlt(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 18),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                              onPressed: quantity.value > 1
                                  ? () => quantity.value--
                                  : null,
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 32),
                              alignment: Alignment.center,
                              child: Text(
                                '${quantity.value}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                              onPressed: quantity.value < maxAllowedQty
                                  ? () => quantity.value++
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Step 3: Attendee Note (Optional)
                  Text(
                    '3. Special Requests / Note (Optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: attendeeNoteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add dietary preferences, questions, or notes for the host...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.getTextMuted(context),
                      ),
                      filled: true,
                      fillColor: AppColors.getCardAlt(context),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.getBorder(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.getBorder(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Step 4: Real-time Price & Tax Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.getCardAlt(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price Summary',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FeeRow(
                          label: '${currentTier.name} × ${quantity.value}',
                          amount: currentTier.isFree ? 'FREE' : '₹${subtotal.toStringAsFixed(2)}',
                        ),
                        if (!currentTier.isFree) ...[
                          const SizedBox(height: 6),
                          _FeeRow(
                            label: 'GST (18% on ticket)',
                            amount: '₹${gst.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 6),
                          _FeeRow(
                            label: 'Convenience Fee (inc GST)',
                            amount: '₹${convenienceFee.toStringAsFixed(2)}',
                          ),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Payable',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            Text(
                              currentTier.isFree ? '₹0.00 (FREE)' : '₹${totalPayable.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: currentTier.isFree ? const Color(0xFF10B981) : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              border: Border(top: BorderSide(color: AppColors.getBorder(context))),
            ),
            child: SafeArea(
              child: AppPrimaryButton(
                text: isProcessing.value
                    ? 'Processing...'
                    : (currentTier.isFree
                        ? 'Confirm Free Registration'
                        : 'Pay ₹${totalPayable.toStringAsFixed(2)} & Get Pass'),
                isLoading: isProcessing.value,
                onPressed: isProcessing.value ? null : handleCheckout,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String amount;

  const _FeeRow({
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.getTextSecondary(context),
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ],
    );
  }
}
