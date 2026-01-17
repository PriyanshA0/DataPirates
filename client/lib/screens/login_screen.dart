import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const LoginScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'appName': 'SwasthSetu',
      'secureAccess': 'Secure Health Access',
      'welcomeBack': 'Welcome Back',
      'subtitle':
          'Your health journey continues here. Log in to view your latest analytics.',
      'emailOrPhone': 'Email or Phone',
      'emailHint': 'user@example.com',
      'password': 'Password',
      'passwordHint': '••••••••',
      'logInButton': 'Log In',
      'noAccount': "Don't have an account? ",
      'register': 'Register',
      'bycontinuing': 'By continuing, you agree to our ',
      'termsOfService': 'Terms of Service',
      'and': ' and ',
      'privacyPolicy': 'Privacy Policy',
      'loginSuccess': 'Login successful!',
    },
    'Hindi': {
      'appName': 'वाइटलसिंक',
      'secureAccess': 'सुरक्षित स्वास्थ्य पहुंच',
      'welcomeBack': 'वापस स्वागत है',
      'subtitle':
          'आपकी स्वास्थ्य यात्रा यहां जारी है। अपने नवीनतम विश्लेषण देखने के लिए लॉग इन करें।',
      'emailOrPhone': 'ईमेल या फोन',
      'emailHint': 'user@example.com',
      'password': 'पासवर्ड',
      'passwordHint': '••••••••',
      'logInButton': 'लॉग इन करें',
      'noAccount': 'खाता नहीं है? ',
      'register': 'रजिस्टर करें',
      'bycontinuing': 'जारी रखकर, आप हमारी ',
      'termsOfService': 'सेवा की शर्तें',
      'and': ' और ',
      'privacyPolicy': 'गोपनीयता नीति',
      'loginSuccess': 'लॉगिन सफल!',
    },
    'Marathi': {
      'appName': 'व्हायटलसिंक',
      'secureAccess': 'सुरक्षित आरोग्य प्रवेश',
      'welcomeBack': 'परत स्वागत आहे',
      'subtitle':
          'तुमचा आरोग्य प्रवास येथे सुरू आहे. तुमचे नवीनतम विश्लेषण पाहण्यासाठी लॉग इन करा.',
      'emailOrPhone': 'ईमेल किंवा फोन',
      'emailHint': 'user@example.com',
      'password': 'पासवर्ड',
      'passwordHint': '••••••••',
      'logInButton': 'लॉग इन करा',
      'noAccount': 'खाते नाही? ',
      'register': 'नोंदणी करा',
      'bycontinuing': 'सुरू ठेवून, तुम्ही आमच्या ',
      'termsOfService': 'सेवा अटी',
      'and': ' आणि ',
      'privacyPolicy': 'गोपनीयता धोरण',
      'loginSuccess': 'लॉगिन यशस्वी!',
    },
  };

  String _translate(String key) =>
      _translations[widget.currentLanguage]?[key] ?? key;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        // Save user name from the response
        final userName = result['data']?['user']?['name'] ?? 'User';
        await prefs.setString('userName', userName);

        _showSnackBar(_translate('loginSuccess'), isError: false);

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          }
        });
      } else {
        _showSnackBar(
          result['message'] ?? "Invalid credentials",
          isError: true,
        );
      }
    } catch (e) {
      if (kDebugMode) print("Login Error: $e");
      _showSnackBar("Connection error. Check backend.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF45A191),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF22262A)
          : const Color(0xFFF1F2F4),
      body: Stack(
        children: [
          Positioned(
            bottom: -130,
            right: -130,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: const Color(0xFF45A191).withOpacity(isDark ? 0.05 : 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF45A191).withOpacity(0.1),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -80,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(isDark ? 0.05 : 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),
                            _buildHeroBanner(isDark),
                            const SizedBox(height: 32),
                            _buildTitle(isDark),
                            const SizedBox(height: 32),
                            _buildLoginForm(isDark),
                            const SizedBox(height: 32),
                            _buildRegisterLink(isDark),
                            const SizedBox(height: 32),
                            _buildTermsAndPrivacy(isDark),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C3136) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(20, 20),
                    painter: HeartECGIconPainter(const Color(0xFF45A191)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _translate('appName'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Row(
            children: [
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.language,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                ),
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? const Color(0xFF2C3136) : Colors.white,
                onSelected: widget.onLanguageChange,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  _buildPopupMenuItem('English', 'English', isDark),
                  _buildPopupMenuItem('Hindi', 'हिंदी', isDark),
                  _buildPopupMenuItem('Marathi', 'मराठी', isDark),
                ],
              ),
              IconButton(
                onPressed: widget.onThemeToggle,
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    String label,
    bool isDark,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (widget.currentLanguage == value)
            const Icon(Icons.check, color: Color(0xFF45A191), size: 20)
          else
            const SizedBox(width: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF131615),
              fontWeight: widget.currentLanguage == value
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(bool isDark) {
    return Container(
      height: 128,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF4A4458),
                            const Color(0xFF3D3550),
                            const Color(0xFF574762),
                            const Color(0xFF6B4F75),
                          ]
                        : [
                            const Color(0xFF6B5B7C),
                            const Color(0xFF7B6684),
                            const Color(0xFF9B7B9E),
                            const Color(0xFFB897B5),
                          ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      const Color(0xFFE88FB1).withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.3 : 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: Color(0xFF45A191),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _translate('secureAccess'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF45A191)
                                : const Color(0xFF368275),
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
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _translate('welcomeBack'),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF131615),
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _translate('subtitle'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : const Color(0xFF6C7F7C),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3136) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              label: _translate('emailOrPhone'),
              controller: _emailController,
              icon: Icons.email,
              placeholder: _translate('emailHint'),
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              label: _translate('password'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              placeholder: _translate('passwordHint'),
              isDark: isDark,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF45A191),
                  foregroundColor: const Color(0xFF131615),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _translate('logInButton'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String placeholder,
    TextInputType? keyboardType,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[200] : const Color(0xFF131615),
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF22262A) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
              width: 2,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: const Color(0xFF6C7F7C).withOpacity(0.6),
              ),
              prefixIcon: Icon(
                icon,
                color: isDark ? Colors.grey[500] : const Color(0xFF6C7F7C),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String placeholder,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[200] : const Color(0xFF131615),
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF22262A) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
              width: 2,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: const Color(0xFF6C7F7C).withOpacity(0.6),
              ),
              prefixIcon: Icon(
                Icons.lock,
                color: isDark ? Colors.grey[500] : const Color(0xFF6C7F7C),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.grey[500] : const Color(0xFF6C7F7C),
                ),
                onPressed: onToggleVisibility,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink(bool isDark) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: _translate('noAccount'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : const Color(0xFF6C7F7C),
          ),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Text(
                  _translate('register'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF45A191),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndPrivacy(bool isDark) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: _translate('bycontinuing'),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : const Color(0xFF6C7F7C),
          ),
          children: [
            TextSpan(
              text: _translate('termsOfService'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF45A191),
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(text: _translate('and')),
            TextSpan(
              text: _translate('privacyPolicy'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF45A191),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
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
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final ecgPath = Path();
    final baseY = h * 0.52;
    final amplitude = h * 0.2;
    ecgPath.moveTo(w * 0.08, baseY);
    ecgPath.lineTo(w * 0.18, baseY);
    ecgPath.lineTo(w * 0.22, baseY - amplitude * 0.3);
    ecgPath.lineTo(w * 0.26, baseY);
    ecgPath.lineTo(w * 0.36, baseY + amplitude * 0.25);
    ecgPath.lineTo(w * 0.42, baseY - amplitude * 0.9);
    ecgPath.lineTo(w * 0.48, baseY + amplitude * 0.35);
    ecgPath.lineTo(w * 0.52, baseY);
    ecgPath.lineTo(w * 0.66, baseY - amplitude * 0.5);
    ecgPath.lineTo(w * 0.72, baseY);
    ecgPath.lineTo(w * 0.92, baseY);
    canvas.drawPath(ecgPath, ecgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
