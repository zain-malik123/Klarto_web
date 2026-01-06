import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:klarto/apis/auth_api_service.dart';
import 'package:klarto/screens/reset_password_b_screen.dart';

import 'package:klarto/widgets/feature_tile.dart';
import 'package:klarto/widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // The API call will always seem to succeed to prevent email enumeration.
    await _authApiService.requestPasswordReset(email: _emailController.text);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ResetPasswordBScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 900;

          final leftSide = Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2838B5),
                    Color(0xFF3D4CD6),
                    Color(0xFF4A5AE8),
                  ],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 65,
                              height: 65,
                            ),
                            const SizedBox(width: 18),
                            const Text(
                              'Klarto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 65,
                                fontWeight: FontWeight.w600,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        FeatureTile(
                          title: 'Fast Capture',
                          description:
                              'Add tasks instantly with a clean, frictionless input.',
                        ),
                        const SizedBox(height: 24),
                        FeatureTile(
                          title: 'Smart Focus Mode',
                          description:
                              'See only what matters — your own tasks, filtered, max clarity.',
                        ),
                        const SizedBox(height: 24),
                        FeatureTile(
                          title: 'Flexible Views',
                          description:
                              'Switch between List and Column views effortlessly, tailored for you.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

          final rightSide = Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // Decorative background elements
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.20,
                    left: MediaQuery.of(context).size.width *
                        0.075, // Corresponds to left-[15%] of half the screen
                    child: _buildRadialGradientCircle(154, 141),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.20,
                    right: MediaQuery.of(context).size.width *
                        0.075, // Corresponds to right-[15%] of half the screen
                    child: _buildRadialGradientCircle(132, 162),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.1525,
                    right: MediaQuery.of(context).size.width *
                        0.05625, // Corresponds to right-[11.25%] of half the screen
                    child: Transform.rotate(
                      angle: 3.14159, // 180 degrees
                      child: _buildStripes(164, 79, const Color(0xFFF0F0F0)),
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.1513,
                    left: MediaQuery.of(context).size.width *
                        0.05625, // Corresponds to left-[11.25%] of half the screen
                    child: _buildStripes(164, 79, const Color(0xFFEEEEEE)),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Reset Your Password',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF383838),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Enter the email address you used when you created the account. You will receive an email with instructions on how to change your password.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF707070),
                                ),
                              ),
                              const SizedBox(height: 40),
                              // This can be used to display authentication errors
                              // const Text(
                              //   'Your error message here',
                              //   style: TextStyle(color: Colors.red, fontSize: 14),
                              // ),
                              const SizedBox(height: 24),
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: Icons.mail_outline,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email address.';
                                  }
                                  final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Please enter a valid email address.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                    : ElevatedButton(
                                        onPressed: _handleResetRequest,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3D4CD6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Send Reset Instructions',
                                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                    ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Remember your password? ",
                                    style: TextStyle(
                                        fontSize: 14, color: Color(0xFF707070)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to login page
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF3D4CD6),
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                           ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

          if (!isWideScreen) return rightSide;

          return Row(
            children: [
              Expanded(child: leftSide),
              Expanded(child: rightSide),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadialGradientCircle(double height, double width) {
    return Opacity(
      opacity: 0.4,
      child: Container(
        height: height,
        width: width,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color(0xFF3D4CD6),
              Color(0x1A3D4CD6), // Equivalent to rgba(61, 76, 214, 0.1)
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildStripes(double height, double width, Color stripeColor) {
    return CustomPaint(
      size: Size(width, height),
      painter: _StripesPainter(stripeColor),
    );
  }
}

class _StripesPainter extends CustomPainter {
  final Color stripeColor;
  _StripesPainter(this.stripeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 1;

    for (double i = 10; i < size.width; i += 11) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}