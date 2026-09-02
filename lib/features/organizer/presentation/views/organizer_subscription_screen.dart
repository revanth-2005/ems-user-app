import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/organizer_entities.dart';
import '../providers/organizer_providers.dart';

class OrganizerSubscriptionScreen extends HookConsumerWidget {
  const OrganizerSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(organizerProfileProvider);
    final packagesAsync = ref.watch(organizerPackagesProvider);
    final servicesAsync = ref.watch(organizerServicesProvider);

    final selectedPlan = useState(SubscriptionTier.MEDIUM);

    void showPlanSelectorModal(SubscriptionTier currentTier) {
      selectedPlan.value = currentTier;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change Subscription Tier 💎',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
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
                  Expanded(
                    child: ListView(
                      children: SubscriptionTier.values.map((tier) {
                        final isSel = selectedPlan.value == tier;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedPlan.value = tier),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.primary.withValues(alpha: 0.05)
                                  : AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.getBorder(context),
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tier.label,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      tier.priceLabel,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• ${tier.maxActivePackages == 999 ? "Unlimited" : tier.maxActivePackages} Active Packages Quota\n• ${tier.maxActiveServices == 999 ? "Unlimited" : tier.maxActiveServices} Active Services Quota\n• 0% Platform Commission Guarantee',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.getTextSecondary(context),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  AppPrimaryButton(
                    text: 'Confirm & Checkout with Razorpay',
                    onPressed: () async {
                      await ref
                          .read(organizerProfileProvider.notifier)
                          .selectSubscriptionTier(selectedPlan.value);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        AppSnackbar.show(
                          context,
                          message:
                              'Subscription upgraded to ${selectedPlan.value.label}!',
                          type: SnackbarType.success,
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
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
          'Subscription & Listing Quotas',
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
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          final packages = packagesAsync.valueOrNull ?? [];
          final services = servicesAsync.valueOrNull ?? [];
          final activePackages = packages.where((p) => p.isActive).length;
          final activeServices = services.where((s) => s.isActive).length;

          final maxPackages = profile.maxActivePackages;
          final maxServices = profile.maxActiveServices;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Active Plan Card ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              'CURRENT PLAN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            profile.plan.priceLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        profile.plan.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '0% Platform Commission • Priority Search Placement',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => showPlanSelectorModal(profile.plan),
                        child: const Text('Upgrade Plan 💎'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Quotas Live Gauges ─────────────────────────────────────
                Text(
                  'Live Active Listing Quotas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),

                _buildQuotaCard(
                  context: context,
                  title: 'Active Packages Quota',
                  current: activePackages,
                  limit: maxPackages,
                  icon: Icons.inventory_2_outlined,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 12),

                _buildQuotaCard(
                  context: context,
                  title: 'Active Standalone Services Quota',
                  current: activeServices,
                  limit: maxServices,
                  icon: Icons.design_services_outlined,
                  color: Colors.teal,
                ),
                const SizedBox(height: 28),

                // ── Tier Comparison ────────────────────────────────────────
                Text(
                  'Available Subscription Tiers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),

                ...SubscriptionTier.values.map((tier) {
                  final isCurrent = profile.plan == tier;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.getBorder(context),
                        width: isCurrent ? 2 : 1,
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
                              tier.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            else
                              Text(
                                tier.priceLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• ${tier.maxActivePackages == 999 ? "Unlimited" : tier.maxActivePackages} Packages • ${tier.maxActiveServices == 999 ? "Unlimited" : tier.maxActiveServices} Services Cap',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuotaCard({
    required BuildContext context,
    required String title,
    required int current,
    required int limit,
    required IconData icon,
    required Color color,
  }) {
    final ratio = limit > 0 ? (current / limit).clamp(0.0, 1.0) : 0.0;
    final isMax = current >= limit;

    return Container(
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
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$current / $limit Active',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isMax ? Colors.orange.shade800 : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: isMax ? Colors.orange : color,
            ),
          ),
        ],
      ),
    );
  }
}
