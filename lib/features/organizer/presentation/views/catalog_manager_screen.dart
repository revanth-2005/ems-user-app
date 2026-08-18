import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/organizer_providers.dart';

class CatalogManagerScreen extends HookConsumerWidget {
  const CatalogManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogManagerProvider);

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
          'Catalog & Listings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(catalogManagerProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyView(
              icon: Icons.inventory_2_outlined,
              title: 'No Catalog Items',
              subtitle: 'Add your first package or service listing.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    AppNetworkImage(
                      url: item.coverImageUrl,
                      width: 72,
                      height: 72,
                      borderRadius: 14,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppStatusBadge(
                                label: item.type,
                                status: BadgeStatus.accepted,
                              ),
                              const SizedBox(width: 6),
                              AppStatusBadge(
                                label: item.isActive ? 'Active' : 'Paused',
                                status: item.isActive
                                    ? BadgeStatus.completed
                                    : BadgeStatus.cancelled,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatPaise(item.priceInPaise),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: item.isActive,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        ref
                            .read(catalogManagerProvider.notifier)
                            .toggleItem(item.id);
                        AppSnackbar.show(
                          context,
                          message: val ? 'Listing published' : 'Listing paused',
                          type: SnackbarType.info,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
