import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/organizer_entities.dart';
import '../providers/organizer_providers.dart';

class OnboardingWizardScreen extends HookConsumerWidget {
  const OnboardingWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = useState(1);
    final selectedMode = useState<OperationalMode>(OperationalMode.BOTH);
    final selectedTier = useState<SubscriptionTier>(SubscriptionTier.MEDIUM);
    final isSaving = useState(false);

    Future<void> handleComplete() async {
      isSaving.value = true;
      try {
        await ref
            .read(organizerProfileProvider.notifier)
            .setOperationalMode(selectedMode.value);
        await ref
            .read(organizerProfileProvider.notifier)
            .selectSubscriptionTier(selectedTier.value);

        if (context.mounted) {
          AppSnackbar.show(
            context,
            message:
                'Welcome to Organizer Hub! Setup complete on ${selectedTier.value.label}.',
            type: SnackbarType.success,
          );
          context.go(AppRoutes.organizerHub);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Failed to complete setup: $e',
            type: SnackbarType.error,
          );
        }
      } finally {
        isSaving.value = false;
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
          onPressed: () {
            if (currentStep.value > 1) {
              currentStep.value--;
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          'Organizer Onboarding Setup',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Progress Stepper Bar ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            color: AppColors.getSurface(context),
            child: Row(
              children: [
                _buildStepPill(1, 'Business Mode', currentStep.value >= 1),
                Expanded(
                  child: Container(
                    height: 2,
                    color: currentStep.value > 1
                        ? AppColors.primary
                        : AppColors.getBorder(context),
                  ),
                ),
                _buildStepPill(2, 'Subscription Plan', currentStep.value >= 2),
              ],
            ),
          ),

          // ── Step Content ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: currentStep.value == 1
                  ? _buildStep1ModeSelector(context, selectedMode)
                  : _buildStep2PlanSelector(context, selectedTier),
            ),
          ),

          // ── Bottom Navigation Bar ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              border: Border(top: BorderSide(color: AppColors.getBorder(context))),
            ),
            child: Row(
              children: [
                if (currentStep.value > 1) ...[
                  Expanded(
                    flex: 1,
                    child: AppSecondaryButton(
                      text: 'Back',
                      onPressed: () => currentStep.value = 1,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  flex: 2,
                  child: AppPrimaryButton(
                    text: currentStep.value == 1
                        ? 'Next: Select Plan →'
                        : isSaving.value
                            ? 'Activating Workspace…'
                            : 'Complete Setup & Launch Hub 🚀',
                    isLoading: isSaving.value,
                    onPressed: () {
                      if (currentStep.value == 1) {
                        currentStep.value = 2;
                      } else {
                        handleComplete();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill(int step, String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1ModeSelector(
      BuildContext context, ValueNotifier<OperationalMode> selectedMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Operational Mode 🎯',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select how you intend to take bookings. You can change this later in settings.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.getTextSecondary(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        _buildModeCard(
          context: context,
          mode: OperationalMode.SINGLE_SERVICE,
          icon: Icons.music_note_rounded,
          iconColor: Colors.purple,
          title: 'Individual Service Provider',
          subtitle: 'Offers standalone hourly or per-head services (DJ, Solo Photographer, Anchor, Emcee, Makeup Artist).',
          isSelected: selectedMode.value == OperationalMode.SINGLE_SERVICE,
          onTap: () => selectedMode.value = OperationalMode.SINGLE_SERVICE,
        ),
        const SizedBox(height: 14),

        _buildModeCard(
          context: context,
          mode: OperationalMode.MULTI_SERVICE,
          icon: Icons.celebration_rounded,
          iconColor: Colors.amber.shade800,
          title: 'Event Organizer / Planner',
          subtitle: 'Curates & executes bundled multi-service packages (Full Wedding Planners, Corporate Staging & Banquet).',
          isSelected: selectedMode.value == OperationalMode.MULTI_SERVICE,
          onTap: () => selectedMode.value = OperationalMode.MULTI_SERVICE,
        ),
        const SizedBox(height: 14),

        _buildModeCard(
          context: context,
          mode: OperationalMode.BOTH,
          icon: Icons.all_inclusive_rounded,
          iconColor: AppColors.primary,
          badge: 'RECOMMENDED',
          title: 'Hybrid (Both Standalone & Packages)',
          subtitle: 'Maximum flexibility: offer standalone talent/equipment hires AND bundled end-to-end event packages.',
          isSelected: selectedMode.value == OperationalMode.BOTH,
          onTap: () => selectedMode.value = OperationalMode.BOTH,
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required OperationalMode mode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.getBorder(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2PlanSelector(
      BuildContext context, ValueNotifier<SubscriptionTier> selectedTier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Subscription Tier 💎',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'All plans include 0% platform commission and direct bank payouts. Tiers dictate active listing quotas.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.getTextSecondary(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        _buildPlanCard(
          context: context,
          tier: SubscriptionTier.BASIC,
          title: 'Basic Starter',
          price: '₹999 / mo',
          packagesQuota: '3 Active Packages',
          servicesQuota: '5 Active Services',
          features: const [
            'Instant advance payout release',
            'In-app client booking chats',
            'Basic availability calendar',
          ],
          isSelected: selectedTier.value == SubscriptionTier.BASIC,
          onTap: () => selectedTier.value = SubscriptionTier.BASIC,
        ),
        const SizedBox(height: 14),

        _buildPlanCard(
          context: context,
          tier: SubscriptionTier.MEDIUM,
          title: 'Medium Professional',
          price: '₹2,499 / mo',
          isPopular: true,
          packagesQuota: '10 Active Packages',
          servicesQuota: '20 Active Services',
          features: const [
            'Verified Organizer Blue Badge',
            'Priority search placement',
            'Automated 24h SLA booking engine',
            'Full portfolio photo & video gallery',
          ],
          isSelected: selectedTier.value == SubscriptionTier.MEDIUM,
          onTap: () => selectedTier.value = SubscriptionTier.MEDIUM,
        ),
        const SizedBox(height: 14),

        _buildPlanCard(
          context: context,
          tier: SubscriptionTier.ADVANCED,
          title: 'Advanced Agency',
          price: '₹4,999 / mo',
          packagesQuota: 'Unlimited Packages',
          servicesQuota: 'Unlimited Services',
          features: const [
            'Unlimited active listings',
            'Multi-city regional coverage',
            'Dedicated 24/7 account manager',
            'Custom branding & contract invoicing',
          ],
          isSelected: selectedTier.value == SubscriptionTier.ADVANCED,
          onTap: () => selectedTier.value = SubscriptionTier.ADVANCED,
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required SubscriptionTier tier,
    required String title,
    required String price,
    required String packagesQuota,
    required String servicesQuota,
    required List<String> features,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPopular = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.getBorder(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppColors.getCardShadow(context),
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
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'MOST POPULAR',
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
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Quotas row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '📦 $packagesQuota',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Text(
                    '🛠️ $servicesQuota',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal.shade900,
                    ),
                  ),
                ),
              ],
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
                          color: AppColors.getTextSecondary(context),
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
