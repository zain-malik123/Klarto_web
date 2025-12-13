import 'package:flutter/material.dart';
import 'package:klarto/apis/auth_api_service.dart';
import 'package:klarto/screens/login_screen.dart';
import 'package:klarto/widgets/auth_branding_panel.dart';
import 'package:klarto/widgets/custom_text_field.dart';

class ResetPasswordConfirmScreen extends StatefulWidget {
  final String token;
  const ResetPasswordConfirmScreen({super.key, required this.token});

  @override
  State<ResetPasswordConfirmScreen> createState() =>
      _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState
    extends State<ResetPasswordConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authApiService.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Password reset successfully!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF3D4CD6),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${result['message']}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF3D4CD6),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect to the server.',
              style: TextStyle(color: Colors.white)),
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
          const AuthBrandingPanel(),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Set a New Password',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF383838),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your new password must be different from previously used passwords.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF707070),
                              ),
                            ),
                            const SizedBox(height: 32),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'New Password',
                              hint: 'Enter your new password',
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
                                  return 'Please enter a new password.';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters long.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm New Password',
                              hint: 'Confirm your new password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isPasswordVisible: _isConfirmPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your new password.';
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
                                          color: Colors.white))
                                  : ElevatedButton(
                                      onPressed: _handleResetPassword,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF3D4CD6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Reset Password',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginScreen()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              child: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3D4CD6),
                                  decoration: TextDecoration.none,
                                ),
                              ),
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