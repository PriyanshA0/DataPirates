import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthHistoryApp());
}

class HealthHistoryApp extends StatefulWidget {
  const HealthHistoryApp({super.key});

  @override
  State<HealthHistoryApp> createState() => _HealthHistoryAppState();
}

class _HealthHistoryAppState extends State<HealthHistoryApp> {
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
      title: 'Health History',
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
      home: HealthHistoryScreen(
        onThemeToggle: _toggleTheme,
        onLanguageChange: _changeLanguage,
        currentLanguage: _language,
      ),
    );
  }
}

class HealthHistoryScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const HealthHistoryScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  int _selectedIndex = 3; // History tab
  int _selectedMonthIndex = 0;
  bool _isLoading = true;
  bool _isOffline = false;
  List<Map<String, dynamic>> _historyData = [];
  int _currentDays = 180; // Load 6 months of data
  List<DateTime> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _initializeMonths();
    _fetchHistory();
  }

  void _initializeMonths() {
    // Generate last 6 months
    final now = DateTime.now();
    _availableMonths = List.generate(6, (index) {
      return DateTime(now.year, now.month - index, 1);
    });
  }

  List<Map<String, dynamic>> get _filteredHistoryData {
    if (_availableMonths.isEmpty) return _historyData;

    final selectedMonth = _availableMonths[_selectedMonthIndex];
    return _historyData.where((item) {
      try {
        final date = DateTime.parse(item['date'] ?? '');
        return date.year == selectedMonth.year &&
            date.month == selectedMonth.month;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);

    // Sync Strava activities first to get latest data
    await ApiService.syncStravaActivities();

    final result = await ApiService.getHealthHistory(days: _currentDays);

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _isOffline = result['cached'] == true;
          _historyData = List<Map<String, dynamic>>.from(data['history'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _historyData = [];
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _currentDays += 30);
    await _fetchHistory();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;

      if (diff == 0) return _translate('today');
      if (diff == 1) return _translate('yesterday');
      return DateFormat('EEEE, MMM d').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getDayLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;

      if (diff == 0) return 'TODAY';
      if (diff == 1) return 'YESTERDAY';
      return DateFormat('EEE').format(date).toUpperCase();
    } catch (e) {
      return '';
    }
  }

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'healthHistory': 'Health History',
      'october': 'October',
      'september': 'September',
      'august': 'August',
      'july': 'July',
      'today': 'TODAY',
      'great': 'Great',
      'heart': 'Heart',
      'steps': 'Steps',
      'sleepDuration': 'Sleep Duration',
      'viewDetails': 'View Details',
      'yesterday': 'Yesterday',
      'normal': 'Normal',
      'avgHr': 'AVG HR',
      'sleep': 'SLEEP',
      'monday': 'Monday',
      'check': 'Check',
      'lowActivity': 'Low Activity Detected',
      'lowActivityDesc': 'Only 2,400 steps recorded.',
      'sun': 'SUN',
      'goodDay': 'Good Day',
      'allGoalsMet': 'All goals met',
      'loadOlder': 'LOAD OLDER RECORDS',
      'home': 'Home',
      'analytics': 'Analytics',
      'aiSummary': 'AI Summary',
      'history': 'History',
      'profile': 'Profile',
      'noData': 'No health data available',
      'distance': 'Distance',
      'calories': 'Calories',
      'activities': 'Activities',
    },
    'Hindi': {
      'healthHistory': 'स्वास्थ्य इतिहास',
      'october': 'अक्टूबर',
      'september': 'सितंबर',
      'august': 'अगस्त',
      'july': 'जुलाई',
      'today': 'आज',
      'great': 'बढ़िया',
      'heart': 'हृदय',
      'steps': 'कदम',
      'sleepDuration': 'नींद की अवधि',
      'viewDetails': 'विवरण देखें',
      'yesterday': 'कल',
      'normal': 'सामान्य',
      'avgHr': 'औसत HR',
      'sleep': 'नींद',
      'monday': 'सोमवार',
      'check': 'जाँचें',
      'lowActivity': 'कम गतिविधि पाई गई',
      'lowActivityDesc': 'केवल 2,400 कदम रिकॉर्ड किए गए।',
      'sun': 'रवि',
      'goodDay': 'अच्छा दिन',
      'allGoalsMet': 'सभी लक्ष्य पूरे हुए',
      'loadOlder': 'पुराने रिकॉर्ड लोड करें',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफ़ाइल',
      'noData': 'कोई स्वास्थ्य डेटा उपलब्ध नहीं',
      'distance': 'दूरी',
      'calories': 'कैलोरी',
      'activities': 'गतिविधियाँ',
    },
    'Marathi': {
      'healthHistory': 'आरोग्य इतिहास',
      'october': 'ऑक्टोबर',
      'september': 'सप्टेंबर',
      'august': 'ऑगस्ट',
      'july': 'जुलै',
      'today': 'आज',
      'great': 'उत्तम',
      'heart': 'हृदय',
      'steps': 'पावले',
      'sleepDuration': 'झोपेची कालावधी',
      'viewDetails': 'तपशील पहा',
      'yesterday': 'काल',
      'normal': 'सामान्य',
      'avgHr': 'सरासरी HR',
      'sleep': 'झोप',
      'monday': 'सोमवार',
      'check': 'तपासा',
      'lowActivity': 'कमी क्रियाकलाप आढळला',
      'lowActivityDesc': 'फक्त 2,400 पावले रेकॉर्ड केली.',
      'sun': 'रवि',
      'goodDay': 'चांगला दिवस',
      'allGoalsMet': 'सर्व लक्ष्ये पूर्ण',
      'loadOlder': 'जुने रेकॉर्ड लोड करा',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफाइल',
      'noData': 'आरोग्य डेटा उपलब्ध नाही',
      'distance': 'अंतर',
      'calories': 'कॅलरी',
      'activities': 'क्रियाकलाप',
    },
  };

  String _translate(String key) {
    return _translations[widget.currentLanguage]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredData = _filteredHistoryData;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF22262A)
          : const Color(0xFFF1F2F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildMonthSelector(isDark),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF6366F1),
                      ),
                    )
                  : filteredData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: isDark
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _translate('noData'),
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.grey.shade600,
                            ),
                          ),
                          if (_availableMonths.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'MMMM yyyy',
                              ).format(_availableMonths[_selectedMonthIndex]),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: Column(
                        children: [
                          if (_isOffline)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.offline_bolt,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Showing cached data',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ...filteredData.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildHistoryCard(entry.value, isDark),
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                          _buildLoadOlderButton(isDark),
                          const SizedBox(height: 24),
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
          Text(
            _translate('healthHistory'),
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

  Widget _buildMonthSelector(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_availableMonths.length, (index) {
            final isSelected = _selectedMonthIndex == index;
            final month = _availableMonths[index];
            final monthName = DateFormat('MMMM').format(month);
            final hasData = _historyData.any((item) {
              try {
                final date = DateTime.parse(item['date'] ?? '');
                return date.year == month.year && date.month == month.month;
              } catch (e) {
                return false;
              }
            });

            return Padding(
              padding: EdgeInsets.only(
                right: index < _availableMonths.length - 1 ? 12 : 0,
              ),
              child: GestureDetector(
                onTap: () => setState(() => _selectedMonthIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF45A191)
                        : isDark
                        ? const Color(0xFF2C3136)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : isDark
                          ? const Color(0xFF3F4549)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF45A191).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isDark
                              ? const Color(0xFF6C7F7C)
                              : const Color(0xFF6C7F7C),
                        ),
                      ),
                      if (!hasData && !_isLoading) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.5)
                                : Colors.grey.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data, bool isDark) {
    final date = data['date'] ?? '';
    final steps = data['steps'] is int
        ? data['steps']
        : int.tryParse(data['steps']?.toString() ?? '0') ?? 0;
    final distanceRaw = data['distance'];
    final distance = distanceRaw is num
        ? distanceRaw.toDouble()
        : double.tryParse(distanceRaw?.toString() ?? '0') ?? 0.0;
    final calories = data['calories'] is int
        ? data['calories']
        : int.tryParse(data['calories']?.toString() ?? '0') ?? 0;
    final activities = List<Map<String, dynamic>>.from(
      data['activities'] ?? [],
    );

    // Status based on steps
    String status = 'Great';
    Color statusColor = const Color(0xFF059669);
    if (steps < 5000) {
      status = 'Check';
      statusColor = const Color(0xFFEF4444);
    } else if (steps < 8000) {
      status = 'Normal';
      statusColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF22262A)
                        : const Color(0xFFF1F2F4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Container(
                width: 2,
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      statusColor.withOpacity(0.5),
                      isDark
                          ? const Color(0xFF3F4549)
                          : const Color(0xFFE5E7EB),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C3136) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3F4549)
                      : const Color(0xFFF3F4F6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDayLabel(date),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.2,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF131615),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? statusColor.withOpacity(0.2)
                              : statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              steps >= 8000
                                  ? Icons.check_circle
                                  : steps >= 5000
                                  ? Icons.remove_circle
                                  : Icons.warning,
                              color: statusColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricBox(
                          icon: Icons.directions_walk,
                          iconColor: const Color(0xFF6366F1),
                          label: _translate('steps'),
                          value:
                              '${steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricBox(
                          icon: Icons.straighten,
                          iconColor: const Color(0xFFEC4899),
                          label: _translate('distance'),
                          value: '${distance.toStringAsFixed(1)} km',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMetricBox(
                    icon: Icons.local_fire_department,
                    iconColor: const Color(0xFFEF4444),
                    label: _translate('calories'),
                    value: '${calories.toString()} kcal',
                    isDark: isDark,
                  ),
                  if (activities.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF22262A)
                            : const Color(0xFFF1F2F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _translate('activities'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : const Color(0xFF6C7F7C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...activities.map((activity) {
                            final type = activity['type'] ?? 'Activity';
                            final durationMin = activity['durationMin'] ?? 0;
                            final activityCal = activity['calories'] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$type ($durationMin min)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.8)
                                          : const Color(0xFF131615),
                                    ),
                                  ),
                                  Text(
                                    '$activityCal cal',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.8)
                                          : const Color(0xFF131615),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22262A) : const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : const Color(0xFF6C7F7C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadOlderButton(bool isDark) {
    return Center(
      child: TextButton(
        onPressed: _loadMore,
        child: Text(
          _translate('loadOlder'),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6C7F7C),
            letterSpacing: 1.5,
          ),
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
                icon: Icons.person_outline,
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

        String route;
        switch (index) {
          case 0:
            route = '/dashboard';
            break;
          case 1:
            route = '/analytics';
            break;
          case 2:
            route = '/ai-summary';
            break;
          case 3:
            return; // Already on history
          case 4:
            route = '/profile';
            break;
          default:
            return;
        }

        Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
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
                      ? const Color(0xFF45A191).withOpacity(0.2)
                      : const Color(0xFF45A191).withOpacity(0.1),
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
