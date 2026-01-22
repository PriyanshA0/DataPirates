import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthTrackerSplashScreen extends StatefulWidget {
  const HealthTrackerSplashScreen({super.key});

  @override
  State<HealthTrackerSplashScreen> createState() =>
      _HealthTrackerSplashScreenState();
}

class _HealthTrackerSplashScreenState extends State<HealthTrackerSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Check login status and navigate after splash animation
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // Wait for splash animation to show (reduced from 3s to 2s)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _hasNavigated) return;

    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw Exception('SharedPreferences timeout'),
      );
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final String? token = prefs.getString('token');

      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;

      // Check both isLoggedIn flag AND token exists
      if (isLoggedIn && token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Clear any stale login state
        await prefs.setBool('isLoggedIn', false);
        Navigator.pushReplacementNamed(context, '/register');
      }
    } catch (e) {
      print('Splash navigation error: $e');
      // If any error, go to register screen
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.pushReplacementNamed(context, '/register');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF45a191);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF22262A) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            _buildLogo(primaryColor),
            const SizedBox(height: 40),
            Text(
              'SwasthSetu',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your vital insights, simplified.',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
            ),
            const Spacer(flex: 2),
            _buildLoadingBar(primaryColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(Color primaryColor) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.05,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(48),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(85, 85),
                painter: HeartECGIconPainter(primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBar(Color primaryColor) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 280,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.2 + (_animation.value * 0.8),
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HeartECGIconPainter extends CustomPainter {
  final Color color;
  HeartECGIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final w = size.width;
    final h = size.height;
    final heartPath = Path();
    heartPath.moveTo(w * 0.5, h * 0.88);
    heartPath.cubicTo(
      w * 0.08,
      h * 0.64,
      w * 0.08,
      h * 0.36,
      w * 0.22,
      h * 0.24,
    );
    heartPath.cubicTo(w * 0.32, h * 0.16, w * 0.44, h * 0.18, w * 0.5, h * 0.3);
    heartPath.cubicTo(
      w * 0.56,
      h * 0.18,
      w * 0.68,
      h * 0.16,
      w * 0.78,
      h * 0.24,
    );
    heartPath.cubicTo(
      w * 0.92,
      h * 0.36,
      w * 0.92,
      h * 0.64,
      w * 0.5,
      h * 0.88,
    );
    heartPath.close();
    canvas.drawPath(heartPath, paint);

    final ecgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final ecgPath = Path();
    final baseY = h * 0.52;
    ecgPath.moveTo(w * 0.1, baseY);
    ecgPath.lineTo(w * 0.3, baseY);
    ecgPath.lineTo(w * 0.4, baseY - (h * 0.2));
    ecgPath.lineTo(w * 0.5, baseY + (h * 0.2));
    ecgPath.lineTo(w * 0.6, baseY);
    ecgPath.lineTo(w * 0.9, baseY);
    canvas.drawPath(ecgPath, ecgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
