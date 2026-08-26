import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/razorpay_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/host_subscription_entities.dart';
import '../providers/host_providers.dart';

class EventHostingSubscriptionScreen extends HookConsumerWidget {
  const EventHostingSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingCycle = useState<String>('monthly'); // 'monthly' | 'annual'
    final isProcessing = useState<bool>(false);
    final selectedTier = useState<String?>(null);

    final plansAsync = ref.watch(eventSubscriptionPlansProvider);
    final userSubAsync = ref.watch(userEventSubscriptionProvider);
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    // Fallback plans if backend returns empty
    final fallbackPlans = [
      const EventSubscriptionPlan(
        id: 'e2a1b3c4-0001-4000-8000-000000000001',
        tier: 'BASIC',
        name: 'Basic Event Host',
        monthlyPriceInPaise: 0,
        annualPriceInPaise: 0,
        maxActiveEvents: 5,
        supportLevel: 'Standard Email Support',
        featureFlags: {'analytics': 'basic'},
      ),
      const EventSubscriptionPlan(
        id: 'e2a1b3c4-0002-4000-8000-000000000002',
        tier: 'MEDIUM',
        name: 'Pro Event Creator',
        monthlyPriceInPaise: 49900,
        annualPriceInPaise: 499000,
        maxActiveEvents: 20,
        supportLevel: 'Priority Chat & Email',
        featureFlags: {'customBranding': true, 'analytics': 'advanced'},
      ),
      const EventSubscriptionPlan(
        id: 'e2a1b3c4-0003-4000-8000-000000000003',
        tier: 'ADVANCED',
        name: 'Enterprise Host',
        monthlyPriceInPaise: 199900,
        annualPriceInPaise: 1999000,
        maxActiveEvents: null,
        supportLevel: 'Dedicated Manager',
        featureFlags: {'customBranding': true, 'analytics': 'pro'},
      ),
    ];

