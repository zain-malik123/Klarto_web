import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klarto/apis/auth_api_service.dart';
import 'package:klarto/screens/home_screen.dart';
import 'package:klarto/screens/signup_screen.dart';
import 'package:klarto/screens/reset_password_screen.dart';
import 'package:klarto/widgets/feature_tile.dart';
import 'package:klarto/widgets/custom_text_field.dart';
import 'package:klarto/widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  final Map<String, String> queryParams;
  const LoginScreen({super.key, this.queryParams = const {}});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleVerificationStatus());
    _loadUserEmail();
  }

  void _handleVerificationStatus() {
    final status = widget.queryParams['verification'];
    if (status == null) return;

    String message;
    Color backgroundColor;

    switch (status) {
      case 'success':
        message = 'Email verified successfully! Please log in.';
        backgroundColor = Colors.green;
        break;
      case 'expired':
      case 'invalid':
      case 'failed':
      default:
        message = 'Email verification failed. Please try signing up again.';
        backgroundColor = Colors.red;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: backgroundColor));
  }

  void _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('remembered_email');
    if (email != null) {
      setState(() {
        _emailController.text = email;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authApiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('remembered_email', _emailController.text);
        } else {
          await prefs.remove('remembered_email');
        }

        // TODO: Securely store the token (result['token'])
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['message']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to the server.'), backgroundColor: Colors.red),
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
                            'Welcome To Klarto',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF383838),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sign up to start your Journey',
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
                            hint: 'Enter your email',
                            icon: Icons.mail_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email.';
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
                                return 'Please enter your password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 24.0,
                                    width: 24.0,
                                    child: Checkbox(
                                      activeColor: const Color(0xFF3D4CD6),
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Remember Me',
                                    style: TextStyle(fontSize: 14, color: Color(0xFF707070)),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ResetPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
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
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                : ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3D4CD6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Login',
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
                                "Don't have an account? ",
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF707070)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignupScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Create an account',
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
                              Expanded(child: Divider(color: Color(0xFFF0F0F0))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                      fontSize: 14, color: Color(0xFF707070)),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0xFFF0F0F0))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SocialLoginButton(
                                  imagePath: 'assets/icons/google.png'),
                              const SizedBox(width: 16),
                              SocialLoginButton(
                                  imagePath: 'assets/icons/facebook.png'),
                              const SizedBox(width: 16),
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