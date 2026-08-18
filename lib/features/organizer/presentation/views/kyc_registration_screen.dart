import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/organizer_providers.dart';

class KycRegistrationScreen extends HookConsumerWidget {
  const KycRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessNameController =
        useTextEditingController(text: 'Aurora Royal Planners');
    final panGstController =
        useTextEditingController(text: '27AABCU9603R1ZM');
    final bankAccountController =
        useTextEditingController(text: '5020004819281');
    final ifscController =
        useTextEditingController(text: 'HDFC0000128');
    final isSubmitting = useState(false);

    Future<void> handleSubmit() async {
      isSubmitting.value = true;
      await ref.read(organizerRepositoryProvider).submitKyc(
            businessName: businessNameController.text.trim(),
            panGst: panGstController.text.trim(),
            bankAccount: bankAccountController.text.trim(),
            ifsc: ifscController.text.trim(),
          );
      await ref
          .read(authStateProvider.notifier)
          .updateKycStatus(KycStatus.APPROVED);
      isSubmitting.value = false;

      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: 'Business KYC successfully verified & approved!',
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
          'Business KYC Verification',
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
              'Identity & Tax Details 🏛️',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'To enable instant advance payouts, verify your GST/PAN and bank payout routing details.',
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
                    label: 'Registered Business Name',
                    hint: 'e.g. Acme Event Management LLP',
                    controller: businessNameController,
                    prefixIcon: const Icon(Icons.business_rounded,
                        color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'GSTIN / PAN Number',
                    hint: '27AABCU9603R1ZM',
                    controller: panGstController,
                    prefixIcon: const Icon(Icons.badge_outlined,
                        color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Bank Account Number',
                    hint: '5020004819281',
                    controller: bankAccountController,
                    prefixIcon: const Icon(Icons.account_balance_rounded,
                        color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Bank IFSC Code',
                    hint: 'HDFC0000128',
                    controller: ifscController,
                    prefixIcon: const Icon(Icons.numbers_rounded,
                        color: AppColors.textMuted, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            AppPrimaryButton(
              text: isSubmitting.value ? 'Submitting…' : 'Verify & Enable Payouts',
              isLoading: isSubmitting.value,
              onPressed: isSubmitting.value ? null : handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
