import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Allow Google Fonts to use system fonts when offline
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const NotificationSettingsApp());
}

class NotificationSettingsApp extends StatefulWidget {
  const NotificationSettingsApp({super.key});

  @override
  State<NotificationSettingsApp> createState() =>
      _NotificationSettingsAppState();
}

class _NotificationSettingsAppState extends State<NotificationSettingsApp> {
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
      title: 'Notification Settings',
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
      home: NotificationSettingsScreen(
        onThemeToggle: _toggleTheme,
        onLanguageChange: _changeLanguage,
        currentLanguage: _language,
      ),
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const NotificationSettingsScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final int _selectedIndex = 4; // Profile tab
  bool _lowActivity = true;
  bool _highHeartRate = true;
  bool _abnormalSleep = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    // Load saved settings from NotificationService
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lowActivity = prefs.getBool('notify_low_activity') ?? true;
      _highHeartRate = prefs.getBool('notify_high_heart_rate') ?? true;
      _abnormalSleep = prefs.getBool('notify_abnormal_sleep') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    await NotificationService.setNotificationEnabled(key, value);
  }

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'notificationSettings': 'Notification Settings',
      'description':
          'Choose which health alerts you\'d like to receive on your device.',
      'lowActivity': 'Low Activity Alert',
      'lowActivityDesc': 'Alert when daily steps are below 3,000',
      'highHeartRate': 'High Heart Rate Alert',
      'highHeartRateDesc': 'Alert when resting heart rate exceeds 120 BPM',
      'abnormalSleep': 'Abnormal Sleep Pattern',
      'abnormalSleepDesc': 'Alert for sleep less than 5hrs or more than 10hrs',
      'testNotifications': 'Test Notifications',
      'testNotificationsDesc': 'Send a test notification to verify setup',
      'systemPermissions': 'System Permissions',
      'systemPermissionsDesc':
          'If you aren\'t receiving notifications, please ensure they are enabled in your device\'s ',
      'settingsPath': 'Settings > Notifications > SwasthSetu',
      'home': 'Home',
      'analytics': 'Analytics',
      'aiSummary': 'AI Summary',
      'history': 'History',
      'profile': 'Profile',
    },
    'Hindi': {
      'notificationSettings': 'सूचना सेटिंग्स',
      'description':
          'चुनें कि आप अपने डिवाइस पर कौन से स्वास्थ्य अलर्ट प्राप्त करना चाहते हैं।',
      'lowActivity': 'कम गतिविधि अलर्ट',
      'lowActivityDesc': 'दैनिक कदम 3,000 से कम होने पर अलर्ट',
      'highHeartRate': 'उच्च हृदय गति अलर्ट',
      'highHeartRateDesc': 'आराम की हृदय गति 120 BPM से अधिक होने पर अलर्ट',
      'abnormalSleep': 'असामान्य नींद पैटर्न',
      'abnormalSleepDesc': '5 घंटे से कम या 10 घंटे से अधिक नींद के लिए अलर्ट',
      'testNotifications': 'सूचना परीक्षण',
      'testNotificationsDesc': 'सेटअप सत्यापित करने के लिए परीक्षण सूचना भेजें',
      'systemPermissions': 'सिस्टम अनुमतियां',
      'systemPermissionsDesc':
          'यदि आपको सूचनाएं नहीं मिल रही हैं, तो कृपया सुनिश्चित करें कि वे आपके डिवाइस की ',
      'settingsPath': 'सेटिंग्स > सूचनाएं > SwasthSetu',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफ़ाइल',
    },
    'Marathi': {
      'notificationSettings': 'सूचना सेटिंग्ज',
      'description':
          'तुम्हाला तुमच्या डिव्हाइसवर कोणते आरोग्य अलर्ट मिळवायचे आहेत ते निवडा.',
      'lowActivity': 'कमी क्रियाकलाप अलर्ट',
      'lowActivityDesc': 'दैनिक पावले 3,000 पेक्षा कमी असताना अलर्ट',
      'highHeartRate': 'उच्च हृदय गती अलर्ट',
      'highHeartRateDesc':
          'विश्रांती हृदय गती 120 BPM पेक्षा जास्त असताना अलर्ट',
      'abnormalSleep': 'असामान्य झोपेचा नमुना',
      'abnormalSleepDesc':
          '5 तासांपेक्षा कमी किंवा 10 तासांपेक्षा जास्त झोपेसाठी अलर्ट',
      'testNotifications': 'सूचना चाचणी',
      'testNotificationsDesc': 'सेटअप सत्यापित करण्यासाठी चाचणी सूचना पाठवा',
      'systemPermissions': 'सिस्टम परवानग्या',
      'systemPermissionsDesc':
          'जर तुम्हाला सूचना मिळत नसतील, तर कृपया खात्री करा की ते तुमच्या डिव्हाइसच्या ',
      'settingsPath': 'सेटिंग्ज > सूचना > SwasthSetu',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildDescription(isDark),
                    const SizedBox(height: 24),
                    _buildNotificationsList(isDark),
                    const SizedBox(height: 32),
                    _buildSystemPermissions(isDark),
                    const SizedBox(height: 32),
                    _buildVersionText(isDark),
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
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _translate('notificationSettings'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF131615),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
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

  Widget _buildDescription(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        _translate('description'),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildNotificationsList(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
          _buildNotificationItem(
            icon: Icons.directions_walk,
            iconColor: const Color(0xFFF59E0B),
            iconBgColor: const Color(0xFFF59E0B).withOpacity(0.1),
            title: _translate('lowActivity'),
            subtitle: _translate('lowActivityDesc'),
            value: _lowActivity,
            onChanged: (val) {
              setState(() => _lowActivity = val);
              _saveNotificationSetting('notify_low_activity', val);
            },
            isDark: isDark,
            showDivider: true,
          ),
          _buildNotificationItem(
            icon: Icons.monitor_heart,
            iconColor: const Color(0xFFEF4444),
            iconBgColor: const Color(0xFFEF4444).withOpacity(0.1),
            title: _translate('highHeartRate'),
            subtitle: _translate('highHeartRateDesc'),
            value: _highHeartRate,
            onChanged: (val) {
              setState(() => _highHeartRate = val);
              _saveNotificationSetting('notify_high_heart_rate', val);
            },
            isDark: isDark,
            showDivider: true,
          ),
          _buildNotificationItem(
            icon: Icons.bedtime,
            iconColor: const Color(0xFF7C4DFF),
            iconBgColor: const Color(0xFF7C4DFF).withOpacity(0.1),
            title: _translate('abnormalSleep'),
            subtitle: _translate('abnormalSleepDesc'),
            value: _abnormalSleep,
            onChanged: (val) {
              setState(() => _abnormalSleep = val);
              _saveNotificationSetting('notify_abnormal_sleep', val);
            },
            isDark: isDark,
            showDivider: true,
          ),
          _buildTestNotificationButton(isDark),
        ],
      ),
    );
  }

  Widget _buildTestNotificationButton(bool isDark) {
    return InkWell(
      onTap: () async {
        await NotificationService.showTestNotification(
          title: '🎉 SwasthSetu Test',
          body:
              'Notifications are working! You\'ll receive health alerts here.',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Test notification sent!'),
              backgroundColor: const Color(0xFF45A191),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF45A191).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Color(0xFF45A191),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _translate('testNotifications'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF131615),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _translate('testNotificationsDesc'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
    required bool showDivider,
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildSwitch(value, onChanged, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged, bool isDark) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF45A191)
              : isDark
              ? const Color(0xFF4B5563)
              : const Color(0xFFD1D5DB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemPermissions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3136) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF45A191).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Color(0xFF45A191), size: 20),
              const SizedBox(width: 12),
              Text(
                _translate('systemPermissions'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                height: 1.5,
              ),
              children: [
                TextSpan(text: _translate('systemPermissionsDesc')),
                TextSpan(
                  text: _translate('settingsPath'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionText(bool isDark) {
    return Center(
      child: Text(
        'v1.4.2 (Build 209)',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
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
