import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:klarto/config.dart';
import 'package:klarto/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Set Stripe publishable key
  // On web, we must ensure we don't trigger dart:io Platform checks
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? AppConfig.stripePublishableKey;
  
  if (!kIsWeb) {
    // Additional mobile-specific Stripe setup could go here
    // e.g. Stripe.instance.applySettings();
  }

  runApp(const KlartoApp());
}

class KlartoApp extends StatelessWidget {
  const KlartoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klarto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}