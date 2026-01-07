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