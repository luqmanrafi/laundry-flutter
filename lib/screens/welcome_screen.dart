import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // Background Blobs
          Positioned.fill(
            child: CustomPaint(
              painter: _WelcomeBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppLogo(size: 120, color: Colors.white),
                      const SizedBox(height: 40),
                      const Text(
                        'Laundry App',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Get ready to make your life easy with single click of app, which makes laundry things handle better.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 60),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DAAC8), // Vibrant Orange
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          minimumSize: const Size(200, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text(
                          'GET STARTED',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLightGreen = Paint()
      ..color = const Color(0xFF1E7A4E).withAlpha(100) // Slightly lighter green
      ..style = PaintingStyle.fill;

    // Bottom left blob
    final pathBottomLeft = Path();
    pathBottomLeft.moveTo(0, size.height * 0.75);
    pathBottomLeft.quadraticBezierTo(
        size.width * 0.3, size.height * 0.8, size.width * 0.4, size.height);
    pathBottomLeft.lineTo(0, size.height);
    pathBottomLeft.close();
    canvas.drawPath(pathBottomLeft, paintLightGreen);

    // Top right blob
    final pathTopRight = Path();
    pathTopRight.moveTo(size.width * 0.6, 0);
    pathTopRight.quadraticBezierTo(
        size.width * 0.8, size.height * 0.2, size.width, size.height * 0.25);
    pathTopRight.lineTo(size.width, 0);
    pathTopRight.close();
    canvas.drawPath(pathTopRight, paintLightGreen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
