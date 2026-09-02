import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/organizer_providers.dart';

class OrganizerSuspendedScreen extends HookConsumerWidget {
  const OrganizerSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(organizerProfileProvider);
    final profile = profileAsync.valueOrNull;

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
          'Account Suspended',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.gavel_rounded,
                  color: Colors.red.shade700, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Organizer Hub Access Suspended',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.red.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile?.rejectionReason ??
                  'Your organizer account has been temporarily suspended due to repeated SLA expiration or compliance review requirements.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.getTextSecondary(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            AppPrimaryButton(
              text: 'Contact EMS Help & Dispute Support',
              onPressed: () {
                AppSnackbar.show(
                  context,
                  message:
                      'Support ticket opened (#TKT-9921). An EMS agent will contact you within 4 hours.',
                  type: SnackbarType.info,
                );
              },
            ),
            const SizedBox(height: 14),
            AppSecondaryButton(
              text: 'Return to User Profile',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
