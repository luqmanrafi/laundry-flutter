import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // The exact blue color from the uploaded image
    final logoColor = color ?? const Color(0xFF1668B8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Tilted washing machine
            Transform.rotate(
              angle: -0.25,
              child: Icon(
                Icons.local_laundry_service_rounded,
                size: size,
                color: logoColor,
              ),
            ),
            // Splash/Bubbles to the right
            Positioned(
              right: -size * 0.45,
              bottom: size * 0.05,
              child: Transform.rotate(
                angle: 0.2,
                child: Icon(
                  Icons.water_drop_rounded,
                  size: size * 0.5,
                  color: logoColor,
                ),
              ),
            ),
            Positioned(
              right: -size * 0.2,
              top: -size * 0.1,
              child: Icon(
                Icons.bubble_chart,
                size: size * 0.4,
                color: logoColor,
              ),
            ),
            Positioned(
              left: -size * 0.1,
              top: -size * 0.1,
              child: Icon(
                Icons.bubble_chart_outlined,
                size: size * 0.25,
                color: logoColor,
              ),
            ),
          ],
        ),
        if (showText) ...[
          SizedBox(height: size * 0.25),
          Text(
            'Washweswos',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: size * 0.45,
              fontWeight: FontWeight.w900,
              color: logoColor,
              letterSpacing: -1.2,
            ),
          ),
          Text(
            'Laundry Services',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: size * 0.18,
              fontWeight: FontWeight.w400,
              color: logoColor.withAlpha(200),
            ),
          ),
        ]
      ],
    );
  }
}
