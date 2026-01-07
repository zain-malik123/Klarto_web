import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:klarto/screens/login_screen.dart';

import 'package:klarto/widgets/feature_tile.dart';
import 'package:klarto/widgets/auth_branding_panel.dart';
import 'package:klarto/widgets/auth_form_card.dart';
import 'package:klarto/widgets/auth_background.dart';

class ResetPasswordBScreen extends StatelessWidget {
  const ResetPasswordBScreen({super.key});

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
