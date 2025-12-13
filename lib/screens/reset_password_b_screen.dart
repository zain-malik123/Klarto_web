import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:klarto/screens/login_screen.dart';

import 'package:klarto/widgets/feature_tile.dart';

class ResetPasswordBScreen extends StatelessWidget {
  const ResetPasswordBScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using LayoutBuilder to get constraints for responsive positioning
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate positions based on the right panel's width
          final rightPanelWidth = constraints.maxWidth / 2;

          return Row(
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
                                  color: Colors.white,
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
                            const FeatureTile(
                              title: 'Fast Capture',
                              description:
                                  'Add tasks instantly with a clean, frictionless input.',
                            ),
                            const SizedBox(height: 24),
                            const FeatureTile(
                              title: 'Smart Focus Mode',
                              description:
                                  'See only what matters — your own tasks, filtered, max clarity.',
                            ),
                            const SizedBox(height: 24),
                            const FeatureTile(
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
                        top: constraints.maxHeight * 0.20,
                        left: rightPanelWidth * 0.15,
                        child: _buildRadialGradientCircle(154, 141),
                      ),
                      Positioned(
                        bottom: constraints.maxHeight * 0.20,
                        right: rightPanelWidth * 0.15,
                        child: _buildRadialGradientCircle(132, 162),
                      ),
                      Positioned(
                        top: constraints.maxHeight * 0.1525,
                        right: rightPanelWidth * 0.1125,
                        child: Transform.rotate(
                          angle: 3.14159, // 180 degrees
                          child: _buildStripes(164, 79, const Color(0xFFF0F0F0)),
                        ),
                      ),
                      Positioned(
                        bottom: constraints.maxHeight * 0.1513,
                        left: rightPanelWidth * 0.05625,
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
                                    'Password Reset Instructions Sent',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF383838),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'We have sent an email, please check your inbox and follow the instructions to reset your password.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF707070),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginScreen()),
                                          (Route<dynamic> route) => false,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3D4CD6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Login Now',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF3D4CD6).withOpacity(0.4),
              const Color(0xFF3D4CD6).withOpacity(0.1),
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildStripes(double height, double width, Color stripeColor) {
    return Opacity(
      opacity: 0.3,
      child: CustomPaint(
        size: Size(width, height),
        painter: _StripesPainter(stripeColor),
      ),
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