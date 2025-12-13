import 'package:flutter/material.dart';
import 'package:klarto/widgets/feature_tile.dart';

class AuthBrandingPanel extends StatelessWidget {
  const AuthBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                        color: Colors.white,
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
    );
  }
}