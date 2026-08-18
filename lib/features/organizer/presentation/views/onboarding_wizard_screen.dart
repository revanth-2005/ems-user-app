import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/organizer_entities.dart';

class OnboardingWizardScreen extends HookConsumerWidget {
  const OnboardingWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlan = useState(SubscriptionPlan.PRO);

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
          'Organizer Subscription Plan',
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
              'Scale Your Event Business 📈',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a business tier to unlock verified listings, SLA escrow protection, and analytics.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            _PlanCard(
              title: 'Starter / Free Trial',
              price: '₹0 / month',
              features: const [
                'Up to 2 active listings',
                'Basic client inquiry messaging',
                'Standard 48-hour payout cycle',
              ],
              isSelected: selectedPlan.value == SubscriptionPlan.FREE_TRIAL,
              onTap: () => selectedPlan.value = SubscriptionPlan.FREE_TRIAL,
            ),
            const SizedBox(height: 14),

            _PlanCard(
              title: 'Professional Tier',
              price: '₹2,499 / month',
              isPopular: true,
              features: const [
                'Unlimited packages & services',
                'Verified Vendor Blue Checkmark',
                'Instant advance escrow release',
                'Priority ranking on home search',
              ],
              isSelected: selectedPlan.value == SubscriptionPlan.PRO,
              onTap: () => selectedPlan.value = SubscriptionPlan.PRO,
            ),
            const SizedBox(height: 14),

            _PlanCard(
              title: 'Enterprise Agency',
              price: '₹6,999 / month',
              features: const [
                'Multi-team staff manager accounts',
                'Custom corporate contract invoicing',
                'Dedicated 24/7 account manager',
              ],
              isSelected: selectedPlan.value == SubscriptionPlan.ENTERPRISE,
              onTap: () => selectedPlan.value = SubscriptionPlan.ENTERPRISE,
            ),

            const SizedBox(height: 32),

            AppPrimaryButton(
              text: 'Confirm & Activate Plan',
              onPressed: () {
                AppSnackbar.show(
                  context,
                  message: 'Subscription plan updated successfully!',
                  type: SnackbarType.success,
                );
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isSelected;
  final bool isPopular;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.features,
    required this.isSelected,
    this.isPopular = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppColors.cardShadow,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'POPULAR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.statusCompleted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
