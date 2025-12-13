import 'package:flutter/material.dart';
import 'package:klarto/screens/splash_screen.dart';



void main() {
  runApp(const KlartoApp());
}

class KlartoApp extends StatelessWidget {
  const KlartoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klarto',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}