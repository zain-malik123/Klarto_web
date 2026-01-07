import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/apis/auth_api_service.dart';
import 'package:klarto/screens/verify_email_screen.dart';
import 'package:klarto/widgets/custom_text_field.dart';
import 'package:klarto/widgets/feature_tile.dart';
import 'package:klarto/widgets/auth_branding_panel.dart';
import 'package:klarto/widgets/auth_form_card.dart';
import 'package:klarto/widgets/social_login_button.dart';
import 'package:klarto/widgets/auth_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final AuthApiService _authApiService = AuthApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authApiService.signup(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                VerifyEmailScreen(email: _emailController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['message']}', style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF3D4CD6),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to connect to the server. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF3D4CD6),
        ),
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
                      children: [
                        const Text(
                          'Create Your Account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF383838),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Join Klarto to start organizing your tasks',
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
                          controller: _nameController,
                          label: 'Full name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name.';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters long.';
                            }
                            return null;
                          },
                        ),
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
                            // Regex for email validation
                            final emailRegex = RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
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
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                  color: Color(0xFF3D4CD6),
                                ))
                              : ElevatedButton(
                                  onPressed: _handleSignup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3D4CD6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Signup',
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
                              "Already have an account? ",
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF707070)),
                            ),
                            TextButton(
                              onPressed: () {
                                // Go back to the previous screen (LoginScreen)
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
                        const SizedBox(height: 24),
                        const Row(
                          children: [
                            Expanded(
                                child: Divider(color: Color(0xFFF0F0F0))),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF707070)),
                              ),
                            ),
                            Expanded(
                                child: Divider(color: Color(0xFFF0F0F0))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SocialLoginButton(
                                imagePath: 'assets/icons/google.png'),
                            SizedBox(width: 16),
                            SocialLoginButton(
                                imagePath: 'assets/icons/facebook.png'),
                            SizedBox(width: 16),
                            SocialLoginButton(
                                imagePath: 'assets/icons/apple.png'),
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