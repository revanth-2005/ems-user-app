import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/organizer_providers.dart';

class OrganizerBecomeScreen extends HookConsumerWidget {
  const OrganizerBecomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessNameController = useTextEditingController(text: 'Aura Event Studios');
    final displayNameController = useTextEditingController(text: 'Aura Events & Co.');
    final bioController = useTextEditingController(
        text: 'Premier luxury wedding and corporate event curators.');
    final cityController = useTextEditingController(text: 'Mumbai');
    final emailController = useTextEditingController(text: 'contact@auraevents.in');
    final phoneController = useTextEditingController(text: '+91 98765 43210');
    final panGstController = useTextEditingController(text: '27AABCU9603R1ZM');
    final accountHolderController = useTextEditingController(text: 'Aura Event Studios LLP');
    final accountNumberController = useTextEditingController(text: '5020004819281');
    final ifscController = useTextEditingController(text: 'HDFC0000128');

    final selectedCategories = useState<List<String>>([
      'Wedding Planners',
      'Decorators',
      'DJ & Sound',
    ]);

    final panDocUploaded = useState(true);
    final gstDocUploaded = useState(true);
    final isSubmitting = useState(false);

    final allCategories = [
      'Wedding Planners',
      'Decorators',
      'Catering',
      'DJ & Sound',
      'Photography',
      'Anchor & Emcee',
      'Makeup & Styling',
      'Venue & Staging',
      'Lighting & Pyro',
    ];

