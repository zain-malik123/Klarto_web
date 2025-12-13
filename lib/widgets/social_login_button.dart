import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String imagePath;
  const SocialLoginButton({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF9F9F9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Image.asset(
          imagePath,
          width: 18,
          height: 18,
        ),
      ),
    );
  }
}
