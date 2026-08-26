import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/catalog_providers.dart';

class FollowButton extends ConsumerWidget {
  final String organizerId;
  final String organizerName;
  final bool initialIsFollowed;
  final int initialFollowerCount;
  final bool isCompact;
  final ValueChanged<bool>? onFollowChanged;

  const FollowButton({
    super.key,
    required this.organizerId,
    required this.organizerName,
    this.initialIsFollowed = false,
    this.initialFollowerCount = 0,
    this.isCompact = false,
    this.onFollowChanged,
  });

  Future<bool?> _showUnfollowConfirmation(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.getSurface(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.getBorder(ctx)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getBorder(ctx),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_remove_rounded,
                color: AppColors.accentRose,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Unfollow $organizerName?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(ctx),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You will no longer receive priority listings, notifications, or ranking boosts from this organizer.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.getTextSecondary(ctx),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: AppColors.getBorder(ctx)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextPrimary(ctx),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRose,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Unfollow',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthRequiredSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.getSurface(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.getBorder(ctx)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getBorder(ctx),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Sign In to Follow Organizers',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(ctx),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to follow your favorite event organizers and get personalized recommendations.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.getTextSecondary(ctx),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: AppColors.getBorder(ctx)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextPrimary(ctx),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.login);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.valueOrNull != null;

    final followedIds = ref.watch(followedOrganizerIdsProvider);
    final isGloballyFollowed = followedIds.contains(organizerId);

    final followArgs = OrganizerFollowArgs(
      id: organizerId,
      initialFollow: isGloballyFollowed,
      initialFollowerCount: initialFollowerCount,
    );

    final isFollowing = isGloballyFollowed || (initialIsFollowed && followedIds.isEmpty);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (!isAuthenticated) {
          _showAuthRequiredSheet(context);
          return;
        }

        if (isFollowing) {
          final confirm = await _showUnfollowConfirmation(context);
          if (confirm != true) return;
        }

        if (!context.mounted) return;

        ref.read(organizerFollowProvider(followArgs).notifier).toggleFollow(
          onMessage: (msg, {isError = false}) {
            if (onFollowChanged != null) {
              onFollowChanged!(!isFollowing);
            }
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  msg,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: isError ? AppColors.accentRose : AppColors.success,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 16,
          vertical: isCompact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isFollowing
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing ? AppColors.primary : Colors.transparent,
          ),
          boxShadow: isFollowing
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowing ? Icons.check_rounded : Icons.add_rounded,
              size: isCompact ? 13 : 15,
              color: isFollowing ? AppColors.primary : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              isFollowing
                  ? 'Following'
                  : (isCompact ? 'Follow' : 'Follow Studio'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: isCompact ? 11 : 12.5,
                fontWeight: FontWeight.w700,
                color: isFollowing ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
