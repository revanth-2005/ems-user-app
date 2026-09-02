import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/organizer_providers.dart';

class PayoutLedgerScreen extends HookConsumerWidget {
  const PayoutLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(payoutLedgerProvider);
    final profileAsync = ref.watch(organizerProfileProvider);
    final profile = profileAsync.valueOrNull;

    void showUpdateBankSheet() {
      final holderC = TextEditingController(
          text: profile?.bankAccountHolder ?? 'Aura Event Studios LLP');
      final accC = TextEditingController(text: profile?.bankAccount ?? '5020004819281');
      final ifscC = TextEditingController(text: profile?.bankIfsc ?? 'HDFC0000128');

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Update Payout Bank Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
              TextField(
                controller: holderC,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accC,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ifscC,
                decoration: const InputDecoration(
                  labelText: 'Bank IFSC Code',
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                text: 'Save & Verify Bank Account',
                onPressed: () {
                  Navigator.pop(ctx);
                  AppSnackbar.show(
                    context,
                    message:
                        'Payout bank account updated. Micro-penny verification initiated.',
                    type: SnackbarType.success,
                  );
                },
              ),
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
          'Earnings & Bank Payouts',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: ledgerAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => AppErrorView(message: e.toString()),
        data: (ledger) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(payoutLedgerProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Zero Commission Guarantee Banner ───────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '0% Platform Commission Guarantee',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You receive 100% of your listed service price minus only standard payment gateway processing fees.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Balance & Payout Card ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.getBorder(context)),
                      boxShadow: AppColors.getCardShadow(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Available for Payout',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatPaise(
                              ledger.availableBalancePaise),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gross Booking Revenue',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.getTextMuted(context),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatPaise(
                                        ledger.totalEarningsPaise),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending in Escrow',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.getTextMuted(context),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatPaise(
                                        ledger.pendingPayoutPaise),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accentAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AppPrimaryButton(
                          text: 'Request Instant Bank Withdrawal',
                          onPressed: () {
                            AppSnackbar.show(
                              context,
                              message:
                                  'Withdrawal of ${CurrencyFormatter.formatPaise(ledger.availableBalancePaise)} queued to HDFC bank account.',
                              type: SnackbarType.success,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Registered Bank Account Preview ────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
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
                                const Icon(Icons.account_balance_rounded,
                                    color: Colors.indigo, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Linked Bank Account',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: showUpdateBankSheet,
                              child: const Text('Update'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile?.bankAccountHolder ?? 'Aura Event Studios LLP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Account: •••• •••• ${profile?.bankAccount?.substring((profile.bankAccount?.length ?? 4) - 4) ?? '4812'} • IFSC: ${profile?.bankIfsc ?? 'HDFC0000128'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Payout Transaction Ledger ──────────────────────────────
                  Text(
                    'Settlement History & Razorpay Transfers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...ledger.transactions.map((tx) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.getBorder(context)),
                        boxShadow: AppColors.getCardShadow(context),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tx.isCredit
                                  ? AppColors.statusCompleted
                                      .withValues(alpha: 0.12)
                                  : Colors.indigo.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              tx.isCredit
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: tx.isCredit
                                  ? AppColors.statusCompleted
                                  : Colors.indigo,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      DateFormatter.formatDate(tx.date),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color:
                                            AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                    if (tx.transferId != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '• ${tx.transferId}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${tx.isCredit ? "+" : "-"} ${CurrencyFormatter.formatPaise(tx.amountPaise)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: tx.isCredit
                                  ? AppColors.statusCompleted
                                  : Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
