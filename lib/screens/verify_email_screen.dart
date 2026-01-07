import 'package:flutter/material.dart';
import 'package:klarto/screens/login_screen.dart';
import 'package:klarto/widgets/auth_branding_panel.dart';
import 'package:klarto/widgets/auth_form_card.dart';
import 'package:klarto/widgets/auth_background.dart';

class VerifyEmailScreen extends StatelessWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 900;

          final rightSide = AuthBackground(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AuthFormCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF3D4CD6),
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF383838),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We have sent a verification link to your email address: $email. Please check your inbox and click the link to activate your account.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF707070),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to the login screen, removing all previous screens
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
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
                            'Back to Login',
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
          );

          if (!isWideScreen) return rightSide;

          return Row(
            children: [
              const AuthBrandingPanel(),
              Expanded(child: rightSide),
            ],
          );
        },
      ),
    );
  }
}