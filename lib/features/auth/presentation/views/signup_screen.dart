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
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    Future<void> handleSignup() async {
      if (!formKey.currentState!.validate()) return;
      await ref.read(authStateProvider.notifier).signupWithEmail(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            name: nameController.text.trim(),
            city: cityController.text.trim(),
          );
      if (context.mounted && ref.read(authStateProvider).hasValue) {
        AppSnackbar.show(
          context,
          message: 'Account created successfully! Welcome to EventSphere.',
          type: SnackbarType.success,
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
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
                        hint: 'Create strong password',
                        controller: passwordController,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                AppPrimaryButton(
                  text: isLoading ? 'Creating account…' : 'Sign Up',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : handleSignup,
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
