import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController =
        useTextEditingController(text: 'user@ems.platform');
    final passwordController = useTextEditingController(text: 'Password123!');
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final loginError = useState<String?>(null);
    final rememberMe = useState(false);
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;
      loginError.value = null;
      final error = await ref.read(authStateProvider.notifier).loginWithEmail(
            emailController.text.trim(),
            passwordController.text.trim(),
          );
      if (!context.mounted) return;

      if (error != null) {
        loginError.value = error;
        AppSnackbar.show(
          context,
          message: error,
          type: SnackbarType.error,
        );
      } else {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      }
    }

    Future<void> handleGoogleLogin() async {
      loginError.value = null;
      final error =
          await ref.read(authStateProvider.notifier).signInWithGoogle();
      if (!context.mounted) return;
      if (error != null) {
        loginError.value = error;
        AppSnackbar.show(context,
            message: error, type: SnackbarType.error);
      } else {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      }
    }

    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      body: Stack(
        children: [
          // ── Background image ────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/large-banquet-hall-with-large-screens.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ── Tint overlay (makes text readable) ─────────────────
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.black.withValues(alpha: 0.35),
            ),
          ),

          // ── Bottom fade (blends into the panel) ────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    isDark ? const Color(0xFF141414) : AppColors.whiteSurface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.40, 0.70],
                ),
              ),
            ),
          ),

          // ── Main Content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top Banner section (fills upper space, logo at top position)
                Expanded(
                  child: Column(
                    children: [
                      // Top navigation row
                      if (context.canPop())
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 16),
                      // EVENTSPHERE logo
                      Image.asset(
                        'assets/images/eventsphere_logo.png',
                        width: 140,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // ── Bottom sheet panel (snugly hugs content at bottom) ─────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414) : AppColors.whiteSurface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, -4),
                            ),
                          ],
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag handle
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 12),
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF444444)
                                      : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),

                          // Title & Subtitle
                          Text(
                            'Welcome back',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign in to continue',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Email field
                          _NetflixTextField(
                            controller: emailController,
                            hint: 'Email or phone number',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // Password field
                          _NetflixPasswordField(
                            controller: passwordController,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                            onSubmitted: (_) => handleLogin(),
                          ),
                          const SizedBox(height: 10),

                          // Remember me + Need help?
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => rememberMe.value =
                                    !rememberMe.value,
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 150),
                                      width: 17,
                                      height: 17,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: rememberMe.value
                                              ? AppColors.primary
                                              : (isDark
                                                  ? const Color(0xFF737373)
                                                  : const Color(0xFFD1D5DB)),
                                          width: 1.5,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        color: rememberMe.value
                                            ? AppColors.primary
                                            : (isDark
                                                ? Colors.transparent
                                                : Colors.white),
                                      ),
                                      child: rememberMe.value
                                          ? const Icon(Icons.check,
                                              size: 11,
                                              color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Remember me',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  AppSnackbar.show(
                                    context,
                                    message:
                                        'Password reset link sent to email',
                                    type: SnackbarType.info,
                                  );
                                },
                                child: Text(
                                  'Need help?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Error banner
                          if (loginError.value != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.primary,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      loginError.value!,
                                      style:
                                          GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Sign in button with smooth red gradient & ambient glow
                          Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE50914), // bright Netflix red top
                                  Color(0xFFB8070F), // rich crimson middle
                                  Color(0xFF90040A), // deep dark red bottom
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE50914)
                                      .withValues(alpha: isDark ? 0.35 : 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: isLoading ? null : handleLogin,
                                child: Center(
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Sign in',
                                          style: GoogleFonts
                                              .plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // OTP login (secondary)
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => context.push(
                                  '${AppRoutes.otp}?phone=+919876543210'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.getTextPrimary(context),
                                backgroundColor: isDark
                                    ? Colors.transparent
                                    : AppColors.whiteCardAlt,
                                side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF444444)
                                        : const Color(0xFFE5E7EB),
                                    width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Login with OTP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ── OR divider ───────────────────────────
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: isDark
                                          ? const Color(0xFF333333)
                                          : const Color(0xFFE5E7EB),
                                      thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text('OR',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.getTextMuted(context),
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: isDark
                                          ? const Color(0xFF333333)
                                          : const Color(0xFFE5E7EB),
                                      thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // ── Google Sign-In button ─────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed:
                                  isLoading ? null : handleGoogleLogin,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF3A3A3A)
                                        : const Color(0xFFE5E7EB),
                                    width: 1),
                                elevation: isDark ? 0 : 1,
                                shadowColor: Colors.black.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  _GoogleIcon(
                                    backgroundColor: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Sign up link (directly below Google Sign-In with standard 14px gap - NO EMPTY GAP!)
                          Center(
                            child: GestureDetector(
                              onTap: () =>
                                  context.push(AppRoutes.signup),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                  children: [
                                    const TextSpan(
                                        text: 'First time here? '),
                                    TextSpan(
                                      text: 'Sign up',
                                      style:
                                          GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Netflix-style text field ─────────────────────────────────────────────
class _NetflixTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final void Function(String)? onSubmitted;

  const _NetflixTextField({
    this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        color: AppColors.getTextPrimary(context),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          color: AppColors.getTextMuted(context),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: isDark
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: isDark
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE50914), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE50914), width: 1.5),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          color: const Color(0xFFE50914),
        ),
      ),
    );
  }
}

// ── Netflix-style password field with visibility toggle ───────────────────────
class _NetflixPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _NetflixPasswordField({
    this.controller,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<_NetflixPasswordField> createState() => _NetflixPasswordFieldState();
}

class _NetflixPasswordFieldState extends State<_NetflixPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return _NetflixTextField(
      controller: widget.controller,
      hint: 'Password',
      obscureText: _obscure,
      validator: widget.validator,
      onSubmitted: widget.onSubmitted,
      suffixIcon: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          _obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.getTextSecondary(context),
          size: 19,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

// ── Google 'G' logo painted widget ───────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  final Color backgroundColor;
  const _GoogleIcon({this.backgroundColor = const Color(0xFF1E1E1E)});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(backgroundColor: backgroundColor),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  final Color backgroundColor;
  _GoogleLogoPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final segments = [
      (const Color(0xFF4285F4), -10.0, 85.0),
      (const Color(0xFF34A853),  75.0, 90.0),
      (const Color(0xFFFBBC05), 165.0, 90.0),
      (const Color(0xFFEA4335), 255.0, 75.0),
    ];

    for (final (color, startDeg, sweepDeg) in segments) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        startDeg * 3.14159265 / 180,
        sweepDeg * 3.14159265 / 180,
        false,
        paint,
      );
    }

    // Cutout rectangle for the horizontal bar of the 'G'
    final barPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - size.width * 0.04,
        center.dy - size.height * 0.12,
        size.width * 0.54,
        size.height * 0.24,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor;
}
