import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klarto/apis/user_api_service.dart';
import 'package:klarto/screens/main_app_shell.dart';
import 'package:klarto/screens/onboarding/onboarding_screen.dart';
import 'package:klarto/screens/login_screen.dart';
import 'package:klarto/widgets/custom_text_field.dart';
import 'package:klarto/widgets/auth_branding_panel.dart';
import 'package:klarto/widgets/auth_form_card.dart';
import 'package:klarto/widgets/auth_background.dart';

class AcceptInviteScreen extends StatefulWidget {
  final String token;
  const AcceptInviteScreen({super.key, required this.token});

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final UserApiService _userApi = UserApiService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _userApi.setPasswordForInvite(
      token: widget.token,
      password: _passwordController.text,
    );

    if (!mounted) return;

      if (result['success'] == true && result['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', result['token']);

      final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => onboardingCompleted ? const MainAppShell() : const OnboardingScreen(showInviteStep: false)),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['message'] ?? 'Failed to accept invite.'}')),
      );
    }

    setState(() => _isLoading = false);
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
                          'Set a Password to Join',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF383838),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a password for your new account to sign in immediately.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 14, color: Color(0xFF707070)),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hintText: 'Enter a password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onToggleVisibility: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password.';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters long.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hintText: 'Confirm your password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          onToggleVisibility: () => setState(() =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password.';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match.';
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
                                  onPressed: _handleSetPassword,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3D4CD6),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                  child: const Text('Join and Sign In',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                                (route) => false);
                          },
                          child: const Text('Back to Login',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3D4CD6),
                                  decoration: TextDecoration.none)),
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
