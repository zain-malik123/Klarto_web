import 'dart:ui';
import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: BackgroundOrnaments()),
        // The actual content
        Positioned.fill(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class BackgroundOrnaments extends StatelessWidget {
  const BackgroundOrnaments({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // References from signin.html which uses a 720x800 container
        double rx(double x) => (x / 720.0) * w;
        double ry(double y) => (y / 800.0) * h;

        return Stack(
          children: [
            // Background color
            Positioned.fill(
              child: Container(color: Colors.white),
            ),

            // 1. .img (Top Left - Dot Grid)
            Positioned(
              top: ry(77), // 50% - 323px on 800px height
              left: rx(75), // 50% - 285px on 720px width
              child: CustomPaint(
                size: Size(rx(141), ry(154)),
                painter: _DotGridPainter(),
              ),
            ),

            // 2. .ornament (Bottom Middle - Bars)
            Positioned(
              top: ry(635),
              left: rx(355),
              child: CustomPaint(
                size: Size(rx(162), ry(132)),
                painter: _BarsPainter(),
              ),
            ),

            // 3. .vector (Top Right - Half Ellipse)
            Positioned(
              top: ry(121.44), // 15.18%
              left: rx(559.51), // 77.71%
              child: CustomPaint(
                size: Size(rx(78.98), ry(164.0)),
                painter: _EllipsePainter(color: const Color(0xFFD1D4F5), isRightSide: true),
              ),
            ),

            // 4. .vector-2 (Bottom Left - Half Ellipse)
            Positioned(
              top: ry(514.48), // 64.31%
              left: rx(80.50), // 11.18%
              child: CustomPaint(
                size: Size(rx(78.98), ry(164.0)),
                painter: _EllipsePainter(color: const Color(0xFFD1D4F5), isRightSide: false),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3D4CD6).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    const int cols = 11;
    const int rows = 12;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Spacing based on 141x154 viewBox
        double dx = (c * 13.645 + 2.27) * (size.width / 141);
        double dy = (r * 13.59 + 2.26) * (size.height / 154);
        canvas.drawCircle(Offset(dx, dy), 2.25 * (size.width / 141), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3D4CD6).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Heights from SVG path (rough estimates but match the look)
    final barHeights = [
      18.8, 37.7, 56.5, 75.4, 94.2, 113.1, 132.0, 113.1, 94.2, 75.4, 56.5, 37.7, 18.8
    ];
    final barXOffsets = [
      1.8, 15.0, 28.2, 41.4, 54.6, 67.8, 81.0, 94.1, 107.3, 120.5, 133.7, 146.9, 160.1
    ];

    for (int i = 0; i < barHeights.length; i++) {
      double w = 3.76 * (size.width / 162);
      double h = barHeights[i] * (size.height / 132);
      double x = (barXOffsets[i] - 1.88) * (size.width / 162);
      double y = size.height - h; // Ground bars at the bottom of the ornament area
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          Radius.circular(w / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _EllipsePainter extends CustomPainter {
  final Color color;
  final bool isRightSide;

  _EllipsePainter({required this.color, required this.isRightSide});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (isRightSide) {
      // Matches signin.html .vector outline
      path.moveTo(0, 0);
      path.cubicTo(w * 0.55, h * 0.01, w, h * 0.23, w, h * 0.5);
      path.cubicTo(w, h * 0.77, w * 0.55, h * 0.99, 0, h);
    } else {
      // Matches signin.html .vector-2 outline (flipped)
      path.moveTo(w, 0);
      path.cubicTo(w * 0.45, h * 0.01, 0, h * 0.23, 0, h * 0.5);
      path.cubicTo(0, h * 0.77, w * 0.45, h * 0.99, w, h);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
