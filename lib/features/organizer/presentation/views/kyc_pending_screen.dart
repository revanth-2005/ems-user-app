import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/organizer_providers.dart';

class KycPendingScreen extends HookConsumerWidget {
  const KycPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(organizerProfileProvider);

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
          'KYC Verification Status',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profile) {
          final submittedDateStr = profile.submittedAt != null
              ? DateFormatter.formatDate(profile.submittedAt!)
              : 'Recently';
          final refNumber = profile.trackingReference ?? 'EMS-KYC-84920';

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(organizerProfileProvider.notifier).refreshProfile();
              if (context.mounted) {
                AppSnackbar.show(
                  context,
                  message: 'KYC status refreshed.',
                  type: SnackbarType.info,
                );
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Status Banner Card ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.amber.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.hourglass_top_rounded,
                            color: Colors.amber.shade900, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Application Under Review ⏳',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your business documents & payout bank routing are currently being verified by the TrueGather Admin team.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.amber.shade900.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 16, color: Colors.amber.shade800),
                            const SizedBox(width: 6),
                            Text(
                              'Expected Turnaround: 24–48 Hours',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Application Reference Bar ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking Reference',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            refNumber,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Submitted On',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            submittedDateStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Read-only Submission Details ───────────────────────────
                Text(
                  'Submitted Business Profile',
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
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(context, 'Business Name', profile.businessName),
                      const Divider(height: 18),
                      _buildDetailRow(context, 'Location', profile.city),
                      const Divider(height: 18),
                      _buildDetailRow(
                          context, 'Contact Phone', profile.contactPhone),
                      const Divider(height: 18),
                      _buildDetailRow(
                          context, 'Contact Email', profile.contactEmail),
                      const Divider(height: 18),
                      _buildDetailRow(
                        context,
                        'Categories',
                        profile.categories.isEmpty
                            ? 'Event Services'
                            : profile.categories.join(', '),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Payout & Tax Verification',
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
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                          context, 'PAN / GSTIN', profile.panGst ?? '27AABCU9603R1ZM'),
                      const Divider(height: 18),
                      _buildDetailRow(context, 'Account Holder',
                          profile.bankAccountHolder ?? profile.businessName),
                      const Divider(height: 18),
                      _buildDetailRow(context, 'Bank Account',
                          '•••• •••• ${profile.bankAccount?.substring((profile.bankAccount?.length ?? 4) - 4) ?? '4812'}'),
                      const Divider(height: 18),
                      _buildDetailRow(context, 'IFSC Code', profile.bankIfsc ?? 'HDFC0000128'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Demo Simulator Shortcut Button ─────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.smart_toy_outlined,
                              color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Demo / Testing Fast-Track',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Simulate instant admin approval to proceed to the Onboarding Setup Wizard.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Simulate Approval'),
                              onPressed: () async {
                                await ref
                                    .read(organizerProfileProvider.notifier)
                                    .setKycStatusForTesting(KycStatus.approved);
                                if (context.mounted) {
                                  context.pushReplacement(AppRoutes.organizerSetupWizard);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade800,
                                side: BorderSide(color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Simulate Reject'),
                              onPressed: () async {
                                await ref
                                    .read(organizerProfileProvider.notifier)
                                    .setKycStatusForTesting(
                                      KycStatus.rejected,
                                      reason:
                                          'PAN card image was blurry / GST certificate mismatch with registered name.',
                                    );
                                if (context.mounted) {
                                  context.pushReplacement(AppRoutes.organizerKycResubmit);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.getTextSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ),
      ],
    );
  }
}
