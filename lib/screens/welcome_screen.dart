import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
   
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
         
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
                     
                      Image.asset(
                        'assets/images/LogoPutih.png', 
                        height: 350,
                        width: 350,
                        fit: BoxFit.contain, 
                      ),

                      
                      const SizedBox(height: 2),
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

                     
                      Column(
                        children: [
                          // TOMBOL SIGN UP
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2DAAC8), // Warna biru cerah
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56), // Lebar penuh
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () => Navigator.pushNamed(context, '/signup'),
                            child: const Text(
                              'CREATE ACCOUNT',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          // TOMBOL SIGN IN 
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.5), 
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            child: const Text(
                              'SIGN IN',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                        ],
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
      ..color = const Color(0xFFF1F5F9)
      // ..color = const Color(0xFF1E7A4E).withAlpha(100)// Slightly lighter green
      
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
