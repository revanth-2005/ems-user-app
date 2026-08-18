import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_providers.dart';

class VerifyOtpScreen extends HookConsumerWidget {
  final String phone;

  const VerifyOtpScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllers = useMemoized(
      () => List.generate(6, (_) => TextEditingController()),
    );
    final focusNodes = useMemoized(
      () => List.generate(6, (_) => FocusNode()),
    );

    useEffect(() {
      return () {
        for (var c in controllers) {
          c.dispose();
        }
        for (var f in focusNodes) {
          f.dispose();
        }
      };
    }, const []);

    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    String getEnteredOtp() => controllers.map((c) => c.text).join();

    Future<void> verifyOtp() async {
      final otp = getEnteredOtp();
      if (otp.length < 6) {
        AppSnackbar.show(
          context,
          message: 'Please enter the full 6-digit verification code',
          type: SnackbarType.warning,
        );
        return;
      }

      await ref.read(authStateProvider.notifier).verifyPhoneOtp(phone, otp);

      if (context.mounted && ref.read(authStateProvider).hasValue) {
        AppSnackbar.show(
          context,
          message: 'Phone verified successfully!',
          type: SnackbarType.success,
        );
        context.go(AppRoutes.home);
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
          'Verify OTP',
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Verification Code 📲',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit one-time passcode to $phone',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // OTP Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextFormField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.lightSurface,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.lightBorder, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.lightBorder, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          focusNodes[index - 1].requestFocus();
                        }
                        if (getEnteredOtp().length == 6) {
                          verifyOtp();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 36),

              AppPrimaryButton(
                text: isLoading ? 'Verifying…' : 'Verify & Continue',
                isLoading: isLoading,
                onPressed: isLoading ? null : verifyOtp,
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(authStateProvider.notifier).requestPhoneOtp(phone);
                    AppSnackbar.show(
                      context,
                      message: 'A new code has been sent to $phone',
                      type: SnackbarType.info,
                    );
                  },
                  child: Text(
                    'Resend OTP Code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
