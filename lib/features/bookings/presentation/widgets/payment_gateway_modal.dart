import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/razorpay_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/booking_providers.dart';

/// Shows the interactive Payment Gateway Modal for completing pre-booking deposit payments.
Future<void> showPaymentGatewayModal({
  required BuildContext context,
  required WidgetRef ref,
  required int depositAmountPaise,
  required int totalAmountPaise,
  String? couponCode,
  String? notes,
}) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalCtx) {
      return _PaymentGatewayBottomSheet(
        depositAmountPaise: depositAmountPaise,
        totalAmountPaise: totalAmountPaise,
        couponCode: couponCode,
        notes: notes,
      );
    },
  );
}

class _PaymentGatewayBottomSheet extends HookConsumerWidget {
  final int depositAmountPaise;
  final int totalAmountPaise;
  final String? couponCode;
  final String? notes;

  const _PaymentGatewayBottomSheet({
    required this.depositAmountPaise,
    required this.totalAmountPaise,
    this.couponCode,
    this.notes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMethod = ValueNotifier<String>('UPI');
    final isLoading = ValueNotifier<bool>(false);
    final user = ref.watch(authStateProvider).valueOrNull;
    final razorpayService = ref.watch(razorpayServiceProvider);

    Future<void> handlePayNow() async {
      isLoading.value = true;
      final repo = ref.read(bookingRepositoryProvider);
      final cartState = ref.read(cartProvider);

      try {
        // 0. Sync local cart items to server so /checkout has something to process
        for (final item in cartState.items) {
          try {
            await repo.addToCartRemote(
              packageId: item.packageId,
              serviceId: item.serviceId,
              eventDate: item.eventDate.toIso8601String().substring(0, 10),
              quantity: item.quantity,
            );
          } catch (_) {
            // Ignore if item already in cart
          }
        }

        // 1. Process Checkout to generate orderId
        String? orderId;
        int requiredDeposit = depositAmountPaise;

        try {
          final checkoutRes = await repo.processCheckout(
            couponCode: couponCode,
            notes: notes,
          );
          orderId = checkoutRes['orderId'] as String? ?? checkoutRes['id'] as String?;
          if (checkoutRes['depositAmountPaise'] is int) {
            requiredDeposit = checkoutRes['depositAmountPaise'] as int;
          }
        } catch (e) {
          // If checkout failed, throw descriptive error
          throw Exception('Failed to create booking order: $e');
        }

        // 2. Launch Native Razorpay Payment Flow
        await razorpayService.startPaymentFlow(
          amountInPaise: requiredDeposit,
          paymentType: 'DEPOSIT',
          orderId: orderId,
          userEmail: user?.email,
          userPhone: user?.phone,
          userName: user?.name,
          description: 'EMS Pre-Booking Deposit',
          onSuccess: (verifyData) {
            isLoading.value = false;
            ref.read(cartProvider.notifier).clearCart();
            if (context.mounted) {
              Navigator.pop(context); // Close payment modal
              final paymentObj = verifyData['payment'] as Map<String, dynamic>?;
              final paymentId = (paymentObj?['gatewayPaymentId'] ?? paymentObj?['id'] ?? 'pay_rzp_success').toString();
              _showPaymentSuccessDialog(
                context,
                paymentId: paymentId,
                amountPaise: requiredDeposit,
              );
            }
          },
          onError: (errorMsg, isCancelled) {
            isLoading.value = false;
            if (context.mounted) {
              if (isCancelled) {
                AppSnackbar.show(
                  context,
                  message: 'Payment cancelled.',
                  type: SnackbarType.info,
                );
              } else {
                AppSnackbar.show(
                  context,
                  message: errorMsg,
                  type: SnackbarType.error,
                );
              }
            }
          },
        );
      } catch (e) {
        isLoading.value = false;
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Failed to initiate payment: $e',
            type: SnackbarType.error,
          );
        }
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (context, loading, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Pre-Booking Payment',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Powered by Razorpay Escrow',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentEmerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🔒 Escrow Safe',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentEmerald,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightCardAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pre-Booking Deposit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatPaise(depositAmountPaise),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Order Value',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(totalAmountPaise),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Select Payment Option',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              ValueListenableBuilder<String>(
                valueListenable: selectedMethod,
                builder: (context, method, _) {
                  return Column(
                    children: [
                      _PaymentOptionTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'UPI (GPay / PhonePe / Paytm)',
                        subtitle: 'Instant pre-booking deposit via UPI apps',
                        isSelected: method == 'UPI',
                        onTap: () => selectedMethod.value = 'UPI',
                      ),
                      const SizedBox(height: 8),
                      _PaymentOptionTile(
                        icon: Icons.credit_card_rounded,
                        title: 'Credit / Debit Cards',
                        subtitle: 'Visa, Mastercard, RuPay & Corporate Cards',
                        isSelected: method == 'CARD',
                        onTap: () => selectedMethod.value = 'CARD',
                      ),
                      const SizedBox(height: 8),
                      _PaymentOptionTile(
                        icon: Icons.account_balance_rounded,
                        title: 'Net Banking',
                        subtitle: 'All major Indian retail & corporate banks',
                        isSelected: method == 'NETBANKING',
                        onTap: () => selectedMethod.value = 'NETBANKING',
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              AppPrimaryButton(
                text: loading
                    ? 'Securing Payment…'
                    : 'Pay ${CurrencyFormatter.formatPaise(depositAmountPaise)} Now',
                isLoading: loading,
                onPressed: loading ? null : handlePayNow,
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.lightCardAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
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
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              activeColor: AppColors.primary,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}

void _showPaymentSuccessDialog(
  BuildContext context, {
  required String paymentId,
  required int amountPaise,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.lightSurface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accentEmerald,
                  size: 56,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pre-Booking Confirmed!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your deposit of ${CurrencyFormatter.formatPaise(amountPaise)} was captured under EMS Escrow Protection.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightCardAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment ID:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            paymentId.length > 18 ? '${paymentId.substring(0, 18)}…' : paymentId,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SLA Guarantee:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '24h Vendor Confirmation',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentEmerald),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              AppPrimaryButton(
                text: 'View My Bookings',
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  context.go(AppRoutes.bookings);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
