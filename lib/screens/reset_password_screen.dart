import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:klarto/apis/auth_api_service.dart';
import 'package:klarto/screens/reset_password_b_screen.dart';

import 'package:klarto/widgets/feature_tile.dart';
import 'package:klarto/widgets/custom_text_field.dart';
import 'package:klarto/widgets/auth_branding_panel.dart';
import 'package:klarto/widgets/auth_form_card.dart';
import 'package:klarto/widgets/auth_background.dart';

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
          final isWideScreen = constraints.maxWidth >= 900;

          final rightSide = AuthBackground(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AuthFormCard(
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
                            final emailRegex = RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
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
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF3D4CD6)))
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
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
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


