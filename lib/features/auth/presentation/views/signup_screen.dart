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
import '../providers/auth_providers.dart';

class SignupScreen extends HookConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final cityController = useTextEditingController(text: 'Mumbai');
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final errorMessage = useState<String?>(null);
    final isSubmitting = useState(false);

    Future<void> handleSignup() async {
      if (!formKey.currentState!.validate()) return;
      errorMessage.value = null;
      isSubmitting.value = true;
      final email = emailController.text.trim();

      try {
        final error = await ref.read(authStateProvider.notifier).signupWithEmail(
              email: email,
              password: passwordController.text.trim(),
              name: nameController.text.trim(),
              city: cityController.text.trim(),
            );
        if (!context.mounted) return;

        if (error != null) {
          errorMessage.value = error;
          
          AppSnackbar.show(
            context,
            message: error,
            type: SnackbarType.error,
          );

          final isConflict = error.toLowerCase().contains('already exists');

          showDialog(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.lightSurface,
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: AppColors.accentRose, size: 36),
              ),
              title: Text(
                isConflict ? 'Account Already Exists' : 'Sign Up Failed',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              content: Text(
                error,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                if (isConflict)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      context.go(AppRoutes.login);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Go to Sign In'),
                  ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isConflict ? 'Use Another Email' : 'OK',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        } else {
          AppSnackbar.show(
            context,
            message: 'Verification code sent to $email',
            type: SnackbarType.info,
          );
          context.push('${AppRoutes.otp}?target=${Uri.encodeComponent(email)}&type=signup');
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Account',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join EventSphere Community 🚀',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start exploring events, booking trusted vendors, or switch into hosting and organizer tools anytime.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Form card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.lightBorder),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Full Name',
                        hint: 'Rohith Kumar',
                        controller: nameController,
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: AppColors.textMuted, size: 20),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Email Address',
                        hint: 'user@example.com',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: AppColors.textMuted, size: 20),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Please enter your email' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'City',
                        hint: 'Mumbai',
                        controller: cityController,
                        prefixIcon: const Icon(Icons.location_city_outlined,
                            color: AppColors.textMuted, size: 20),
                      ),
                      const SizedBox(height: 16),
                      AppPasswordField(
                        label: 'Password',
                        hint: 'Create strong password (min 8 chars)',
                        controller: passwordController,
                        validator: (v) => (v == null || v.length < 8)
                            ? 'Password must be at least 8 characters'
                            : null,
                      ),
                    ],
                  ),
                ),

                if (errorMessage.value != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.accentRose, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage.value!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentRose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                AppPrimaryButton(
                  text: isSubmitting.value ? 'Creating account…' : 'Sign Up',
                  isLoading: isSubmitting.value,
                  onPressed: isSubmitting.value ? null : handleSignup,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
