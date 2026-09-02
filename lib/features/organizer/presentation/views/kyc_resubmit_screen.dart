import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/organizer_providers.dart';

class KycResubmitScreen extends HookConsumerWidget {
  const KycResubmitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(organizerProfileProvider);
    final profile = profileAsync.valueOrNull;

    final businessNameController =
        useTextEditingController(text: profile?.businessName ?? 'Aura Event Studios');
    final panGstController =
        useTextEditingController(text: profile?.panGst ?? '27AABCU9603R1ZM');
    final accountHolderController = useTextEditingController(
        text: profile?.bankAccountHolder ?? 'Aura Event Studios LLP');
    final accountNumberController =
        useTextEditingController(text: profile?.bankAccount ?? '5020004819281');
    final ifscController =
        useTextEditingController(text: profile?.bankIfsc ?? 'HDFC0000128');

    final panReplaced = useState(false);
    final isSubmitting = useState(false);

    final rejectionReason = profile?.rejectionReason ??
        'PAN card photo was blurry / unable to verify name match with GST certificate.';

    Future<void> handleResubmit() async {
      isSubmitting.value = true;
      try {
        await ref.read(organizerProfileProvider.notifier).resubmitKyc(
              businessName: businessNameController.text.trim(),
              panGst: panGstController.text.trim(),
              bankAccount: accountNumberController.text.trim(),
              ifsc: ifscController.text.trim(),
              accountHolder: accountHolderController.text.trim(),
            );

        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Updated KYC documents resubmitted successfully!',
            type: SnackbarType.success,
          );
          context.pushReplacement(AppRoutes.organizerKycPending);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Resubmission failed: $e',
            type: SnackbarType.error,
          );
        }
      } finally {
        isSubmitting.value = false;
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
              color: AppColors.getTextPrimary(context), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'KYC Action Required',
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
            // ── Rejection Notice Banner ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.red.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.warning_amber_rounded,
                            color: Colors.red.shade800, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KYC Verification Needs Correction',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.red.shade900,
                              ),
                            ),
                            Text(
                              'Admin Verification Notes',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      '“$rejectionReason”',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please replace the flagged document below with a clear scan or high-resolution photo and resubmit.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.red.shade800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Replace Document Slot ──────────────────────────────────────
            Text(
              'Replace Flagged Document 📎',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: panReplaced.value
                      ? Colors.green.shade400
                      : AppColors.accentAmber,
                  width: 1.5,
                ),
                boxShadow: AppColors.getCardShadow(context),
              ),
              child: Row(
                children: [
                  Icon(
                    panReplaced.value
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    color: panReplaced.value
                        ? Colors.green.shade700
                        : AppColors.accentAmber,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business PAN Card Photo / Scan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          panReplaced.value
                              ? 'pan_card_clear_scanned_2026.pdf (Ready)'
                              : 'Tap to pick high-resolution clear scan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: panReplaced.value
                                ? Colors.green.shade700
                                : AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: panReplaced.value
                          ? Colors.green.shade600
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      panReplaced.value = true;
                      AppSnackbar.show(
                        context,
                        message: 'New clear PAN scan attached.',
                        type: SnackbarType.success,
                      );
                    },
                    child: Text(panReplaced.value ? 'Replaced ✓' : 'Replace Scan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Pre-populated Form Details ─────────────────────────────────
            Text(
              'Confirm Business & Bank Details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: AppColors.getCardShadow(context),
              ),
              child: Column(
                children: [
                  AppTextField(
                    label: 'Registered Business Name',
                    controller: businessNameController,
                    prefixIcon: Icon(Icons.business_rounded,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'PAN Number / GSTIN',
                    controller: panGstController,
                    prefixIcon: Icon(Icons.badge_outlined,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Account Holder Name',
                    controller: accountHolderController,
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Bank Account Number',
                    controller: accountNumberController,
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Bank IFSC Code',
                    controller: ifscController,
                    prefixIcon: Icon(Icons.numbers_rounded,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Resubmit Button ─────────────────────────────────────────────
            AppPrimaryButton(
              text: isSubmitting.value ? 'Resubmitting…' : 'Resubmit KYC Application →',
              isLoading: isSubmitting.value,
              onPressed: isSubmitting.value ? null : handleResubmit,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
