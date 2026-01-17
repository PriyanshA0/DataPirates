import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../edit_profile/edit_profile.dart';
import '../notification/notification_screen.dart';
import '../settings_page/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthProfileApp());
}

class HealthProfileApp extends StatefulWidget {
  const HealthProfileApp({super.key});

  @override
  State<HealthProfileApp> createState() => _HealthProfileAppState();
}

class _HealthProfileAppState extends State<HealthProfileApp> {
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
      title: 'Health Profile',
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
        scaffoldBackgroundColor: const Color(0xFF22262A),
      ),
      themeMode: _themeMode,
      home: ProfileScreen(
        onThemeToggle: _toggleTheme,
        onLanguageChange: _changeLanguage,
        currentLanguage: _language,
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const ProfileScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 4; // Profile tab
  bool _isLoading = true;
  String _userName = 'User';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final result = await ApiService.getUserProfile();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      setState(() {
        _userName = data['name'] ?? 'User';
        _userEmail = data['email'] ?? '';
        _isLoading = false;
      });
    } else {
      // Try to load from SharedPreferences as fallback
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('userName') ?? 'User';
        _isLoading = false;
      });
    }
  }

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'profile': 'Profile',
      'manageAccount': 'Manage Account',
      'notifications': 'Notifications',
      'settings': 'Settings',
      'signOut': 'Sign Out',
      'home': 'Home',
      'analytics': 'Analytics',
      'aiSummary': 'AI Summary',
      'history': 'History',
    },
    'Hindi': {
      'profile': 'प्रोफ़ाइल',
      'manageAccount': 'खाता प्रबंधित करें',
      'notifications': 'सूचनाएं',
      'settings': 'सेटिंग्स',
      'signOut': 'साइन आउट',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
    },
    'Marathi': {
      'profile': 'प्रोफाइल',
      'manageAccount': 'खाते व्यवस्थापित करा',
      'notifications': 'सूचना',
      'settings': 'सेटिंग्ज',
      'signOut': 'साइन आउट',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
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
          ? const Color(0xFF22262A)
          : const Color(0xFFF1F2F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildProfileCard(isDark),
                    const SizedBox(height: 24),
                    _buildMenuCard(isDark),
                    const SizedBox(height: 24),
                    _buildSignOutButton(isDark),
                    const SizedBox(height: 24),
                    _buildVersionText(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF22262A) : const Color(0xFFF1F2F4))
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
          const SizedBox(width: 80),
          Text(
            _translate('profile'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF131615),
              letterSpacing: -0.3,
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

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3136) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background gradient circle
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF45A191).withOpacity(0.1),
                    const Color(0xFF45A191).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 112,
                    height: 112,
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF45A191),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2C3136)
                              : Colors.white,
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
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF45A191),
                      ),
                    )
                  : Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                _userEmail.isNotEmpty ? _userEmail : '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3136) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.manage_accounts,
            label: _translate('manageAccount'),
            isDark: isDark,
            showDivider: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonalDataScreen(
                    onThemeToggle: widget.onThemeToggle,
                    onLanguageChange: widget.onLanguageChange,
                    currentLanguage: widget.currentLanguage,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.notifications,
            label: _translate('notifications'),
            isDark: isDark,
            showDivider: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsScreen(
                    onThemeToggle: widget.onThemeToggle,
                    onLanguageChange: widget.onLanguageChange,
                    currentLanguage: widget.currentLanguage,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.settings,
            label: _translate('settings'),
            isDark: isDark,
            showDivider: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppSettingsScreen(
                    onThemeToggle: widget.onThemeToggle,
                    onLanguageChange: widget.onLanguageChange,
                    currentLanguage: widget.currentLanguage,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isDark,
    required bool showDivider,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF3F4549)
                      : const Color(0xFFF3F4F6),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3F4549)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFFD1D5DB),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? const Color(0xFF45A191).withOpacity(0.2)
              : const Color(0xFF45A191).withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSignOutDialog(isDark),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: Color(0xFF45A191), size: 20),
              const SizedBox(width: 8),
              Text(
                _translate('signOut'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF45A191),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C3136) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _translate('signOut'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performSignOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performSignOut() async {
    try {
      // Call API logout
      await ApiService.logout();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('token');

      // Navigate to login screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  Widget _buildVersionText(bool isDark) {
    return Text(
      'v1.4.2 (Build 209)',
      style: TextStyle(
        fontSize: 12,
        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
      ),
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
      onTap: () => setState(() => _selectedIndex = index),
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
