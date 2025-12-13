import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klarto/apis/auth_api_service.dart';
import 'package:klarto/screens/verify_email_screen.dart';
import 'package:klarto/widgets/custom_text_field.dart';
import 'package:klarto/widgets/feature_tile.dart';
import 'package:klarto/widgets/social_login_button.dart';

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
            ),
          ),
          // Right Side
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
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
                              hint: 'Enter your full name',
                              icon: Icons.person_outline,
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
                              hint: 'Enter your email',
                              icon: Icons.mail_outline,
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
                              hint: 'Enter your password',
                              icon: Icons.lock_outline,
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
                                      color: Colors.white,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}