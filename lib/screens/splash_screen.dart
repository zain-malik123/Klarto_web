import 'package:flutter/material.dart';
import 'package:klarto/screens/login_screen.dart';
import 'package:klarto/screens/reset_password_confirm_screen.dart';
import 'package:klarto/screens/accept_invite_screen.dart';
import 'package:klarto/apis/auth_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klarto/apis/user_api_service.dart';
import 'package:klarto/screens/main_app_shell.dart';
import 'package:klarto/screens/onboarding/onboarding_screen.dart';

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
    } else if (uri.path.contains('/accept-invite') && uri.queryParameters.containsKey('token')) {
      final token = uri.queryParameters['token']!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AcceptInviteScreen(token: token)),
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
      // If there's a stored JWT, validate it and go to the app instead of login.
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null && token.isNotEmpty) {
          final userApi = UserApiService();
          final profile = await userApi.getProfile();
          if (profile['success'] == true) {
            if (!mounted) return;
            final bool onboarded = profile['has_completed_onboarding'] == true;
            if (onboarded) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MainAppShell()));
            } else {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => OnboardingScreen()));
            }
            return;
          }
        }
      } catch (_) {}

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