    Future<void> handleSelectPlan(EventSubscriptionPlan plan) async {
      if (isProcessing.value) return;
      isProcessing.value = true;
      selectedTier.value = plan.tier;

      try {
        final notifier = ref.read(userEventSubscriptionProvider.notifier);
        final selectRes = await notifier.selectPlan(
          tier: plan.tier,
          billingCycle: billingCycle.value,
        );

        if (!selectRes.requiresPayment) {
          // Free tier activated immediately
          if (context.mounted) {
            AppSnackbar.show(
              context,
              message: '🎉 ${plan.name} activated successfully!',
              type: SnackbarType.success,
            );
            ref.read(hostedEventsProvider.notifier).refresh();
          }
          isProcessing.value = false;
          return;
        }

        // Paid Plan — Initiate Razorpay Mobile SDK Checkout
        final paymentOrder = selectRes.paymentOrder;
        if (paymentOrder == null) {
          throw Exception('Payment order could not be generated.');
        }

        final razorpayService = ref.read(razorpayServiceProvider);

        await razorpayService.startEventTicketPaymentFlow(
          key: paymentOrder.key,
          gatewayOrderId: paymentOrder.gatewayOrderId,
          amountInPaise: paymentOrder.amountInPaise,
          userEmail: currentUser?.email,
          userPhone: currentUser?.phone,
          userName: currentUser?.name,
          eventTitle: 'Subscription: ${plan.name} (${billingCycle.value.toUpperCase()})',
          onSuccess: (data) async {
            if (context.mounted) {
              await ref.read(userEventSubscriptionProvider.notifier).refresh();
              await ref.read(hostedEventsProvider.notifier).refresh();

              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.getSurface(ctx),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981), size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Plan Activated!',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.getTextPrimary(ctx),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Congratulations! Your event hosting capacity is now upgraded to ${plan.name} (${plan.isUnlimited ? "Unlimited Events" : "Up to ${plan.maxActiveEvents} Events"}).',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.getTextSecondary(ctx),
                      height: 1.5,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        'Start Hosting',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            isProcessing.value = false;
          },
          onError: (errMsg, isCancelled) {
            if (context.mounted && !isCancelled) {
              AppSnackbar.show(
                context,
                message: 'Payment failed: $errMsg',
                type: SnackbarType.error,
              );
            }
            isProcessing.value = false;
          },
        );
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Failed to process subscription: $e',
            type: SnackbarType.error,
          );
        }
        isProcessing.value = false;
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
              color: AppColors.getTextPrimary(context), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Host Subscriptions & Plans',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              ref.refresh(eventSubscriptionPlansProvider);
              ref.read(userEventSubscriptionProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Current Active Plan & Quota Usage Banner ───────────────────
            userSubAsync.when(
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: AppLoader()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (userSub) {
                final currentTier = userSub?.subscription?.plan?.tier ??
                    (userSub?.hasSubscription == true ? 'BASIC' : 'BASIC');
                final currentPlanName = userSub?.subscription?.plan?.name ?? 'Free Host (Basic)';
                final activeEvents = userSub?.usage.activeEvents ?? 0;
                final maxEvents = userSub?.usage.maxActiveEvents;
                final isUnlimited = userSub?.usage.isUnlimited ?? false;
                final isLimitReached = userSub?.usage.isLimitReached ?? false;
                final usageRatio = userSub?.usage.usageRatio ?? 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLimitReached
                          ? [const Color(0xFFEF4444).withValues(alpha: 0.12), AppColors.getSurface(context)]
                          : [AppColors.primary.withValues(alpha: 0.12), AppColors.getSurface(context)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLimitReached
                          ? Colors.redAccent.withValues(alpha: 0.4)
                          : AppColors.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: AppColors.getCardShadow(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active Subscription',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.getTextSecondary(context),
                                        ),
                                      ),
                                      Text(
                                        currentPlanName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.getTextPrimary(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLimitReached
                                  ? Colors.redAccent.withValues(alpha: 0.15)
                                  : const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isLimitReached ? 'LIMIT REACHED' : (currentTier),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isLimitReached ? Colors.redAccent : const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Usage Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Active Hosting Quota',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getTextPrimary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isUnlimited
                                ? '$activeEvents (Unlimited)'
                                : '$activeEvents / $maxEvents Events',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isLimitReached ? Colors.redAccent : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: isUnlimited ? 0.2 : usageRatio,
                          minHeight: 8,
                          backgroundColor: AppColors.getBorder(context),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isLimitReached ? Colors.redAccent : AppColors.primary,
                          ),
                        ),
                      ),
                      if (userSub?.subscription?.currentPeriodEnd != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Renews on ${DateFormat('MMM dd, yyyy').format(userSub!.subscription!.currentPeriodEnd!)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            // ── Section Title ─────────────────────────────────────────────
            Text(
              'Select Hosting Tier',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upgrade capacity to host more active public & private events.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 16),

            // ── Monthly / Annual Billing Toggle ───────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => billingCycle.value = 'monthly',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: billingCycle.value == 'monthly'
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Monthly Billing',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: billingCycle.value == 'monthly'
                                  ? Colors.white
                                  : AppColors.getTextSecondary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => billingCycle.value = 'annual',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: billingCycle.value == 'annual'
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Annual Billing',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: billingCycle.value == 'annual'
                                      ? Colors.white
                                      : AppColors.getTextSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: billingCycle.value == 'annual'
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SAVE 17%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: billingCycle.value == 'annual'
                                      ? Colors.white
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Plans List Cards ──────────────────────────────────────────
            plansAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: AppLoader(),
                ),
              ),
              error: (_, __) => _renderPlansList(
                context,
                fallbackPlans,
                userSubAsync.valueOrNull,
                billingCycle.value,
                isProcessing.value,
                selectedTier.value,
                handleSelectPlan,
              ),
              data: (plans) {
                final effectivePlans = plans.isNotEmpty ? plans : fallbackPlans;
                return _renderPlansList(
                  context,
                  effectivePlans,
                  userSubAsync.valueOrNull,
                  billingCycle.value,
                  isProcessing.value,
                  selectedTier.value,
                  handleSelectPlan,
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Feature Matrix Table ──────────────────────────────────────
            _FeatureMatrixCard(),
          ],
        ),
      ),
    );
  }

  Widget _renderPlansList(
    BuildContext context,
    List<EventSubscriptionPlan> plans,
    UserEventSubscriptionResponse? userSub,
    String cycle,
    bool isProcessing,
    String? selectedTier,
    Function(EventSubscriptionPlan) onSelect,
  ) {
    final currentTier = userSub?.subscription?.plan?.tier ?? 'BASIC';

    return Column(
      children: plans.map((plan) {
        final isCurrent = plan.tier.toUpperCase() == currentTier.toUpperCase();
        final isPro = plan.tier.toUpperCase() == 'MEDIUM';
        final isEnterprise = plan.tier.toUpperCase() == 'ADVANCED';
        final price = cycle == 'monthly'
            ? plan.monthlyPriceInRupees
            : plan.annualPriceInRupees;
        final perMonthFormatted = cycle == 'monthly' ? '/month' : '/year';

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isPro
                  ? AppColors.primary
                  : (isCurrent
                      ? const Color(0xFF10B981)
                      : AppColors.getBorder(context)),
              width: isPro ? 2 : (isCurrent ? 1.5 : 1),
            ),
            boxShadow: isPro
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ]
                : AppColors.getCardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Banner
              if (isPro)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '⭐ RECOMMENDED FOR CREATORS',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan.isUnlimited
                                  ? 'Unlimited Active Events'
                                  : 'Up to ${plan.maxActiveEvents} Active Events',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPro ? AppColors.primary : AppColors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              plan.isFree ? 'FREE' : '₹$price',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            if (!plan.isFree)
                              Text(
                                perMonthFormatted,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 28),

                    // Feature highlights
                    _PlanFeatureRow(
                      icon: Icons.event_available_rounded,
                      text: plan.isUnlimited
                          ? 'Unlimited concurrent events'
                          : 'Max ${plan.maxActiveEvents} active hosted events',
                      isHighlight: isPro || isEnterprise,
                    ),
                    const SizedBox(height: 8),
                    _PlanFeatureRow(
                      icon: Icons.support_agent_rounded,
                      text: plan.supportLevel,
                      isHighlight: false,
                    ),
                    const SizedBox(height: 8),
                    _PlanFeatureRow(
                      icon: Icons.qr_code_scanner_rounded,
                      text: 'High-speed Gate QR Entry Scanner',
                      isHighlight: false,
                    ),
                    if (isPro || isEnterprise) ...[
                      const SizedBox(height: 8),
                      _PlanFeatureRow(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Custom Branding & Advanced Analytics',
                        isHighlight: true,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: isCurrent
                          ? OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF10B981)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Current Active Plan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            )
                          : AppPrimaryButton(
                              text: plan.isFree ? 'Activate Free Plan' : 'Select ${plan.name}',
                              isLoading: isProcessing && selectedTier == plan.tier,
                              onPressed: isProcessing ? null : () => onSelect(plan),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PlanFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isHighlight;

  const _PlanFeatureRow({
    required this.icon,
    required this.text,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlight ? AppColors.primary : const Color(0xFF10B981),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight
                  ? AppColors.getTextPrimary(context)
                  : AppColors.getTextSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureMatrixCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: AppColors.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tier Feature Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 14),
          _MatrixRow(label: 'Max Active Events', basic: '5', medium: '20', advanced: 'Unlimited'),
          _MatrixRow(label: 'Gate Scanner', basic: 'Yes', medium: 'Yes', advanced: 'Yes'),
          _MatrixRow(label: 'Custom Branding', basic: '—', medium: 'Yes', advanced: 'Yes'),
          _MatrixRow(label: 'Analytics', basic: 'Basic', medium: 'Advanced', advanced: 'Pro Real-time'),
          _MatrixRow(label: 'Support Tier', basic: 'Email', medium: 'Chat & Email', advanced: 'Dedicated Manager', isLast: true),
        ],
      ),
    );
  }
}

class _MatrixRow extends StatelessWidget {
  final String label;
  final String basic;
  final String medium;
  final String advanced;
  final bool isLast;

  const _MatrixRow({
    required this.label,
    required this.basic,
    required this.medium,
    required this.advanced,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  basic,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  medium,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  advanced,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: AppColors.getBorder(context), height: 1),
      ],
    );
  }
}
