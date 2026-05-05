import 'package:flutter/material.dart';

class OrganicHeader extends StatelessWidget {
  final Widget child;
  final double height;

  const OrganicHeader({
    super.key,
    required this.child,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HeaderPainter(
                primaryColor: const Color(0xFF005B71),
                darkColor: const Color(0xFF0D3A26),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color darkColor;

  _HeaderPainter({required this.primaryColor, required this.darkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBase = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final paintDark = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // Draw main green background with a wavy bottom
    final pathBase = Path();
    pathBase.lineTo(0, size.height - 40);
    pathBase.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 20);
    pathBase.quadraticBezierTo(
        size.width * 0.75, size.height - 40, size.width, size.height);
    pathBase.lineTo(size.width, 0);
    pathBase.close();
    canvas.drawPath(pathBase, paintBase);

    // Draw dark green organic blob on the top right
    final pathDarkTopRight = Path();
    pathDarkTopRight.moveTo(size.width * 0.4, 0);
    pathDarkTopRight.quadraticBezierTo(
        size.width * 0.5, size.height * 0.3, size.width, size.height * 0.4);
    pathDarkTopRight.lineTo(size.width, 0);
    pathDarkTopRight.close();
    canvas.drawPath(pathDarkTopRight, paintDark);

    // Draw dark green blob on top left
    final pathDarkTopLeft = Path();
    pathDarkTopLeft.moveTo(0, size.height * 0.2);
    pathDarkTopLeft.quadraticBezierTo(
        size.width * 0.2, size.height * 0.4, size.width * 0.3, 0);
    pathDarkTopLeft.lineTo(0, 0);
    pathDarkTopLeft.close();
    canvas.drawPath(pathDarkTopLeft, paintDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
