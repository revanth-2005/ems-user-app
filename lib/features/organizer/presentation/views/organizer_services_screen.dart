import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/datasources/organizer_local_datasource.dart';
import '../../domain/entities/organizer_entities.dart';
import '../providers/organizer_providers.dart';

class OrganizerServicesScreen extends HookConsumerWidget {
  const OrganizerServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0); // 0: All, 1: Active, 2: Paused
    final servicesAsync = ref.watch(organizerServicesProvider);
    final profileAsync = ref.watch(organizerProfileProvider);
    final profile = profileAsync.valueOrNull;

    final maxCap = profile?.maxActiveServices ?? 20;

    void showPlanLimitBottomSheet(int currentActive) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_clock_rounded,
                    color: Colors.teal.shade800, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Active Service Quota Reached',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your current ${profile?.plan.label ?? 'Plan'} permits $maxCap active standalone service listings ($currentActive/$maxCap active). Deactivate another service or upgrade your subscription plan to publish more.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.getTextSecondary(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                text: 'Upgrade Subscription Plan 💎',
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.organizerSubscription);
                },
              ),
              const SizedBox(height: 10),
              AppSecondaryButton(
                text: 'Close',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    }

    void showCreateServiceSheet([OrganizerService? initial]) {
      final isEditing = initial != null;
      final nameCtrl = TextEditingController(text: initial?.name ?? '');
      final categoryCtrl =
          TextEditingController(text: initial?.category ?? 'DJ & Sound');
      final descCtrl = TextEditingController(
          text: initial?.description ??
              'High quality standalone event service with professional equipment.');
      final priceCtrl = TextEditingController(
          text: initial != null ? '${initial.priceInPaise ~/ 100}' : '35000');
      final depositPctCtrl = TextEditingController(
          text: initial != null ? '${initial.advanceDepositPct}' : '25');
      final leadTimeCtrl = TextEditingController(
          text: initial != null ? '${initial.leadTimeDays}' : '3');
      var unit = initial?.pricingUnit ?? ServicePricingUnit.FIXED;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Service' : 'Create Standalone Service',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        AppTextField(
                          label: 'Service Title *',
                          hint: 'e.g. Club & Bollywood DJ 4-Hour Live Set',
                          controller: nameCtrl,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Category *',
                          hint: 'e.g. DJ & Sound, Photography, Catering',
                          controller: categoryCtrl,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Service Description',
                          hint: 'Equipment details, duration, requirements…',
                          controller: descCtrl,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // ── Pricing Unit Selector ──────────────────────────
                        Text(
                          'Pricing Unit *',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ServicePricingUnit.values.map((u) {
                            final isSel = unit == u;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(() => unit = u),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? AppColors.primary
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      u.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isSel
                                            ? Colors.white
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Price (₹) *',
                                hint: '35000',
                                controller: priceCtrl,
                                prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppTextField(
                                label: 'Advance Deposit %',
                                hint: '20',
                                controller: depositPctCtrl,
                                prefixIcon: const Icon(Icons.percent, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Lead Time Requirement (Days) *',
                          hint: 'Must be booked at least 3 days in advance',
                          controller: leadTimeCtrl,
                          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  AppPrimaryButton(
                    text: isEditing ? 'Save Changes' : 'Publish Service Listing',
                    onPressed: () {
                      final priceInt =
                          (int.tryParse(priceCtrl.text) ?? 35000) * 100;
                      final newSrv = OrganizerService(
                        id: initial?.id ??
                            'srv_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim().isNotEmpty
                            ? nameCtrl.text.trim()
                            : 'New Standalone Service',
                        category: categoryCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        priceInPaise: priceInt,
                        pricingUnit: unit,
                        advanceDepositPct:
                            int.tryParse(depositPctCtrl.text) ?? 20,
                        leadTimeDays: int.tryParse(leadTimeCtrl.text) ?? 3,
                        coverImageUrl: initial?.coverImageUrl ??
                            'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&auto=format&fit=crop',
                        isActive: initial?.isActive ?? true,
                      );

                      if (isEditing) {
                        ref
                            .read(organizerServicesProvider.notifier)
                            .updateService(newSrv);
                      } else {
                        ref
                            .read(organizerServicesProvider.notifier)
                            .createService(newSrv);
                      }
                      Navigator.pop(sheetCtx);
                      AppSnackbar.show(
                        context,
                        message: isEditing
                            ? 'Service updated successfully.'
                            : 'Standalone service published!',
                        type: SnackbarType.success,
                      );
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
          'Standalone Services',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            onPressed: () => showCreateServiceSheet(),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => AppErrorView(message: e.toString()),
        data: (services) {
          final activeCount = services.where((s) => s.isActive).length;

          final filtered = services.where((s) {
            if (selectedTab.value == 1) return s.isActive;
            if (selectedTab.value == 2) return !s.isActive;
            return true;
          }).toList();

          return Column(
            children: [
              // ── Active Cap Quota Gauge Banner ────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.design_services_outlined,
                          color: Colors.teal, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Active Services Quota',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              Text(
                                '$activeCount / $maxCap Active',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: activeCount >= maxCap
                                      ? Colors.orange.shade800
                                      : Colors.teal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: maxCap > 0
                                  ? (activeCount / maxCap).clamp(0.0, 1.0)
                                  : 0.0,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              color: activeCount >= maxCap
                                  ? Colors.orange
                                  : Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Segmented Tabs ───────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabItem('All (${services.length})', 0, selectedTab),
                    _buildTabItem('Active ($activeCount)', 1, selectedTab),
                    _buildTabItem(
                        'Paused (${services.length - activeCount})',
                        2,
                        selectedTab),
                  ],
                ),
              ),

              // ── Services List ────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No services found in this view.',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final srv = filtered[index];
                          return _buildServiceCard(
                            context: context,
                            srv: srv,
                            onToggle: () async {
                              try {
                                await ref
                                    .read(organizerServicesProvider.notifier)
                                    .toggleServiceStatus(srv.id);
                                if (context.mounted) {
                                  AppSnackbar.show(
                                    context,
                                    message: srv.isActive
                                        ? 'Service listing paused'
                                        : 'Service listing activated and live!',
                                    type: SnackbarType.info,
                                  );
                                }
                              } on QuotaExceededException {
                                showPlanLimitBottomSheet(activeCount);
                              }
                            },
                            onTap: () => showCreateServiceSheet(srv),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem(
      String label, int index, ValueNotifier<int> selectedTab) {
    final isSelected = selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => selectedTab.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4)
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.teal.shade900 : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required OrganizerService srv,
    required VoidCallback onToggle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Row(
          children: [
            AppNetworkImage(
              url: srv.coverImageUrl,
              width: 64,
              height: 64,
              borderRadius: 14,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: srv.isActive
                              ? Colors.teal.shade50
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          srv.isActive ? 'ACTIVE' : 'PAUSED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: srv.isActive
                                ? Colors.teal.shade800
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            srv.pricingUnit.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    srv.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyFormatter.formatPaise(srv.priceInPaise)} ${srv.pricingUnit.suffix} • ${srv.leadTimeDays}d lead time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: srv.isActive,
              activeColor: Colors.teal,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}
