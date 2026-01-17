import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SwasthSetuApp());
}

class SwasthSetuApp extends StatefulWidget {
  const SwasthSetuApp({super.key});

  @override
  State<SwasthSetuApp> createState() => _SwasthSetuAppState();
}

class _SwasthSetuAppState extends State<SwasthSetuApp> {
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
      title: 'AI Health Summary',
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
      home: AISummaryScreen(
        onThemeToggle: _toggleTheme,
        onLanguageChange: _changeLanguage,
        currentLanguage: _language,
      ),
    );
  }
}

class AISummaryScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const AISummaryScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<AISummaryScreen> createState() => _AISummaryScreenState();
}

class _AISummaryScreenState extends State<AISummaryScreen> {
  int _selectedIndex = 2; // AI Summary tab
  bool _isLoading = true;
  bool _isOffline = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Text-to-Speech
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  bool _ttsInitialized = false;

  // Dynamic data from API
  String _summaryText = '';
  String _sleepAdvice = '';
  String _updatedAt = '';
  String _sleepChange = '+0hrs';
  int _steps = 0;
  String _status = 'Recovered';
  String _trend = 'Positive';
  List<Map<String, String>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchAISummary();
  }

  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();

      // Configure for a soft female voice
      await _flutterTts!.setLanguage("en-US");
      await _flutterTts!.setSpeechRate(0.45); // Slower, softer pace
      await _flutterTts!.setVolume(0.9);
      await _flutterTts!.setPitch(1.2); // Higher pitch for female voice

      // Try to set a female voice
      List<dynamic>? voices = await _flutterTts!.getVoices;
      if (voices != null) {
        for (var voice in voices) {
          String name = voice['name']?.toString().toLowerCase() ?? '';
          String locale = voice['locale']?.toString() ?? '';
          // Look for female voices
          if (locale.contains('en') &&
              (name.contains('female') ||
                  name.contains('samantha') ||
                  name.contains('karen') ||
                  name.contains('victoria') ||
                  name.contains('zira') ||
                  name.contains('susan') ||
                  name.contains('hazel') ||
                  name.contains('moira'))) {
            await _flutterTts!.setVoice({
              "name": voice['name'],
              "locale": voice['locale'],
            });
            break;
          }
        }
      }

      _flutterTts!.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });

      _flutterTts!.setErrorHandler((msg) {
        print('TTS Error: $msg');
        if (mounted) setState(() => _isSpeaking = false);
      });

      _ttsInitialized = true;
      print('TTS initialized successfully');
    } catch (e) {
      print('TTS initialization error: $e');
      _ttsInitialized = false;
    }
  }

  Future<void> _speak() async {
    if (!_ttsInitialized || _flutterTts == null) {
      print('TTS not initialized, trying to initialize...');
      await _initTts();
      if (!_ttsInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text-to-speech is not available')),
        );
        return;
      }
    }

    if (_isSpeaking) {
      await _flutterTts!.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    // Set TTS language based on current language
    String ttsLanguage = "en-US";
    if (widget.currentLanguage == 'Hindi') {
      ttsLanguage = "hi-IN";
    } else if (widget.currentLanguage == 'Marathi') {
      ttsLanguage = "mr-IN";
    }
    await _flutterTts!.setLanguage(ttsLanguage);

    // Get translated text for TTS
    String textToSpeak;
    if (_summaryText.isNotEmpty) {
      if (widget.currentLanguage == 'Hindi') {
        textToSpeak = _getHindiSummary();
      } else if (widget.currentLanguage == 'Marathi') {
        textToSpeak = _getMarathiSummary();
      } else {
        textToSpeak = '$_summaryText. $_sleepAdvice';
      }
    } else {
      textToSpeak = _translate('noSummary');
    }

    setState(() => _isSpeaking = true);

    try {
      var result = await _flutterTts!.speak(textToSpeak);
      if (result != 1) {
        setState(() => _isSpeaking = false);
      }
    } catch (e) {
      print('TTS speak error: $e');
      setState(() => _isSpeaking = false);
    }
  }

  String _getHindiSummary() {
    // Create Hindi summary from the data
    String summary = 'आपका साप्ताहिक स्वास्थ्य सारांश। ';

    if (_sleepChange.isNotEmpty) {
      summary += 'नींद में ${_sleepChange} का बदलाव। ';
    }
    if (_steps > 0) {
      summary += 'आपने $_steps कदम चले। ';
    }
    if (_status.isNotEmpty) {
      String statusHindi = _status == 'Recovered' ? 'रिकवर हो गया' : _status;
      summary += 'स्थिति: $statusHindi। ';
    }
    if (_trend.isNotEmpty) {
      String trendHindi = _trend == 'Positive' ? 'सकारात्मक' : _trend;
      summary += 'रुझान: $trendHindi। ';
    }

    // Add recommendations
    if (_recommendations.isNotEmpty) {
      summary += 'सुझाव: ';
      for (var rec in _recommendations) {
        if (rec['title'] == 'Light Cardio') {
          summary += 'रिकवरी बढ़ाने के लिए 15 मिनट की सैर करें। ';
        } else if (rec['title'] == 'Mindfulness') {
          summary += 'सोने से पहले गहरी सांस लें। ';
        }
      }
    }

    return summary;
  }

  String _getMarathiSummary() {
    // Create Marathi summary from the data
    String summary = 'तुमचा साप्ताहिक आरोग्य सारांश। ';

    if (_sleepChange.isNotEmpty) {
      summary += 'झोपेत ${_sleepChange} बदल। ';
    }
    if (_steps > 0) {
      summary += 'तुम्ही $_steps पावले चाललात। ';
    }
    if (_status.isNotEmpty) {
      String statusMarathi = _status == 'Recovered' ? 'रिकव्हर झाले' : _status;
      summary += 'स्थिती: $statusMarathi। ';
    }
    if (_trend.isNotEmpty) {
      String trendMarathi = _trend == 'Positive' ? 'सकारात्मक' : _trend;
      summary += 'ट्रेंड: $trendMarathi। ';
    }

    // Add recommendations
    if (_recommendations.isNotEmpty) {
      summary += 'सूचना: ';
      for (var rec in _recommendations) {
        if (rec['title'] == 'Light Cardio') {
          summary += 'रिकव्हरी वाढवण्यासाठी 15 मिनिटांची चाल करा। ';
        } else if (rec['title'] == 'Mindfulness') {
          summary += 'झोपण्यापूर्वी खोल श्वास घ्या। ';
        }
      }
    }

    return summary;
  }

  Future<void> _stopTtsIfSpeaking() async {
    if (_isSpeaking && _flutterTts != null) {
      await _flutterTts!.stop();
      _isSpeaking = false;
    }
  }

  void _showKeyInsightsPopup(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _translate('keyInsights'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF131615),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Insights list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildDetailedInsightCard(
                    icon: Icons.bedtime,
                    iconColor: const Color(0xFF6366F1),
                    iconBgColor: isDark
                        ? const Color(0xFF6366F1).withOpacity(0.2)
                        : const Color(0xFFEEF2FF),
                    title: _translate('sleep'),
                    value: _sleepChange,
                    description: _sleepChange.startsWith('+')
                        ? 'Great! Your sleep duration has improved compared to last week. Keep maintaining a consistent sleep schedule.'
                        : _sleepChange.startsWith('-')
                        ? 'Your sleep duration has decreased. Try going to bed 30 minutes earlier tonight.'
                        : 'Your sleep pattern is stable. Consider optimizing your sleep quality with a consistent bedtime routine.',
                    trend: _sleepChange.startsWith('+')
                        ? 'Improving'
                        : (_sleepChange.startsWith('-')
                              ? 'Declining'
                              : 'Stable'),
                    trendColor: _sleepChange.startsWith('+')
                        ? const Color(0xFF10B981)
                        : (_sleepChange.startsWith('-')
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF9CA3AF)),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailedInsightCard(
                    icon: Icons.directions_walk,
                    iconColor: const Color(0xFFF97316),
                    iconBgColor: isDark
                        ? const Color(0xFFF97316).withOpacity(0.2)
                        : const Color(0xFFFFF7ED),
                    title: _translate('steps'),
                    value: _steps > 0
                        ? _steps.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          )
                        : '0',
                    description: _steps >= 10000
                        ? 'Excellent! You\'ve exceeded the recommended daily step goal. Your cardiovascular health is benefiting.'
                        : _steps >= 7000
                        ? 'Good progress! You\'re close to the 10,000 step goal. Try adding a short walk after meals.'
                        : 'Consider increasing your daily activity. Start with a goal of 7,000 steps and work your way up.',
                    trend: _steps >= 10000
                        ? 'Excellent'
                        : (_steps >= 7000 ? 'Good' : 'Needs Improvement'),
                    trendColor: _steps >= 10000
                        ? const Color(0xFF10B981)
                        : (_steps >= 7000
                              ? const Color(0xFFF97316)
                              : const Color(0xFFEF4444)),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailedInsightCard(
                    icon: Icons.check_circle,
                    iconColor: _status == 'Needs Attention'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF059669),
                    iconBgColor: isDark
                        ? (_status == 'Needs Attention'
                              ? const Color(0xFFEF4444).withOpacity(0.2)
                              : const Color(0xFF059669).withOpacity(0.2))
                        : (_status == 'Needs Attention'
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFD1FAE5)),
                    title: _translate('status'),
                    value: _status,
                    description: _status == 'Recovered'
                        ? 'Your body has fully recovered. You\'re ready for your regular activities and exercise routine.'
                        : _status == 'Improving'
                        ? 'Your health metrics are trending positively. Continue your current healthy habits.'
                        : 'Some health indicators need attention. Consider consulting with a healthcare professional.',
                    trend: _status,
                    trendColor: _status == 'Needs Attention'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailedInsightCard(
                    icon: _trend == 'Positive'
                        ? Icons.trending_up
                        : (_trend == 'Negative'
                              ? Icons.trending_down
                              : Icons.trending_flat),
                    iconColor: _trend == 'Positive'
                        ? const Color(0xFF3B82F6)
                        : (_trend == 'Negative'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF9CA3AF)),
                    iconBgColor: isDark
                        ? (_trend == 'Positive'
                              ? const Color(0xFF3B82F6).withOpacity(0.2)
                              : (_trend == 'Negative'
                                    ? const Color(0xFFEF4444).withOpacity(0.2)
                                    : const Color(0xFF9CA3AF).withOpacity(0.2)))
                        : (_trend == 'Positive'
                              ? const Color(0xFFDBEAFE)
                              : (_trend == 'Negative'
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFF3F4F6))),
                    title: _translate('trend'),
                    value: _trend,
                    description: _trend == 'Positive'
                        ? 'Your overall health trajectory is improving. Your consistent efforts are paying off!'
                        : _trend == 'Negative'
                        ? 'Your health metrics show a declining trend. Focus on sleep, hydration, and regular exercise.'
                        : 'Your health metrics are stable. Consider setting new goals to continue improving.',
                    trend: _trend,
                    trendColor: _trend == 'Positive'
                        ? const Color(0xFF10B981)
                        : (_trend == 'Negative'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF9CA3AF)),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedInsightCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required String description,
    required String trend,
    required Color trendColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3F4549) : const Color(0xFFF3F4F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF6B7280),
                      height: 1.5,
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

  @override
  void dispose() {
    _flutterTts?.stop();
    super.dispose();
  }

  Future<void> _fetchAISummary() async {
    // Stop TTS if speaking during refresh
    await _stopTtsIfSpeaking();

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Sync Strava activities first to get latest data
      await ApiService.syncStravaActivities();

      // Force refresh to clear cache and get fresh AI summary
      final result = await ApiService.getAISummary(forceRefresh: true);
      print('AI Summary API Result: $result'); // Debug log

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          _isOffline = result['cached'] == true;

          // Weekly Pulse data
          final weeklyPulse = data['weeklyPulse'] ?? {};
          _summaryText = weeklyPulse['summaryText'] ?? '';
          _sleepAdvice = weeklyPulse['sleepAdvice'] ?? '';
          _updatedAt = _formatUpdatedTime(weeklyPulse['updatedAt']);

          // Key Insights data
          final keyInsights = data['keyInsights'] ?? {};
          _sleepChange = keyInsights['sleepChange'] ?? '+0hrs';
          _steps = keyInsights['steps'] ?? 0;
          _status = keyInsights['status'] ?? 'Recovered';
          _trend = keyInsights['trend'] ?? 'Positive';

          // Recommendations
          final recommendations = data['recommendations'] as List? ?? [];
          _recommendations = recommendations
              .map(
                (r) => {
                  'title': (r['title'] ?? '').toString(),
                  'description': (r['description'] ?? '').toString(),
                },
              )
              .toList();

          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = result['message'] ?? 'Failed to load AI summary';
          });
        }
      }
    } catch (e) {
      print('AI Summary Error: $e'); // Debug log
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  String _formatUpdatedTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return 'UPDATED JUST NOW';
    try {
      final dateTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'UPDATED JUST NOW';
      if (diff.inMinutes < 60) return 'UPDATED ${diff.inMinutes}M AGO';
      if (diff.inHours < 24) return 'UPDATED ${diff.inHours}H AGO';
      return 'UPDATED ${diff.inDays}D AGO';
    } catch (e) {
      return 'UPDATED JUST NOW';
    }
  }

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'aiHealthSummary': 'AI Health Summary',
      'dailyUpdate': 'Daily Update',
      'weeklyPulse': 'Your Weekly Pulse',
      'pulseDesc':
          'Your heart rate variability has improved significantly this week, suggesting',
      'betterRecovery': 'better recovery',
      'pulseDesc2':
          ". You've also hit your step goal 5 out of 7 days—great consistency!",
      'sleepAdvice':
          'However, your sleep duration dipped slightly on Tuesday. Consider an earlier wind-down tonight.',
      'listen': 'Listen',
      'updated': 'UPDATED 2M AGO',
      'keyInsights': 'Key Insights',
      'viewAll': 'View All',
      'sleep': 'Sleep',
      'steps': 'Steps',
      'status': 'Status',
      'trend': 'Trend',
      'recovered': 'Recovered',
      'positive': 'Positive',
      'basedOnSummary': 'Based on your summary',
      'lightCardio': 'Light Cardio',
      'lightCardioDesc': 'Try a 15-min walk to boost recovery.',
      'mindfulness': 'Mindfulness',
      'mindfulnessDesc': 'Deep breathing before bed.',
      'generatedBy': 'Generated by AI based on your data',
      'home': 'Home',
      'analytics': 'Analytics',
      'aiSummary': 'AI Summary',
      'history': 'History',
      'profile': 'Profile',
      'noSummary': 'No health summary available yet.',
    },
    'Hindi': {
      'aiHealthSummary': 'AI स्वास्थ्य सारांश',
      'dailyUpdate': 'दैनिक अपडेट',
      'weeklyPulse': 'आपका साप्ताहिक पल्स',
      'pulseDesc':
          'इस सप्ताह आपकी हृदय गति परिवर्तनशीलता में काफी सुधार हुआ है, जो दर्शाता है',
      'betterRecovery': 'बेहतर रिकवरी',
      'pulseDesc2':
          '। आपने 7 में से 5 दिन अपने कदम लक्ष्य को हासिल किया—बढ़िया निरंतरता!',
      'sleepAdvice':
          'हालांकि, मंगलवार को आपकी नींद की अवधि थोड़ी कम हो गई। आज रात जल्दी आराम करने पर विचार करें।',
      'listen': 'सुनें',
      'updated': '2 मिनट पहले अपडेट किया गया',
      'keyInsights': 'मुख्य अंतर्दृष्टि',
      'viewAll': 'सभी देखें',
      'sleep': 'नींद',
      'steps': 'कदम',
      'status': 'स्थिति',
      'trend': 'रुझान',
      'recovered': 'रिकवर हो गया',
      'positive': 'सकारात्मक',
      'basedOnSummary': 'आपके सारांश के आधार पर',
      'lightCardio': 'हल्का कार्डियो',
      'lightCardioDesc': 'रिकवरी बढ़ाने के लिए 15 मिनट की सैर करें।',
      'mindfulness': 'माइंडफुलनेस',
      'mindfulnessDesc': 'सोने से पहले गहरी सांस लें।',
      'generatedBy': 'आपके डेटा के आधार पर AI द्वारा जेनरेट किया गया',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफ़ाइल',
      'noSummary': 'अभी तक कोई स्वास्थ्य सारांश उपलब्ध नहीं है।',
    },
    'Marathi': {
      'aiHealthSummary': 'AI आरोग्य सारांश',
      'dailyUpdate': 'दैनिक अपडेट',
      'weeklyPulse': 'तुमचा साप्ताहिक पल्स',
      'pulseDesc':
          'या आठवड्यात तुमच्या हृदय गती परिवर्तनशीलतेमध्ये लक्षणीय सुधारणा झाली आहे, जे सूचित करते',
      'betterRecovery': 'चांगली रिकव्हरी',
      'pulseDesc2':
          '. तुम्ही 7 पैकी 5 दिवस तुमचे पाऊल लक्ष्य गाठले आहे—उत्तम सातत्य!',
      'sleepAdvice':
          'तथापि, मंगळवारी तुमची झोपेची कालावधी थोडी कमी झाली. आज रात्री लवकर विश्रांती घेण्याचा विचार करा.',
      'listen': 'ऐका',
      'updated': '2 मिनिटांपूर्वी अपडेट केले',
      'keyInsights': 'मुख्य अंतर्दृष्टी',
      'viewAll': 'सर्व पहा',
      'sleep': 'झोप',
      'steps': 'पावले',
      'status': 'स्थिती',
      'trend': 'ट्रेंड',
      'recovered': 'रिकव्हर झाले',
      'positive': 'सकारात्मक',
      'basedOnSummary': 'तुमच्या सारांशावर आधारित',
      'lightCardio': 'हलका कार्डिओ',
      'lightCardioDesc': 'रिकव्हरी वाढवण्यासाठी 15 मिनिटांची चाल करा.',
      'mindfulness': 'माइंडफुलनेस',
      'mindfulnessDesc': 'झोपण्यापूर्वी खोल श्वास घ्या.',
      'generatedBy': 'तुमच्या डेटावर आधारित AI द्वारे व्युत्पन्न',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफाइल',
      'noSummary': 'अद्याप कोणताही आरोग्य सारांश उपलब्ध नाही.',
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
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.orange.withOpacity(0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Showing cached data (Offline)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF45A191),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Generating AI Summary...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This may take a few seconds',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _hasError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: isDark
                                  ? Colors.red.shade300
                                  : Colors.red.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load AI Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _fetchAISummary,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF45A191),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAISummary,
                      color: const Color(0xFF45A191),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWeeklyPulseCard(isDark),
                            const SizedBox(height: 24),
                            _buildKeyInsightsSection(isDark),
                            const SizedBox(height: 24),
                            _buildRecommendationsSection(isDark),
                            const SizedBox(height: 24),
                            _buildGeneratedByAI(isDark),
                          ],
                        ),
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
        color: (isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF1F2F4))
            .withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade200.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 80),
          Text(
            _translate('aiHealthSummary'),
            style: TextStyle(
              fontSize: 18,
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
                color: isDark ? const Color(0xFF2C3035) : Colors.white,
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

  Widget _buildWeeklyPulseCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF45A191).withOpacity(0.05)
            : const Color(0xFF45A191).withOpacity(0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF45A191).withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -48,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: const Color(0xFF45A191).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF45A191).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF45A191).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _translate('dailyUpdate').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF45A191),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C3035) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
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
                    child: const Icon(
                      Icons.smart_toy,
                      color: Color(0xFF45A191),
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _translate('weeklyPulse'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _summaryText.isNotEmpty
                    ? _summaryText
                    : _translate('pulseDesc'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? Colors.grey.shade300
                      : const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _sleepAdvice.isNotEmpty
                            ? _sleepAdvice
                            : _translate('sleepAdvice'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _speak,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isSpeaking
                            ? const Color(0xFF45A191).withOpacity(0.15)
                            : (isDark ? const Color(0xFF2C3035) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSpeaking
                              ? const Color(0xFF45A191)
                              : (isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05)),
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
                      child: Row(
                        children: [
                          Icon(
                            _isSpeaking ? Icons.stop_circle : Icons.play_circle,
                            color: const Color(0xFF45A191),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSpeaking ? 'Stop' : _translate('listen'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF45A191),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    _updatedAt.isNotEmpty ? _updatedAt : _translate('updated'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsightsSection(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _translate('keyInsights'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                ),
              ),
              GestureDetector(
                onTap: () => _showKeyInsightsPopup(isDark),
                child: Text(
                  _translate('viewAll'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF45A191),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              _buildInsightCard(
                icon: Icons.bedtime,
                iconColor: const Color(0xFF6366F1),
                iconBgColor: isDark
                    ? const Color(0xFF6366F1).withOpacity(0.2)
                    : const Color(0xFFEEF2FF),
                label: _translate('sleep'),
                value: _sleepChange,
                trend: _sleepChange.startsWith('+')
                    ? '↑'
                    : (_sleepChange.startsWith('-') ? '↓' : null),
                trendColor: _sleepChange.startsWith('+')
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildInsightCard(
                icon: Icons.directions_walk,
                iconColor: const Color(0xFFF97316),
                iconBgColor: isDark
                    ? const Color(0xFFF97316).withOpacity(0.2)
                    : const Color(0xFFFFF7ED),
                label: _translate('steps'),
                value: _steps > 0
                    ? _steps.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )
                    : '0',
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildInsightCard(
                icon: Icons.check_circle,
                iconColor: _status == 'Needs Attention'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF059669),
                iconBgColor: isDark
                    ? (_status == 'Needs Attention'
                          ? const Color(0xFFEF4444).withOpacity(0.2)
                          : const Color(0xFF059669).withOpacity(0.2))
                    : (_status == 'Needs Attention'
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFD1FAE5)),
                label: _translate('status'),
                value: _status,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildInsightCard(
                icon: _trend == 'Positive'
                    ? Icons.trending_up
                    : (_trend == 'Negative'
                          ? Icons.trending_down
                          : Icons.trending_flat),
                iconColor: _trend == 'Positive'
                    ? const Color(0xFF3B82F6)
                    : (_trend == 'Negative'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF9CA3AF)),
                iconBgColor: isDark
                    ? (_trend == 'Positive'
                          ? const Color(0xFF3B82F6).withOpacity(0.2)
                          : (_trend == 'Negative'
                                ? const Color(0xFFEF4444).withOpacity(0.2)
                                : const Color(0xFF9CA3AF).withOpacity(0.2)))
                    : (_trend == 'Positive'
                          ? const Color(0xFFDBEAFE)
                          : (_trend == 'Negative'
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFF3F4F6))),
                label: _translate('trend'),
                value: _trend,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    String? trend,
    Color? trendColor,
    required bool isDark,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3F4549) : const Color(0xFFF3F4F6),
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
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  if (trend != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 12,
                        color: trendColor ?? const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(bool isDark) {
    // Default icons for recommendations based on keywords
    IconData _getIconForTitle(String title) {
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains('walk') ||
          lowerTitle.contains('cardio') ||
          lowerTitle.contains('exercise') ||
          lowerTitle.contains('run')) {
        return Icons.directions_walk;
      } else if (lowerTitle.contains('mindful') ||
          lowerTitle.contains('meditat') ||
          lowerTitle.contains('relax')) {
        return Icons.self_improvement;
      } else if (lowerTitle.contains('sleep') || lowerTitle.contains('rest')) {
        return Icons.bedtime;
      } else if (lowerTitle.contains('water') ||
          lowerTitle.contains('hydrat')) {
        return Icons.water_drop;
      } else if (lowerTitle.contains('food') ||
          lowerTitle.contains('eat') ||
          lowerTitle.contains('diet') ||
          lowerTitle.contains('nutrition')) {
        return Icons.restaurant;
      } else if (lowerTitle.contains('heart') || lowerTitle.contains('pulse')) {
        return Icons.favorite;
      } else if (lowerTitle.contains('stretch') ||
          lowerTitle.contains('yoga')) {
        return Icons.accessibility_new;
      } else if (lowerTitle.contains('break') || lowerTitle.contains('pause')) {
        return Icons.pause_circle;
      }
      return Icons.lightbulb;
    }

    Color _getColorForIndex(int index) {
      final colors = [
        const Color(0xFF3B82F6),
        const Color(0xFF8B5CF6),
        const Color(0xFF10B981),
        const Color(0xFFF97316),
        const Color(0xFFEF4444),
      ];
      return colors[index % colors.length];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _translate('basedOnSummary'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF131615),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_recommendations.isEmpty) ...[
          _buildRecommendationCard(
            icon: Icons.directions_walk,
            iconColor: const Color(0xFF3B82F6),
            iconBgColor: isDark
                ? const Color(0xFF3B82F6).withOpacity(0.2)
                : const Color(0xFFDBEAFE),
            title: _translate('lightCardio'),
            description: _translate('lightCardioDesc'),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            icon: Icons.self_improvement,
            iconColor: const Color(0xFF8B5CF6),
            iconBgColor: isDark
                ? const Color(0xFF8B5CF6).withOpacity(0.2)
                : const Color(0xFFF3E8FF),
            title: _translate('mindfulness'),
            description: _translate('mindfulnessDesc'),
            isDark: isDark,
          ),
        ] else ...[
          for (int i = 0; i < _recommendations.length; i++) ...[
            _buildRecommendationCard(
              icon: _getIconForTitle(_recommendations[i]['title'] ?? ''),
              iconColor: _getColorForIndex(i),
              iconBgColor: isDark
                  ? _getColorForIndex(i).withOpacity(0.2)
                  : _getColorForIndex(i).withOpacity(0.1),
              title: _recommendations[i]['title'] ?? '',
              description: _recommendations[i]['description'] ?? '',
              isDark: isDark,
            ),
            if (i < _recommendations.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3F4549) : const Color(0xFFF3F4F6),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedByAI(bool isDark) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: isDark
                ? const Color(0xFF9CA3AF).withOpacity(0.7)
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 6),
          Text(
            _translate('generatedBy'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xFF9CA3AF).withOpacity(0.7)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1C1E).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.5)
                : const Color(0xFFE2E8F0),
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
          height: 88,
          padding: const EdgeInsets.only(bottom: 16, top: 0, left: 8, right: 8),
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
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                height: 32,
                width: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF45A191).withOpacity(0.2)
                      : const Color(0xFF45A191).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 26, color: const Color(0xFF45A191)),
              )
            else
              SizedBox(
                height: 32,
                width: 56,
                child: Center(
                  child: Icon(
                    icon,
                    size: 26,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF45A191)
                    : isDark
                    ? const Color(0xFF94A3B8)
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
