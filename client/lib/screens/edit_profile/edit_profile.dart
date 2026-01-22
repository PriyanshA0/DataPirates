import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Allow Google Fonts to use system fonts when offline
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const PersonalDataApp());
}

class PersonalDataApp extends StatefulWidget {
  const PersonalDataApp({super.key});

  @override
  State<PersonalDataApp> createState() => _PersonalDataAppState();
}

class _PersonalDataAppState extends State<PersonalDataApp> {
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'English';

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _language = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Data',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.manropeTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF45A191),
          primary: const Color(0xFF45A191),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F2F4),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF45A191),
          primary: const Color(0xFF45A191),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1C1E),
      ),
      themeMode: _themeMode,
      home: PersonalDataScreen(
        onThemeToggle: _toggleTheme,
        onLanguageChange: _changeLanguage,
        currentLanguage: _language,
      ),
    );
  }
}

class PersonalDataScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const PersonalDataScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final int _selectedIndex = 4; // Profile tab
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _mobileController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final result = await ApiService.getUserProfile();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      setState(() {
        _nameController.text = data['name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _mobileController.text = data['mobile'] ?? '';
        _heightController.text = data['height'] != null
            ? '${data['height']} cm'
            : '';
        _weightController.text = data['weight'] != null
            ? '${data['weight']} kg'
            : '';
        _emailController.text = data['email'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // Parse height and weight (remove units)
    final heightText = _heightController.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    final weightText = _weightController.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );

    final result = await ApiService.updateUserProfile(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      age: _ageController.text.isNotEmpty
          ? int.tryParse(_ageController.text)
          : null,
      height: heightText.isNotEmpty ? double.tryParse(heightText) : null,
      weight: weightText.isNotEmpty ? double.tryParse(weightText) : null,
      mobile: _mobileController.text.isNotEmpty ? _mobileController.text : null,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success'] == true
                ? 'Profile updated successfully!'
                : result['message'] ?? 'Failed to update profile',
          ),
          backgroundColor: result['success'] == true
              ? const Color(0xFF45A191)
              : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'personalData': 'Personal Data',
      'updateDetails':
          'Update your personal details for more accurate health tracking',
      'fullName': 'Full Name',
      'age': 'Age',
      'mobileNumber': 'Mobile Number',
      'height': 'Height',
      'weight': 'Weight',
      'emailAddress': 'Email Address (Non-editable)',
      'saveChanges': 'Save Changes',
      'logout': 'Logout',
      'home': 'Home',
      'analytics': 'Analytics',
      'aiSummary': 'AI Summary',
      'history': 'History',
      'profile': 'Profile',
    },
    'Hindi': {
      'personalData': 'व्यक्तिगत डेटा',
      'updateDetails':
          'अधिक सटीक स्वास्थ्य ट्रैकिंग के लिए अपना विवरण अपडेट करें',
      'fullName': 'पूरा नाम',
      'age': 'उम्र',
      'mobileNumber': 'मोबाइल नंबर',
      'height': 'ऊंचाई',
      'weight': 'वजन',
      'emailAddress': 'ईमेल पता (संपादन योग्य नहीं)',
      'saveChanges': 'परिवर्तन सहेजें',
      'logout': 'लॉगआउट',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफ़ाइल',
    },
    'Marathi': {
      'personalData': 'वैयक्तिक डेटा',
      'updateDetails': 'अधिक अचूक आरोग्य ट्रॅकिंगसाठी तुमचे तपशील अपडेट करा',
      'fullName': 'पूर्ण नाव',
      'age': 'वय',
      'mobileNumber': 'मोबाइल नंबर',
      'height': 'उंची',
      'weight': 'वजन',
      'emailAddress': 'ईमेल पत्ता (संपादन करण्यायोग्य नाही)',
      'saveChanges': 'बदल जतन करा',
      'logout': 'लॉगआउट',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफाइल',
    },
  };

  String _translate(String key) {
    return _translations[widget.currentLanguage]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A1C1E)
          : const Color(0xFFF1F2F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF45A191),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildProfileSection(isDark),
                          const SizedBox(height: 32),
                          _buildFormSection(isDark),
                          const SizedBox(height: 32),
                          _buildButtons(isDark),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF1F2F4))
            .withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: isDark
                          ? Colors.grey.shade300
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _translate('personalData'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF131615),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? const Color(0xFF2C3136) : Colors.white,
                onSelected: (String language) =>
                    widget.onLanguageChange(language),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  _buildLanguageMenuItem('English', 'English', isDark),
                  _buildLanguageMenuItem('Hindi', 'हिंदी', isDark),
                  _buildLanguageMenuItem('Marathi', 'मराठी', isDark),
                ],
                child: _buildHeaderButton(
                  icon: Icons.language,
                  isDark: isDark,
                  onTap: null,
                ),
              ),
              const SizedBox(width: 4),
              _buildHeaderButton(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                isDark: isDark,
                onTap: widget.onThemeToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildLanguageMenuItem(
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
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: widget.currentLanguage == value
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDark ? Colors.grey.shade300 : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF45A191).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF3F4549)
                      : const Color(0xFFE5E7EB),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuB3tixK1ZF8ATdgor-ygW2XP4lLEQvbyK9ZGMxG28Tn4BwIuIHwqelC1OyyXSXYMwza9lVn6TuCL1jKmqPp4saXI4sQGn_u7gQgY2HkfZgPkPNnIBffiQtVZZe-TlDlFOHrP7zH85lqGqDN9_KUDvYR8UHnTWsr6ipEm-8ajY9BHHc_GN84SyGv63YBYrPYHOJsM3BHt4_gOiSMQBzmmqaj-90Yl_V3DxlYT7fmE3P1sYhUaeXlMG98iWd3C1AZYr5SsLpKMuXzUByr',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF45A191),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_camera,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _translate('updateDetails'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormSection(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: _translate('fullName'),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _ageController,
                label: _translate('age'),
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildTextField(
                controller: _mobileController,
                label: _translate('mobileNumber'),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _heightController,
                label: _translate('height'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildTextField(
                controller: _weightController,
                label: _translate('weight'),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          label: _translate('emailAddress'),
          isDark: isDark,
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 16,
          color: enabled
              ? (isDark ? Colors.white : const Color(0xFF0F172A))
              : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
          floatingLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF45A191),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF),
              width: 2,
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF45A191), width: 2),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
              width: 2,
            ),
          ),
          filled: !enabled,
          fillColor: !enabled
              ? (isDark
                    ? const Color(0xFF1F2937).withOpacity(0.3)
                    : const Color(0xFFF9FAFB).withOpacity(0.5))
              : Colors.transparent,
          contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        ),
      ),
    );
  }

  Widget _buildButtons(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF45A191),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFF45A191).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _translate('saveChanges'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFD1D5DB),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, size: 20),
                const SizedBox(width: 8),
                Text(
                  _translate('logout'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C3136).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF3F4549) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.only(bottom: 20, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: _translate('home'),
                index: 0,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.analytics_outlined,
                label: _translate('analytics'),
                index: 1,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.auto_awesome,
                label: _translate('aiSummary'),
                index: 2,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.history,
                label: _translate('history'),
                index: 3,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.person,
                label: _translate('profile'),
                index: 4,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == _selectedIndex) return;

        // Navigate based on index
        switch (index) {
          case 0: // Home
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
            break;
          case 1: // Analytics
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/analytics',
              (route) => false,
            );
            break;
          case 2: // AI Summary
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/ai-summary',
              (route) => false,
            );
            break;
          case 3: // History
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/history',
              (route) => false,
            );
            break;
          case 4: // Profile
            Navigator.pop(context); // Go back to profile
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF45A191).withOpacity(0.25)
                      : const Color(0xFF45A191).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 24, color: const Color(0xFF45A191)),
              )
            else
              SizedBox(
                height: 32,
                child: Icon(
                  icon,
                  size: 24,
                  color: isDark
                      ? const Color(0xFF6C7F7C)
                      : const Color(0xFF6B7280),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF45A191)
                    : isDark
                    ? const Color(0xFF6C7F7C)
                    : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
