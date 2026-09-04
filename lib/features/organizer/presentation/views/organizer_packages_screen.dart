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

class OrganizerPackagesScreen extends HookConsumerWidget {
  const OrganizerPackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0); // 0: All, 1: Active, 2: Drafts
    final packagesAsync = ref.watch(organizerPackagesProvider);
    final profileAsync = ref.watch(organizerProfileProvider);
    final profile = profileAsync.valueOrNull;

    final maxCap = profile?.maxActivePackages ?? 10;

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
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_clock_rounded,
                    color: Colors.orange.shade800, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Active Package Limit Reached',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your current ${profile?.plan.label ?? 'Plan'} permits $maxCap active package listings ($currentActive/$maxCap currently active). Deactivate another package or upgrade your subscription plan to publish more.',
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

    void showCreatePackageSheet([OrganizerPackage? initial]) {
      final isEditing = initial != null;
      final nameCtrl = TextEditingController(text: initial?.name ?? '');
      final categoryCtrl =
          TextEditingController(text: initial?.category ?? 'Wedding Planners');
      final subcategoryCtrl =
          TextEditingController(text: initial?.subcategory ?? 'Full Wedding Setup');
      final descCtrl = TextEditingController(
          text: initial?.description ??
              'Comprehensive event package featuring stage decor, catering and entertainment.');
      final priceCtrl = TextEditingController(
          text: initial != null ? '${initial.priceInPaise ~/ 100}' : '150000');
      final depositPctCtrl = TextEditingController(
          text: initial != null ? '${initial.advanceDepositPct}' : '20');
      final minGuestsCtrl = TextEditingController(
          text: initial != null ? '${initial.minGuests}' : '50');
      final maxGuestsCtrl = TextEditingController(
          text: initial != null ? '${initial.maxGuests}' : '300');

      final lineItems = List<PackageLineItem>.from(initial?.lineItems ?? [
        const PackageLineItem(
            id: 'li_1',
            title: 'Designer Stage & Entry Arch Decor',
            description: 'Thematic floral setup'),
        const PackageLineItem(
            id: 'li_2',
            title: 'Royal Multi-Cuisine Feast (150 PAX)',
            quantity: '150 PAX'),
      ]);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
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
                        isEditing ? 'Edit Package' : 'Create New Package',
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
                          label: 'Package Title *',
                          hint: 'e.g. Royal Heritage Wedding Extravaganza',
                          controller: nameCtrl,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Primary Category',
                                hint: 'e.g. Wedding Planners',
                                controller: categoryCtrl,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppTextField(
                                label: 'Subcategory',
                                hint: 'e.g. Luxury',
                                controller: subcategoryCtrl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Package Description',
                          hint: 'Inclusions and highlights…',
                          controller: descCtrl,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Base Price (₹) *',
                                hint: '150000',
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
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Min Guests',
                                hint: '50',
                                controller: minGuestsCtrl,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppTextField(
                                label: 'Max Guests',
                                hint: '300',
                                controller: maxGuestsCtrl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Line Items Builder ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Package Line Items (${lineItems.length})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Item'),
                              onPressed: () {
                                final titleC = TextEditingController();
                                final qtyC = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (dCtx) => AlertDialog(
                                    title: const Text('Add Line Item'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: titleC,
                                          decoration: const InputDecoration(
                                            labelText: 'Item Name (e.g. DJ 4 Hours)',
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          controller: qtyC,
                                          decoration: const InputDecoration(
                                            labelText: 'Quantity / PAX (Optional)',
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dCtx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (titleC.text.trim().isNotEmpty) {
                                            setSheetState(() {
                                              lineItems.add(
                                                PackageLineItem(
                                                  id: 'li_${DateTime.now().millisecondsSinceEpoch}',
                                                  title: titleC.text.trim(),
                                                  quantity: qtyC.text.trim().isNotEmpty
                                                      ? qtyC.text.trim()
                                                      : null,
                                                ),
                                              );
                                            });
                                            Navigator.pop(dCtx);
                                          }
                                        },
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ...lineItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.getBorder(context)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 18, color: Colors.green),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (item.quantity != null)
                                        Text(
                                          'Quantity: ${item.quantity}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  onPressed: () {
                                    setSheetState(() {
                                      lineItems.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  AppPrimaryButton(
                    text: isEditing ? 'Save Changes' : 'Publish Package',
                    onPressed: () {
                      final priceInt =
                          (int.tryParse(priceCtrl.text) ?? 150000) * 100;
                      final newPkg = OrganizerPackage(
                        id: initial?.id ??
                            'pkg_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim().isNotEmpty
                            ? nameCtrl.text.trim()
                            : 'New Event Package',
                        category: categoryCtrl.text.trim(),
                        subcategory: subcategoryCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        priceInPaise: priceInt,
                        advanceDepositPct:
                            int.tryParse(depositPctCtrl.text) ?? 20,
                        minGuests: int.tryParse(minGuestsCtrl.text) ?? 50,
                        maxGuests: int.tryParse(maxGuestsCtrl.text) ?? 300,
                        coverImageUrl: initial?.coverImageUrl ??
                            'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop',
                        isActive: initial?.isActive ?? true,
                        lineItems: lineItems,
                      );

                      if (isEditing) {
                        ref
                            .read(organizerPackagesProvider.notifier)
                            .updatePackage(newPkg);
                      } else {
                        ref
                            .read(organizerPackagesProvider.notifier)
                            .createPackage(newPkg);
                      }
                      Navigator.pop(sheetCtx);
                      AppSnackbar.show(
                        context,
                        message: isEditing
                            ? 'Package updated successfully.'
                            : 'Package created and listed!',
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
          'Packages Management',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            onPressed: () => showCreatePackageSheet(),
          ),
        ],
      ),
      body: packagesAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => AppErrorView(message: e.toString()),
        data: (packages) {
          final activeCount = packages.where((p) => p.isActive).length;

          final filtered = packages.where((p) {
            if (selectedTab.value == 1) return p.isActive;
            if (selectedTab.value == 2) return !p.isActive;
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.primary, size: 22),
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
                                'Active Package Quota',
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
                                      : AppColors.primary,
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
                                  : AppColors.primary,
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
                    _buildTabItem('All (${packages.length})', 0, selectedTab),
                    _buildTabItem('Active ($activeCount)', 1, selectedTab),
                    _buildTabItem(
                        'Draft / Paused (${packages.length - activeCount})',
                        2,
                        selectedTab),
                  ],
                ),
              ),

              // ── Packages List ────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No packages found in this view.',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final pkg = filtered[index];
                          return _buildPackageCard(
                            context: context,
                            pkg: pkg,
                            onToggle: () async {
                              try {
                                await ref
                                    .read(organizerPackagesProvider.notifier)
                                    .togglePackageStatus(pkg.id);
                                if (context.mounted) {
                                  AppSnackbar.show(
                                    context,
                                    message: pkg.isActive
                                        ? 'Package deactivated'
                                        : 'Package activated and live!',
                                    type: SnackbarType.info,
                                  );
                                }
                              } on QuotaExceededException {
                                showPlanLimitBottomSheet(activeCount);
                              }
                            },
                            onTap: () => showCreatePackageSheet(pkg),
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
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required BuildContext context,
    required OrganizerPackage pkg,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppNetworkImage(
                  url: pkg.coverImageUrl,
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
                              color: pkg.isActive
                                  ? Colors.green.shade50
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pkg.isActive ? 'ACTIVE' : 'DRAFT / PAUSED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: pkg.isActive
                                    ? Colors.green.shade800
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pkg.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pkg.name,
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
                        '${CurrencyFormatter.formatPaise(pkg.priceInPaise)} • ${pkg.advanceDepositPct}% advance',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: pkg.isActive,
                  activeColor: AppColors.primary,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            if (pkg.lineItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: pkg.lineItems.take(3).map((item) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '• ${item.title}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (pkg.lineItems.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${pkg.lineItems.length - 3} more line items…',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