    Future<void> handleSubmit() async {
      if (businessNameController.text.trim().isEmpty ||
          panGstController.text.trim().isEmpty ||
          accountNumberController.text.trim().isEmpty ||
          ifscController.text.trim().isEmpty) {
        AppSnackbar.show(
          context,
          message: 'Please fill in all mandatory business and bank details.',
          type: SnackbarType.warning,
        );
        return;
      }

      isSubmitting.value = true;
      try {
        await ref.read(organizerProfileProvider.notifier).submitKyc(
              businessName: businessNameController.text.trim(),
              displayName: displayNameController.text.trim(),
              bio: bioController.text.trim(),
              city: cityController.text.trim(),
              contactEmail: emailController.text.trim(),
              contactPhone: phoneController.text.trim(),
              categories: selectedCategories.value,
              panGst: panGstController.text.trim(),
              bankAccount: accountNumberController.text.trim(),
              ifsc: ifscController.text.trim(),
              accountHolder: accountHolderController.text.trim(),
            );

        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Application & KYC documents submitted successfully!',
            type: SnackbarType.success,
          );
          context.pushReplacement(AppRoutes.organizerKycPending);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: 'Submission failed: $e',
            type: SnackbarType.error,
          );
        }
      } finally {
        isSubmitting.value = false;
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Become an Organizer',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Benefits Card ─────────────────────────────────────────
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grow Your Event Business',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Reach verified clients & unlock instant payouts',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  _buildBenefitRow(
                    icon: Icons.money_off_csred_rounded,
                    title: '0% Platform Commission Guarantee',
                    subtitle: 'Keep 100% of your listed service and package fees.',
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: Icons.account_balance_rounded,
                    title: 'Direct Bank Payouts with Escrow',
                    subtitle: 'Advance deposits release securely into your bank.',
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: Icons.hub_outlined,
                    title: 'Multi-Service & Standalone Listings',
                    subtitle: 'Publish custom wedding packages or hourly bookings.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Section 1: Business Profile ─────────────────────────────────
            _buildSectionHeader('1. Business Details 🏢',
                'Tell clients who you are and what services you specialize in.'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: AppColors.getCardShadow(context),
              ),
              child: Column(
                children: [
                  AppTextField(
                    label: 'Registered Business Name *',
                    hint: 'e.g. Aura Event Studios LLP',
                    controller: businessNameController,
                    prefixIcon: Icon(Icons.business_rounded,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Brand / Display Name',
                    hint: 'e.g. Aura Events & Co.',
                    controller: displayNameController,
                    prefixIcon: Icon(Icons.storefront_rounded,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Short Bio & Specialization',
                    hint: 'Describe your style, experience, and key offerings…',
                    controller: bioController,
                    maxLines: 2,
                    prefixIcon: Icon(Icons.description_outlined,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Base City *',
                          hint: 'e.g. Mumbai',
                          controller: cityController,
                          prefixIcon: Icon(Icons.location_on_outlined,
                              color: AppColors.getTextMuted(context), size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Contact Phone *',
                          hint: '+91 98765 43210',
                          controller: phoneController,
                          prefixIcon: Icon(Icons.phone_outlined,
                              color: AppColors.getTextMuted(context), size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Business Email *',
                    hint: 'contact@auraevents.in',
                    controller: emailController,
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Section 2: Categories ───────────────────────────────────────
            _buildSectionHeader('2. Event Categories 🎪',
                'Select the primary services you provide:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allCategories.map((category) {
                final isSelected = selectedCategories.value.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.getTextPrimary(context),
                  ),
                  backgroundColor: AppColors.getSurface(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.getBorder(context),
                    ),
                  ),
                  onSelected: (selected) {
                    final current = List<String>.from(selectedCategories.value);
                    if (selected) {
                      current.add(category);
                    } else {
                      current.remove(category);
                    }
                    selectedCategories.value = current;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Section 3: Bank Details ─────────────────────────────────────
            _buildSectionHeader('3. Bank Payout Details 💳',
                'Client booking advances are routed directly to this bank account.'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: AppColors.getCardShadow(context),
              ),
              child: Column(
                children: [
                  AppTextField(
                    label: 'Account Holder Name *',
                    hint: 'e.g. Aura Event Studios LLP',
                    controller: accountHolderController,
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Bank Account Number *',
                    hint: '5020004819281',
                    controller: accountNumberController,
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Bank IFSC Code *',
                    hint: 'HDFC0000128',
                    controller: ifscController,
                    prefixIcon: Icon(Icons.numbers_rounded,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Section 4: Identity & KYC Documents ─────────────────────────
            _buildSectionHeader('4. Identity & Tax Verification 🛡️',
                'Government compliance verification for trusted organizer status.'),
            const SizedBox(height: 14),
            Container(
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
                  AppTextField(
                    label: 'PAN Number / GSTIN *',
                    hint: '27AABCU9603R1ZM',
                    controller: panGstController,
                    prefixIcon: Icon(Icons.badge_outlined,
                        color: AppColors.getTextMuted(context), size: 20),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Upload KYC Documents (Uploaded to MinIO S3)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDocUploadTile(
                    title: 'Business PAN Card (Photo / PDF)',
                    filename: 'pan_card_aura_studios.pdf',
                    isUploaded: panDocUploaded.value,
                    onTap: () {
                      panDocUploaded.value = !panDocUploaded.value;
                      AppSnackbar.show(
                        context,
                        message: panDocUploaded.value
                            ? 'PAN document attached'
                            : 'Document removed',
                        type: SnackbarType.info,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildDocUploadTile(
                    title: 'GST Certificate (Optional for Sole Proprietors)',
                    filename: 'gst_certificate_2026.pdf',
                    isUploaded: gstDocUploaded.value,
                    onTap: () {
                      gstDocUploaded.value = !gstDocUploaded.value;
                      AppSnackbar.show(
                        context,
                        message: gstDocUploaded.value
                            ? 'GST document attached'
                            : 'Document removed',
                        type: SnackbarType.info,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ───────────────────────────────────────────────
            AppPrimaryButton(
              text: isSubmitting.value
                  ? 'Submitting Application…'
                  : 'Submit Application & KYC →',
              isLoading: isSubmitting.value,
              onPressed: isSubmitting.value ? null : handleSubmit,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDocUploadTile({
    required String title,
    required String filename,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUploaded ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded ? Colors.green.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              color: isUploaded ? Colors.green.shade700 : Colors.grey.shade700,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isUploaded ? Colors.green.shade900 : Colors.grey.shade900,
                    ),
                  ),
                  if (isUploaded)
                    Text(
                      filename,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              isUploaded ? 'Change' : 'Upload',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isUploaded ? Colors.green.shade800 : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
