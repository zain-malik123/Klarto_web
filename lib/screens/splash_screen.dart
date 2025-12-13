import 'package:flutter/material.dart';
import 'package:klarto/screens/login_screen.dart';
import 'package:klarto/screens/reset_password_confirm_screen.dart';
import 'package:klarto/apis/auth_api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthApiService _authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the context is available
    // and to check the URL after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleRouting());
  }

  void _handleRouting() async {
    final uri = Uri.base; // Gets the full browser URL

    if (uri.path.contains('/reset-password-confirm') && uri.queryParameters.containsKey('token')) {
      final token = uri.queryParameters['token']!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ResetPasswordConfirmScreen(token: token)),
      );
    } else if (uri.path.contains('/verify-email') && uri.queryParameters.containsKey('token')) {
      final token = uri.queryParameters['token']!;
      final result = await _authApiService.verifyEmail(token: token);
      final status = result['success'] == true ? 'success' : 'failed';

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(queryParams: {'verification': status}),
        ),
      );
    } else {
      // Default to login screen, passing along any query parameters
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen(queryParams: uri.queryParameters)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple loading indicator while the routing is being determined.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}