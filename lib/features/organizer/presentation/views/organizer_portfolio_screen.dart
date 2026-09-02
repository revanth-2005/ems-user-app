import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/organizer_entities.dart';
import '../providers/organizer_providers.dart';

class OrganizerPortfolioScreen extends HookConsumerWidget {
  const OrganizerPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(organizerPortfolioProvider);

    void showAddMediaSheet() {
      final captionCtrl = TextEditingController();
      final urlCtrl = TextEditingController(
          text:
              'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop');

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Portfolio Media',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
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
              const SizedBox(height: 10),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Media Image / Video URL (MinIO S3)',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Caption / Event Highlight',
                  hintText: 'e.g. Royal palace wedding mandap decor',
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                text: 'Upload to Portfolio 📸',
                onPressed: () {
                  final newItem = PortfolioMediaItem(
                    id: 'pf_${DateTime.now().millisecondsSinceEpoch}',
                    mediaUrl: urlCtrl.text.trim().isNotEmpty
                        ? urlCtrl.text.trim()
                        : 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop',
                    caption: captionCtrl.text.trim().isNotEmpty
                        ? captionCtrl.text.trim()
                        : 'Grand Celebration Event',
                    sortOrder: 1,
                    createdAt: DateTime.now(),
                  );

                  ref
                      .read(organizerPortfolioProvider.notifier)
                      .addMedia(newItem);
                  Navigator.pop(ctx);
                  AppSnackbar.show(
                    context,
                    message: 'Media added to your public portfolio!',
                    type: SnackbarType.success,
                  );
                },
              ),
            ],
          ),
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
          'Portfolio Showcase',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 24),
            onPressed: showAddMediaSheet,
          ),
        ],
      ),
      body: portfolioAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => AppErrorView(message: e.toString()),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.collections_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No portfolio items uploaded yet.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: showAddMediaSheet,
                    child: const Text('Upload First Media'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.getBorder(context)),
                  boxShadow: AppColors.getCardShadow(context),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppNetworkImage(
                              url: item.mediaUrl,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: Colors.white),
                                  onPressed: () {
                                    ref
                                        .read(
                                            organizerPortfolioProvider.notifier)
                                        .deleteMedia(item.id);
                                    AppSnackbar.show(
                                      context,
                                      message: 'Media deleted from portfolio.',
                                      type: SnackbarType.info,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          item.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
