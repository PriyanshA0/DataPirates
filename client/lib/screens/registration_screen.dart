import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import '../services/api_service.dart'; // Centralized API service
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const RegistrationScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController =
      TextEditingController(); // Note: Add 'phone' to your Node.js User model if needed
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _selectedGender;
  String _selectedDevice = 'WatchOS';

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'appName': 'SwasthSetu',
      'createAccount': 'Create Account',
      'subtitle': 'Connect your health data for deeper insights.',
      'fullName': 'Full Name',
      'fullNameHint': 'John Doe',
      'emailAddress': 'Email Address',
      'emailHint': 'john.doe@example.com',
      'phoneNumber': 'Phone Number',
      'phoneHint': '(555) 123-4567',
      'password': 'Password',
      'passwordHint': 'Create a password',
      'confirmPassword': 'Confirm Password',
      'confirmPasswordHint': 'Confirm your password',
      'age': 'Age',
      'ageHint': '25',
      'gender': 'Gender',
      'genderSelect': 'Select',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'height': 'Height (cm)',
      'heightHint': '175',
      'weight': 'Weight (kg)',
      'weightHint': '70',
      'selectDevice': 'Select Wearable Device',
      'createAccountButton': 'Create Account',
      'alreadyAccount': 'Already have an account? ',
      'login': 'Login',
      'termsText': 'By creating an account, you agree to our ',
      'terms': 'Terms',
      'and': ' and ',
      'privacy': 'Privacy',
      'accountCreated': 'Account created successfully!',
    },
    'Hindi': {
      'appName': 'वाइटलसिंक',
      'createAccount': 'खाता बनाएं',
      'subtitle': 'गहरी जानकारी के लिए अपना स्वास्थ्य डेटा कनेक्ट करें।',
      'fullName': 'पूरा नाम',
      'fullNameHint': 'जॉन डो',
      'emailAddress': 'ईमेल पता',
      'emailHint': 'john.doe@example.com',
      'phoneNumber': 'फ़ोन नंबर',
      'phoneHint': '(555) 123-4567',
      'password': 'पासवर्ड',
      'passwordHint': 'पासवर्ड बनाएं',
      'confirmPassword': 'पासवर्ड की पुष्टि करें',
      'confirmPasswordHint': 'अपने पासवर्ड की पुष्टि करें',
      'age': 'उम्र',
      'ageHint': '25',
      'gender': 'लिंग',
      'genderSelect': 'चुनें',
      'male': 'पुरुष',
      'female': 'महिला',
      'other': 'अन्य',
      'height': 'ऊंचाई (सेमी)',
      'heightHint': '175',
      'weight': 'वजन (किग्रा)',
      'weightHint': '70',
      'selectDevice': 'पहनने योग्य डिवाइस चुनें',
      'createAccountButton': 'खाता बनाएं',
      'alreadyAccount': 'पहले से खाता है? ',
      'login': 'लॉगिन',
      'termsText': 'खाता बनाकर, आप हमारी ',
      'terms': 'शर्तें',
      'and': ' और ',
      'privacy': 'गोपनीयता',
      'accountCreated': 'खाता सफलतापूर्वक बनाया गया!',
    },
    'Marathi': {
      'appName': 'व्हायटलसिंक',
      'createAccount': 'खाते तयार करा',
      'subtitle': 'सखोल माहितीसाठी तुमचा आरोग्य डेटा कनेक्ट करा.',
      'fullName': 'पूर्ण नाव',
      'fullNameHint': 'जॉन डो',
      'emailAddress': 'ईमेल पत्ता',
      'emailHint': 'john.doe@example.com',
      'phoneNumber': 'फोन नंबर',
      'phoneHint': '(555) 123-4567',
      'password': 'पासवर्ड',
      'passwordHint': 'पासवर्ड तयार करा',
      'confirmPassword': 'पासवर्डची पुष्टी करा',
      'confirmPasswordHint': 'तुमच्या पासवर्डची पुष्टी करा',
      'age': 'वय',
      'ageHint': '25',
      'gender': 'लिंग',
      'genderSelect': 'निवडा',
      'male': 'पुरुष',
      'female': 'स्त्री',
      'other': 'इतर',
      'height': 'उंची (सेमी)',
      'heightHint': '175',
      'weight': 'वजन (किलो)',
      'weightHint': '70',
      'selectDevice': 'वेअरेबल डिव्हाइस निवडा',
      'createAccountButton': 'खाते तयार करा',
      'alreadyAccount': 'आधीपासून खाते आहे? ',
      'login': 'लॉगिन',
      'termsText': 'खाते तयार करून, तुम्ही आमच्या ',
      'terms': 'अटी',
      'and': ' आणि ',
      'privacy': 'गोपनीयता',
      'accountCreated': 'खाते यशस्वीरित्या तयार केले!',
    },
  };

  String _translate(String key) {
    return _translations[widget.currentLanguage]?[key] ?? key;
  }

  // Registration Logic integrated with your Node/Express backend
  Future<void> _handleRegistration() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) return;

    // 2. Validate Password Match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Passwords do not match!", isError: true);
      return;
    }

    // 3. Start Loading
    setState(() => _isLoading = true);

    // DEBUG: Only for Developer
    if (kDebugMode) {
      print("--- STARTING REGISTRATION ---");
      print("Sending data to backend...");
      print("Name: ${_nameController.text.trim()}");
      print("Email: ${_emailController.text.trim()}");
    }

    try {
      // 4. Call centralized ApiService
      final result = await ApiService.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
      );

      // DEBUG: Response check
      if (kDebugMode) {
        print("Backend Response: $result");
      }

      if (result['success']) {
        // Save user info to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        // Save user name from the response
        final userName =
            result['data']?['user']?['name'] ?? _nameController.text.trim();
        await prefs.setString('userName', userName);

        _showSnackBar(_translate('accountCreated'), isError: false);

        // Navigate to dashboard after registration
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          }
        });
      } else {
        // Show server-side error (e.g., "User already exists")
        _showSnackBar(
          result['message'] ?? "Registration failed",
          isError: true,
        );
      }
    } catch (e) {
      // DEBUG: Log actual exception
      if (kDebugMode) {
        print("FATAL ERROR: $e");
      }
      _showSnackBar("Connection error. Is the server running?", isError: true);
    } finally {
      // 5. STOP LOADING: Always stop the wheel even if error occurs
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (kDebugMode) {
        print("--- REGISTRATION FLOW FINISHED ---");
      }
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
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
          // Decorative blurred circles
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildTitle(isDark),
                            const SizedBox(height: 24),
                            _buildForm(isDark),
                            const SizedBox(height: 24),
                            _buildLoginLink(isDark),
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

  Widget _buildTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _translate('createAccount'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF131615),
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _translate('subtitle'),
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

  Widget _buildForm(bool isDark) {
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
              label: _translate('fullName'),
              controller: _nameController,
              icon: Icons.person,
              placeholder: _translate('fullNameHint'),
              isDark: isDark,
              validator: (value) => value!.isEmpty ? "Enter your name" : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: _translate('emailAddress'),
              controller: _emailController,
              icon: Icons.email,
              placeholder: _translate('emailHint'),
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              validator: (value) =>
                  !value!.contains('@') ? "Enter a valid email" : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: _translate('phoneNumber'),
              controller: _phoneController,
              icon: Icons.phone,
              placeholder: _translate('phoneHint'),
              keyboardType: TextInputType.phone,
              isDark: isDark,
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
              validator: (value) =>
                  value!.length < 6 ? "Minimum 6 characters" : null,
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              label: _translate('confirmPassword'),
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              placeholder: _translate('confirmPasswordHint'),
              icon: Icons.lock_reset,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: _translate('age'),
                    controller: _ageController,
                    placeholder: _translate('ageHint'),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildDropdownField(
                    label: _translate('gender'),
                    value: _selectedGender,
                    items: [
                      _translate('male'),
                      _translate('female'),
                      _translate('other'),
                    ],
                    itemValues: const ['Male', 'Female', 'Other'],
                    onChanged: (value) =>
                        setState(() => _selectedGender = value),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: _translate('height'),
                    controller: _heightController,
                    icon: Icons.height,
                    placeholder: _translate('heightHint'),
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: _translate('weight'),
                    controller: _weightController,
                    icon: Icons.monitor_weight,
                    placeholder: _translate('weightHint'),
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildWearableDeviceSelector(isDark),
            const SizedBox(height: 20),
            _buildCreateAccountButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    required String placeholder,
    TextInputType? keyboardType,
    TextAlign? textAlign,
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
            textAlign: textAlign ?? TextAlign.start,
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
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: isDark
                          ? Colors.grey[500]
                          : const Color(0xFF6C7F7C),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: icon != null
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                  : const EdgeInsets.all(16),
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
    IconData? icon,
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
                icon ?? Icons.lock,
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required List<String> itemValues,
    required Function(String?) onChanged,
    required bool isDark,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                _translate('genderSelect'),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF131615),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: isDark ? Colors.grey[500] : const Color(0xFF6C7F7C),
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF131615),
              ),
              dropdownColor: isDark ? const Color(0xFF2C3136) : Colors.white,
              items: List.generate(items.length, (index) {
                return DropdownMenuItem<String>(
                  value: itemValues[index],
                  child: Text(items[index]),
                );
              }),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWearableDeviceSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.watch, color: Color(0xFF45A191), size: 18),
              const SizedBox(width: 8),
              Text(
                _translate('selectDevice'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[200] : const Color(0xFF131615),
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildDeviceOption('WatchOS', Icons.watch_off, 'WatchOS', isDark),
            _buildDeviceOption('Fitbit', Icons.monitor_heart, 'Fitbit', isDark),
            _buildDeviceOption(
              'Garmin',
              Icons.directions_run,
              'Garmin',
              isDark,
            ),
            _buildDeviceOption('Other', Icons.devices_other, 'Other', isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceOption(
    String name,
    IconData icon,
    String value,
    bool isDark,
  ) {
    final isSelected = _selectedDevice == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDevice = value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF45A191).withOpacity(0.1)
              : (isDark ? const Color(0xFF22262A) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF45A191)
                : (isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB)),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF131615))
                        : const Color(0xFF6C7F7C),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF131615))
                          : const Color(0xFF6C7F7C),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF45A191),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegistration,
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
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _translate('createAccountButton'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink(bool isDark) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: _translate('alreadyAccount'),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[500] : const Color(0xFF6C7F7C),
          ),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: Text(
                  _translate('login'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF45A191),
                    decoration: TextDecoration.underline,
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
          text: _translate('termsText'),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : const Color(0xFF6C7F7C),
          ),
          children: [
            TextSpan(
              text: _translate('terms'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF45A191),
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(text: _translate('and')),
            TextSpan(
              text: _translate('privacy'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF45A191),
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(text: '.'),
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
