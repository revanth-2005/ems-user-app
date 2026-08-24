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
        useTextEditingController(text: 'revanthwebnox@gmail.com');
    final passwordController = useTextEditingController(text: '12345678');
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

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
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

          // ── Dark tint overlay (makes text readable) ─────────────────
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),

          // ── Bottom fade-to-black (blends into the panel) ────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xFF141414),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.50, 0.78],
                ),
              ),
            ),
          ),

          // ── Main Content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Logo section
                SizedBox(
                  height: screenHeight * 0.33,
                  child: Column(
                    children: [
                      // Back button if can pop
                      if (context.canPop())
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 16),
                      // EVENTSPHERE logo — background removed PNG
                      Image.asset(
                        'assets/images/eventsphere_logo.png',
                        width: 140,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // ── Bottom sheet panel ─────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF141414),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag handle
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 20),
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF444444),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    'Welcome back',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Sign in to continue',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: const Color(0xFFABABAB),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

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
                                  const SizedBox(height: 10),

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
                                  const SizedBox(height: 16),

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
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: rememberMe.value
                                                      ? AppColors.primary
                                                      : const Color(0xFF737373),
                                                  width: 1.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                color: rememberMe.value
                                                    ? AppColors.primary
                                                    : Colors.transparent,
                                              ),
                                              child: rememberMe.value
                                                  ? const Icon(Icons.check,
                                                      size: 12,
                                                      color: Colors.white)
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Remember me',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                color: const Color(0xFFABABAB),
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
                                            fontSize: 13,
                                            color: const Color(0xFFABABAB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),

                                  // Error banner
                                  if (loginError.value != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
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
                                              size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              loginError.value!,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Sign in button with smooth red gradient & ambient glow
                                  Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
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
                                              .withValues(alpha: 0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: isLoading ? null : handleLogin,
                                        child: Center(
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  'Sign in',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // OTP login (secondary)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: () => context.push(
                                          '${AppRoutes.otp}?phone=+919876543210'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                            color: Color(0xFF444444),
                                            width: 1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: Text(
                                        'Login with OTP',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFABABAB),
                                        ),
                                      ),
                                    ),
                                  ),
                                   const SizedBox(height: 16),

                                   // ── OR divider ───────────────────────────
                                   Row(
                                     children: [
                                       const Expanded(
                                           child: Divider(
                                               color: Color(0xFF333333),
                                               thickness: 1)),
                                       Padding(
                                         padding: const EdgeInsets.symmetric(
                                             horizontal: 12),
                                         child: Text('OR',
                                             style: GoogleFonts.plusJakartaSans(
                                               fontSize: 12,
                                               color: const Color(0xFF666666),
                                               fontWeight: FontWeight.w600,
                                             )),
                                       ),
                                       const Expanded(
                                           child: Divider(
                                               color: Color(0xFF333333),
                                               thickness: 1)),
                                     ],
                                   ),
                                   const SizedBox(height: 16),

                                   // ── Google Sign-In button ─────────────────
                                   SizedBox(
                                     width: double.infinity,
                                     height: 50,
                                     child: OutlinedButton(
                                       onPressed:
                                           isLoading ? null : handleGoogleLogin,
                                       style: OutlinedButton.styleFrom(
                                         backgroundColor:
                                             const Color(0xFF1E1E1E),
                                         side: const BorderSide(
                                             color: Color(0xFF3A3A3A),
                                             width: 1),
                                         shape: RoundedRectangleBorder(
                                           borderRadius:
                                               BorderRadius.circular(10),
                                         ),
                                       ),
                                       child: Row(
                                         mainAxisAlignment:
                                             MainAxisAlignment.center,
                                         children: [
                                           const _GoogleIcon(),
                                           const SizedBox(width: 12),
                                           Text(
                                             'Continue with Google',
                                             style: GoogleFonts.plusJakartaSans(
                                               fontSize: 14,
                                               fontWeight: FontWeight.w600,
                                               color: Colors.white,
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ),
                                   const SizedBox(height: 24),

                                  // Sign up link
                                  Center(
                                    child: GestureDetector(
                                      onTap: () =>
                                          context.push(AppRoutes.signup),
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: const Color(0xFFABABAB),
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
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                ],
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

// ── Netflix-style dark text field ─────────────────────────────────────────────
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: const Color(0xFFCCCCCC),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF737373),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF333333),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFABABAB), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE50914), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFE50914), width: 1.5),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
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
        icon: Icon(
          _obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: const Color(0xFF737373),
          size: 20,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

// ── Google 'G' logo painted widget ───────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
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

    // White cutout rectangle for the horizontal bar of the 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
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
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
