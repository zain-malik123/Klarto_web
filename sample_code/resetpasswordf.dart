import 'dart:ui';

import 'package:flutter/material.dart';

class ResetPasswordF extends StatelessWidget {
  const ResetPasswordF({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Side
          Expanded(
            child: Container(
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
                        const _FeatureTile(
                          title: 'Fast Capture',
                          description:
                              'Add tasks instantly with a clean, frictionless input.',
                        ),
                        const SizedBox(height: 24),
                        const _FeatureTile(
                          title: 'Smart Focus Mode',
                          description:
                              'See only what matters — your own tasks, filtered, max clarity.',
                        ),
                        const SizedBox(height: 24),
                        const _FeatureTile(
                          title: 'Flexible Views',
                          description:
                              'Switch between List and Column views effortlessly, tailored for you.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Right Side
          Expanded(
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // Decorative background elements
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.20,
                    left: MediaQuery.of(context).size.width * 0.075, // Corresponds to left-[15%] of half the screen
                    child: _buildRadialGradientCircle(154, 141),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.20,
                    right: MediaQuery.of(context).size.width * 0.075, // Corresponds to right-[15%] of half the screen
                    child: _buildRadialGradientCircle(132, 162),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.1525,
                    right: MediaQuery.of(context).size.width * 0.05625, // Corresponds to right-[11.25%] of half the screen
                    child: Transform.rotate(
                      angle: 3.14159, // 180 degrees
                      child: _buildStripes(164, 79, const Color(0xFFF0F0F0)),
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.1513,
                    left: MediaQuery.of(context).size.width * 0.05625, // Corresponds to left-[11.25%] of half the screen
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
                              const _CustomTextField(
                                label: 'Email',
                                hint: 'Enter your email',
                                icon: Icons.mail_outline,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Handle send reset instructions
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3D4CD6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Send Reset Instructions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                ],
              ),
            ),
          ),
        ],
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

class _FeatureTile extends StatelessWidget {
  final String title;
  final String description;

  const _FeatureTile({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.024),
              ],
            ),
          ),
          child: const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onToggleVisibility;

  const _CustomTextField({
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF707070))),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword && !isPasswordVisible,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9F9F9F)),
            prefixIcon: Icon(icon, color: const Color(0xFF707070), size: 18),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF707070),
                      size: 18,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF0F0F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF0F0F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3D4CD6)),
            ),
          ),
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xFF383838)),
        ),
      ],
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