import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SwasthSetuAnalyticsApp());
}

class SwasthSetuAnalyticsApp extends StatefulWidget {
  const SwasthSetuAnalyticsApp({super.key});

  @override
  State<SwasthSetuAnalyticsApp> createState() => _SwasthSetuAnalyticsAppState();
}

class _SwasthSetuAnalyticsAppState extends State<SwasthSetuAnalyticsApp> {
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
      title: 'SwasthSetu Analytics',
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
      home: AnalyticsScreen(
        onThemeToggle: _toggleTheme,
        onLanguageChange: _changeLanguage,
        currentLanguage: _language,
      ),
    );
  }
}

class AnalyticsScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  const AnalyticsScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedIndex = 1; // Analytics tab
  String _selectedTimeframe = 'Today';
  bool _isLoading = true;
  bool _isOffline = false;

  // Summary data
  int _totalSteps = 0;
  int _totalCalories = 0;
  int _avgHeartRate = 0;
  int _restingHeartRate = 0;
  double _avgSleep = 0.0;
  String _sleepQuality = 'good';
  int _distance = 0;
  int _wellnessScore = 0; // Stored score to match dashboard behavior
  int _hydration = 0; // Manual hydration tracking in ml
  int _hydrationGoal = 2500; // Default 2.5L, can be set from 2.5L to 4L

  // Daily data for charts
  List<Map<String, dynamic>> _dailyData = [];
  List<int> _heartRateHistory = []; // For heart rate chart
  Timer? _midnightResetTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scheduleMidnightReset();
  }

  Future<void> _initializeData() async {
    // Load goals first, then fetch analytics data
    await _loadGoals();
    _loadHydration();
    _loadHydrationGoal();
    _fetchAnalyticsData();
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _stepsGoal = prefs.getInt('stepsGoal') ?? 10000;
          _sleepGoal = prefs.getDouble('sleepGoal') ?? 8.0;
          _distanceGoal = prefs.getInt('distanceGoal') ?? 5000;
        });
      }
    } catch (e) {
      // Use defaults if loading fails
    }
  }

  @override
  void dispose() {
    _midnightResetTimer?.cancel();
    super.dispose();
  }

  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    _midnightResetTimer = Timer(durationUntilMidnight, () {
      // Reset hydration at midnight
      setState(() => _hydration = 0);
      // Schedule next reset
      _scheduleMidnightReset();
    });
  }

  Future<void> _loadHydration() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _hydration = prefs.getInt('hydration_$today') ?? 0;
    });
  }

  Future<void> _saveHydration(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setInt('hydration_$today', amount);
  }

  Future<void> _loadHydrationGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hydrationGoal = prefs.getInt('hydration_goal') ?? 2500;
    });
  }

  Future<void> _saveHydrationGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hydration_goal', goal);
  }

  void _showHydrationDialog() {
    final TextEditingController controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int tempGoal = _hydrationGoal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C3035) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Water Intake',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF131615),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Daily Goal Setting
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Goal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          '${(tempGoal / 1000).toStringAsFixed(1)}L',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF0EA5E9),
                        inactiveTrackColor: const Color(
                          0xFF0EA5E9,
                        ).withOpacity(0.3),
                        thumbColor: const Color(0xFF0EA5E9),
                        overlayColor: const Color(0xFF0EA5E9).withOpacity(0.2),
                      ),
                      child: Slider(
                        value: tempGoal.toDouble(),
                        min: 2500,
                        max: 4000,
                        divisions: 6, // 2.5, 2.75, 3.0, 3.25, 3.5, 3.75, 4.0
                        onChanged: (value) {
                          setDialogState(() => tempGoal = value.round());
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '2.5L',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey : Colors.grey[600],
                          ),
                        ),
                        Text(
                          '4.0L',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Enter amount in ml',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey[600],
                  ),
                  suffixText: 'ml',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF3A3F45)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Quick add buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAddButton('250ml', 250, isDark),
                  _buildQuickAddButton('500ml', 500, isDark),
                  _buildQuickAddButton('1L', 1000, isDark),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Reset hydration
                setState(() => _hydration = 0);
                _saveHydration(0);
                Navigator.pop(context);
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(controller.text) ?? 0;
                if (amount > 0) {
                  setState(() => _hydration += amount);
                  _saveHydration(_hydration);
                }
                // Also save goal if changed
                if (tempGoal != _hydrationGoal) {
                  setState(() => _hydrationGoal = tempGoal);
                  _saveHydrationGoal(tempGoal);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButton(String label, int amount, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() => _hydration += amount);
        _saveHydration(_hydration);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0EA5E9).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0EA5E9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Calculate resting heart rate using scientific estimation
  // Resting HR is typically measured in the morning before activity
  // We estimate it based on average HR and sleep quality
  int _calculateRestingHeartRate(int avgHR) {
    if (avgHR == 0) return 0;

    // Base calculation: Resting HR is typically 70-80% of average daily HR
    // Good sleepers tend to have lower resting HR
    double multiplier = 0.75; // Base multiplier

    // Adjust based on sleep quality
    if (_sleepQuality == 'good') {
      multiplier = 0.72; // Better recovery = lower resting HR
    } else if (_sleepQuality == 'bad') {
      multiplier = 0.78; // Poor recovery = slightly higher
    }

    // Add small variation based on steps (more active = better cardiovascular health)
    if (_totalSteps > 8000) {
      multiplier -= 0.02; // Active people tend to have lower resting HR
    } else if (_totalSteps < 3000) {
      multiplier += 0.02; // Less active = slightly higher
    }

    int restingHR = (avgHR * multiplier).round();

    // Clamp to realistic resting HR range (50-100 bpm)
    return restingHR.clamp(50, 100);
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);

    // Reload goals to ensure they match dashboard (in case user changed them)
    await _loadGoals();

    // Sync Strava activities first to get latest data
    await ApiService.syncStravaActivities();

    Map<String, dynamic> result;

    if (_selectedTimeframe == 'Today') {
      // Fetch today's data
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      result = await ApiService.getHealthData(today);
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final avgHR = data['heartRateAvg'] ?? 0;
        final steps = data['steps'] ?? 0;
        final sleep = (data['sleep']?['duration'] ?? 0.0).toDouble();
        final distance = ((steps as int) * 0.75).round();

        // Calculate wellness score using same formula as dashboard
        final score = _calculateScoreFromValues(steps, sleep, distance);

        setState(() {
          _totalSteps = steps;
          _totalCalories = data['caloriesBurned'] ?? 0;
          _avgHeartRate = avgHR;
          _restingHeartRate = _calculateRestingHeartRate(avgHR);
          _avgSleep = sleep;
          _sleepQuality = data['sleep']?['quality'] ?? 'good';
          _distance = distance;
          _wellnessScore = score;
          _dailyData = [data];
          _heartRateHistory = [avgHR];
          _isLoading = false;
        });
      } else {
        setState(() {
          _totalSteps = 0;
          _totalCalories = 0;
          _avgHeartRate = 0;
          _restingHeartRate = 0;
          _avgSleep = 0.0;
          _sleepQuality = 'good';
          _distance = 0;
          _wellnessScore = 0;
          _dailyData = [];
          _heartRateHistory = [];
          _isLoading = false;
        });
      }
    } else if (_selectedTimeframe == 'Week') {
      result = await ApiService.getWeeklyAnalytics();
      _processAnalyticsResult(result);
    } else {
      result = await ApiService.getMonthlyAnalytics();
      _processAnalyticsResult(result);
    }
  }

  void _processAnalyticsResult(Map<String, dynamic> result) {
    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _isOffline = result['cached'] == true;
      });
      final data = result['data'];
      final summary = data['summary'] ?? {};
      final dailyData = List<Map<String, dynamic>>.from(
        data['dailyData'] ?? [],
      );

      // Get sleep quality from most recent day
      String quality = 'good';
      if (dailyData.isNotEmpty) {
        quality = dailyData.last['sleep']?['quality'] ?? 'good';
      }

      // Calculate total distance from steps
      int totalDistance = 0;
      for (var day in dailyData) {
        totalDistance += (((day['steps'] ?? 0) as num) * 0.75).round();
      }

      // Collect heart rate history for chart
      List<int> hrHistory = [];
      for (var day in dailyData) {
        hrHistory.add((day['heartRateAvg'] ?? 0) as int);
      }

      final avgHR = summary['avgHeartRate'] ?? 0;

      setState(() {
        _totalSteps = summary['totalSteps'] ?? 0;
        _totalCalories = summary['totalCaloriesBurned'] ?? 0;
        _avgHeartRate = avgHR;
        _restingHeartRate = _calculateRestingHeartRate(avgHR);
        _avgSleep = (summary['avgSleep'] ?? 0.0).toDouble();
        _sleepQuality = quality;
        _distance = totalDistance;
        _dailyData = dailyData;
        _heartRateHistory = hrHistory;
        _isLoading = false;
      });
    } else {
      setState(() {
        _totalSteps = 0;
        _totalCalories = 0;
        _avgHeartRate = 0;
        _restingHeartRate = 0;
        _avgSleep = 0.0;
        _sleepQuality = 'good';
        _distance = 0;
        _dailyData = [];
        _heartRateHistory = [];
        _isLoading = false;
      });
    }
  }

  // Customizable Goals - loaded from SharedPreferences (same as dashboard)
  int _stepsGoal = 10000;
  double _sleepGoal = 8.0;
  int _distanceGoal = 5000;

  // Helper method to calculate score from values (same formula as dashboard)
  int _calculateScoreFromValues(int steps, double sleep, int distance) {
    double score =
        (steps.toDouble() / _stepsGoal.toDouble() * 40.0) +
        (sleep / _sleepGoal * 30.0) +
        (distance.toDouble() / _distanceGoal.toDouble() * 30.0);
    return score.clamp(0, 100).toInt();
  }

  int _calculateWellnessScore() {
    // For Today: return stored score (calculated at fetch time, same as dashboard)
    if (_selectedTimeframe == 'Today') {
      return _wellnessScore;
    }

    // For Week/Month: calculate aggregated score
    if (_totalSteps == 0 && _avgSleep == 0 && _avgHeartRate == 0) return 0;

    // For Week/Month: Use aggregated goals and include heart rate
    int stepsGoal = _selectedTimeframe == 'Week' ? 70000 : 300000;
    double sleepGoal = _sleepGoal; // Average sleep goal stays the same

    double stepsScore = (_totalSteps / stepsGoal * 100).clamp(0, 100);
    double sleepScore = (_avgSleep / sleepGoal * 100).clamp(0, 100);

    // Heart rate: optimal range 60-100
    double hrScore = 100.0;
    if (_avgHeartRate > 0) {
      if (_avgHeartRate < 60) {
        hrScore = (_avgHeartRate / 60 * 100).clamp(0.0, 100.0);
      } else if (_avgHeartRate > 100) {
        hrScore = (100.0 - (_avgHeartRate - 100)).clamp(0.0, 100.0);
      }
    }

    // Weighted average for week/month
    double score = (stepsScore * 0.35 + sleepScore * 0.35 + hrScore * 0.30);
    return score.round();
  }

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'analytics': 'Analytics',
      'today': 'Today',
      'week': 'Week',
      'month': 'Month',
      'overallWellness': 'Overall Wellness',
      'wellnessDesc':
          "Your biometrics are looking stable. You're doing 15% better than last week.",
      'activityLevel': 'Activity Level',
      'stepsAvg': 'steps avg',
      'restingHeartRate': 'Resting Heart Rate',
      'bpm': 'bpm',
      'sleepQuality': 'Sleep Quality',
      'good': 'Good',
      'bad': 'Needs Improvement',
      'moderate': 'Moderate',
      'hydration': 'Hydration',
      'ml': 'ml',
      'vsYest': 'vs yest.',
      'weeklyInsight': 'Weekly Insight',
      'insightText':
          'Your activity peaked on Thursday. Maintaining this consistency could improve your sleep score by ~10%.',
      'home': 'Home',
      'aiSummary': 'AI Summary',
      'history': 'History',
      'profile': 'Profile',
      'score': 'Score',
      'caloriesBurned': 'Calories Burned',
      'kcal': 'kcal',
      'distance': 'Distance',
      'km': 'km',
      'weeklyProgress': 'Weekly Progress',
      'sleepTrend': 'Sleep Trend',
      'hours': 'hours',
      'caloriesTrend': 'Calories Trend',
      'heartRateTrend': 'Heart Rate Trend',
    },
    'Hindi': {
      'analytics': 'विश्लेषण',
      'today': 'आज',
      'week': 'सप्ताह',
      'month': 'महीना',
      'overallWellness': 'समग्र कल्याण',
      'wellnessDesc':
          'आपके बायोमेट्रिक्स स्थिर दिख रहे हैं। आप पिछले सप्ताह से 15% बेहतर कर रहे हैं।',
      'activityLevel': 'गतिविधि स्तर',
      'stepsAvg': 'कदम औसत',
      'restingHeartRate': 'विश्राम हृदय गति',
      'bpm': 'BPM',
      'sleepQuality': 'नींद की गुणवत्ता',
      'good': 'अच्छा',
      'bad': 'सुधार की आवश्यकता',
      'moderate': 'मध्यम',
      'hydration': 'जलयोजन',
      'ml': 'ml',
      'vsYest': 'बनाम कल',
      'weeklyInsight': 'साप्ताहिक अंतर्दृष्टि',
      'insightText':
          'गुरुवार को आपकी गतिविधि चरम पर थी। इस निरंतरता को बनाए रखने से आपके नींद स्कोर में ~10% सुधार हो सकता है।',
      'home': 'होम',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफ़ाइल',
      'score': 'स्कोर',
      'caloriesBurned': 'कैलोरी बर्न',
      'kcal': 'kcal',
      'distance': 'दूरी',
      'km': 'km',
      'weeklyProgress': 'साप्ताहिक प्रगति',
      'sleepTrend': 'नींद का रुझान',
      'hours': 'घंटे',
      'caloriesTrend': 'कैलोरी रुझान',
      'heartRateTrend': 'हृदय गति रुझान',
    },
    'Marathi': {
      'analytics': 'विश्लेषण',
      'today': 'आज',
      'week': 'आठवडा',
      'month': 'महिना',
      'overallWellness': 'एकूण आरोग्य',
      'wellnessDesc':
          'तुमचे बायोमेट्रिक्स स्थिर दिसत आहेत. तुम्ही मागील आठवड्यापेक्षा 15% चांगले करत आहात.',
      'activityLevel': 'क्रियाकलाप पातळी',
      'stepsAvg': 'पावले सरासरी',
      'restingHeartRate': 'विश्रांती हृदय गती',
      'bpm': 'BPM',
      'sleepQuality': 'झोपेची गुणवत्ता',
      'good': 'चांगले',
      'bad': 'सुधारणा आवश्यक',
      'moderate': 'मध्यम',
      'hydration': 'जलयोजन',
      'ml': 'ml',
      'vsYest': 'काल विरुद्ध',
      'weeklyInsight': 'साप्ताहिक अंतर्दृष्टी',
      'insightText':
          'गुरुवारी तुमची क्रियाकलाप शिखरावर होती. ही सातत्य राखल्याने तुमच्या झोपेच्या स्कोअरमध्ये ~10% सुधारणा होऊ शकते.',
      'home': 'होम',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफाइल',
      'score': 'स्कोअर',
      'caloriesBurned': 'कॅलरीज बर्न',
      'kcal': 'kcal',
      'distance': 'अंतर',
      'km': 'km',
      'weeklyProgress': 'साप्ताहिक प्रगती',
      'sleepTrend': 'झोपेचा ट्रेंड',
      'hours': 'तास',
      'caloriesTrend': 'कॅलरी ट्रेंड',
      'heartRateTrend': 'हृदय गती ट्रेंड',
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
            const SizedBox(height: 16),
            _buildTimeframeSelector(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF45A191),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                      child: Column(
                        children: [
                          _buildOverallWellnessCard(isDark),
                          const SizedBox(height: 16),
                          _buildActivityLevelCard(isDark),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildCaloriesCard(isDark)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDistanceCard(isDark)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildHeartRateCard(isDark),
                          const SizedBox(height: 16),
                          _buildSleepTrendCard(isDark),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildSleepQualityCard(isDark)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildHydrationCard(isDark)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildWeeklyInsightCard(isDark),
                          const SizedBox(height: 32),
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
            .withOpacity(0.9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 80),
          Text(
            _translate('analytics'),
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
              const SizedBox(width: 8),
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
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isDark ? Colors.white : const Color(0xFF131615),
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector(bool isDark) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3F45) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(child: _buildTimeframeOption('Today', isDark)),
          Expanded(child: _buildTimeframeOption('Week', isDark)),
          Expanded(child: _buildTimeframeOption('Month', isDark)),
        ],
      ),
    );
  }

  Widget _buildTimeframeOption(String option, bool isDark) {
    final isSelected = _selectedTimeframe == option;
    final translatedOption = _translate(option.toLowerCase());

    return GestureDetector(
      onTap: () {
        if (_selectedTimeframe != option) {
          setState(() => _selectedTimeframe = option);
          _fetchAnalyticsData();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF45A191) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF45A191).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            translatedOption,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF6C7F7C),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallWellnessCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3F45) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: _calculateWellnessScore() / 100,
                primaryColor: const Color(0xFF45A191),
                backgroundColor: isDark
                    ? const Color(0xFF3A3F45)
                    : const Color(0xFFF1F3F3),
                strokeWidth: 8,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_calculateWellnessScore()}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF45A191),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _translate('score').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C7F7C),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF45A191).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFF45A191),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _translate('overallWellness'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF131615),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _translate('wellnessDesc'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6C7F7C),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLevelCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3F45) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                    _translate('activityLevel'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF6C7F7C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        NumberFormat('#,###').format(_totalSteps),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF131615),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _translate('stepsAvg'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6C7F7C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_dailyData.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF059669),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_dailyData.length} days',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildActivityBars(isDark),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityBars(bool isDark) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0 = Monday

    // Find max steps for normalization
    int maxSteps = 10000;
    for (var data in _dailyData) {
      if ((data['steps'] ?? 0) > maxSteps) {
        maxSteps = data['steps'];
      }
    }

    return List.generate(7, (index) {
      double height = 0.0;
      bool isToday = index == todayIndex && _selectedTimeframe != 'Month';

      // Find matching data for this day
      for (var data in _dailyData) {
        try {
          final date = DateTime.parse(data['date']);
          if (date.weekday - 1 == index) {
            height = (data['steps'] ?? 0) / maxSteps;
            break;
          }
        } catch (_) {}
      }

      return _buildBarChart(days[index], height, isDark, isToday);
    });
  }

  Widget _buildBarChart(String day, double height, bool isDark, bool isToday) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      height: constraints.maxHeight * height,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF45A191)
                            : const Color(0xFF45A191).withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF45A191,
                                  ).withOpacity(0.4),
                                  blurRadius: 15,
                                ),
                              ]
                            : [],
                      ),
                      child: isToday
                          ? null
                          : Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF45A191).withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday
                  ? const Color(0xFF45A191)
                  : const Color(0xFF6C7F7C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard(bool isDark) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3F45) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Color(0xFFEA580C),
              size: 24,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate('caloriesBurned').toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C7F7C),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    NumberFormat('#,###').format(_totalCalories),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF131615),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _translate('kcal'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6C7F7C),
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

  Widget _buildDistanceCard(bool isDark) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3F45) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_run,
              color: Color(0xFF8B5CF6),
              size: 24,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate('distance').toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C7F7C),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    NumberFormat('#,###').format(_distance),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF131615),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'm',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6C7F7C),
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

  Widget _buildHeartRateCard(bool isDark) {
    // Determine heart rate status
    String hrStatus = 'Normal';
    Color statusColor = const Color(0xFF10B981);
    if (_restingHeartRate > 0) {
      if (_restingHeartRate < 60) {
        hrStatus = 'Low';
        statusColor = const Color(0xFF0EA5E9);
      } else if (_restingHeartRate > 100) {
        hrStatus = 'High';
        statusColor = const Color(0xFFEF4444);
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3F45) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translate('restingHeartRate'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6C7F7C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_restingHeartRate',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF131615),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _translate('bpm'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6C7F7C),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hrStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg: $_avgHeartRate bpm',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6C7F7C),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFE11D48).withOpacity(0.2)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFE11D48),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: DynamicHeartRateChartPainter(
                color: const Color(0xFFE11D48),
                isDark: isDark,
                dailyData: _dailyData,
                restingHR: _restingHeartRate,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildHeartRateDayLabels(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHeartRateDayLabels() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days
        .map(
          (day) => Text(
            day,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C7F7C),
            ),
          ),
        )
        .toList();
  }

  Widget _buildSleepTrendCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3F45) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                    _translate('sleepTrend'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF6C7F7C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _avgSleep.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF131615),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _translate('hours'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6C7F7C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _sleepQuality == 'good'
                      ? (isDark
                            ? const Color(0xFF10B981).withOpacity(0.2)
                            : const Color(0xFFD1FAE5))
                      : (isDark
                            ? const Color(0xFFEF4444).withOpacity(0.2)
                            : const Color(0xFFFEE2E2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _translate(_sleepQuality),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _sleepQuality == 'good'
                        ? (isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF059669))
                        : (isDark
                              ? const Color(0xFFF87171)
                              : const Color(0xFFDC2626)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildSleepBars(isDark),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSleepBars(bool isDark) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;

    return List.generate(7, (index) {
      double hours = 0.0;
      bool isToday = index == todayIndex && _selectedTimeframe != 'Month';

      for (var data in _dailyData) {
        try {
          final date = DateTime.parse(data['date']);
          if (date.weekday - 1 == index) {
            hours = (data['sleep']?['duration'] ?? 0.0).toDouble();
            break;
          }
        } catch (_) {}
      }

      return _buildSleepBar(days[index], hours, isDark, isToday);
    });
  }

  Widget _buildSleepBar(String day, double hours, bool isDark, bool isToday) {
    final height = hours / 10;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      height: constraints.maxHeight * height,
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF6366F1).withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ]
                            : [],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF6C7F7C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQualityCard(bool isDark) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3F45) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.bedtime, color: Color(0xFF6366F1), size: 28),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _sleepQuality == 'good'
                        ? (isDark
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : const Color(0xFFD1FAE5))
                        : (isDark
                              ? const Color(0xFFEF4444).withOpacity(0.2)
                              : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _translate(_sleepQuality),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _sleepQuality == 'good'
                          ? (isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF059669))
                          : (isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626)),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate('sleepQuality').toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C7F7C),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_avgSleep.floor()}h ${((_avgSleep - _avgSleep.floor()) * 60).round()}m',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF131615),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_avgSleep / 8.0).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: isDark
                      ? const Color(0xFF3A3F45)
                      : const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _sleepQuality == 'good'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationCard(bool isDark) {
    final hydrationGoal = _hydrationGoal; // User-configurable goal (2.5L-4L)
    final progress = (_hydration / hydrationGoal).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return GestureDetector(
      onTap: _showHydrationDialog,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C3035) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3F45) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(
                Icons.water_drop,
                color: const Color(0xFF0EA5E9).withOpacity(isDark ? 0.05 : 0.1),
                size: 100,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.water_drop,
                      color: Color(0xFF0EA5E9),
                      size: 28,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFF0EA5E9),
                        size: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translate('hydration').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6C7F7C),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          NumberFormat('#,###').format(_hydration),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF131615),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _translate('ml'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6C7F7C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage% of ${(hydrationGoal / 1000).toStringAsFixed(1)}L goal',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: isDark
                            ? const Color(0xFF3A3F45)
                            : const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0EA5E9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyInsightCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A302D) : const Color(0xFFE8F3F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF45A191), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate('weeklyInsight'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF131615),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _translate('insightText'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6C7F7C),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2226) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.5)
                : const Color(0xFFE2E8F0),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                icon: Icons.auto_awesome_outlined,
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF45A191,
                  ).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 24, color: const Color(0xFF45A191)),
              )
            else
              Icon(icon, size: 24, color: const Color(0xFF6C7F7C)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF45A191)
                    : const Color(0xFF6C7F7C),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeartRateChartPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  HeartRateChartPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final points = <Offset>[];
    final dataPoints = 60;

    for (int i = 0; i < dataPoints; i++) {
      final x = (width / (dataPoints - 1)) * i;
      final normalizedX = i / dataPoints;
      final y = height * (0.5 + 0.25 * math.sin(normalizedX * 3 * math.pi + 1));
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(0, height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(width, height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.2), color.withOpacity(0)],
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height))
        ..style = PaintingStyle.fill,
    );

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastPoint = points.last;
    canvas.drawCircle(
      lastPoint,
      4,
      Paint()
        ..color = (isDark ? const Color(0xFF2C3035) : Colors.white)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      lastPoint,
      4,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Dynamic Heart Rate Chart that uses actual data
class DynamicHeartRateChartPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final List<Map<String, dynamic>> dailyData;
  final int restingHR;

  DynamicHeartRateChartPainter({
    required this.color,
    required this.isDark,
    required this.dailyData,
    required this.restingHR,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    if (dailyData.isEmpty) {
      // Draw "No data" message
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'No heart rate data',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6C7F7C),
            fontSize: 14,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (width - textPainter.width) / 2,
          (height - textPainter.height) / 2,
        ),
      );
      return;
    }

    // Extract valid heart rate data
    final validData = dailyData
        .where((d) => (d['heartRateAvg'] ?? 0) > 0)
        .map((d) => (d['heartRateAvg'] ?? 0) as int)
        .toList();
    if (validData.isEmpty) return;

    // Find min and max for scaling
    int minHR = validData.reduce((a, b) => a < b ? a : b);
    int maxHR = validData.reduce((a, b) => a > b ? a : b);

    // Add padding to range
    if (minHR == maxHR) {
      minHR = (minHR * 0.8).round();
      maxHR = (maxHR * 1.2).round();
    }
    final range = maxHR - minHR;
    final padding = range * 0.2;
    minHR = (minHR - padding).round();
    maxHR = (maxHR + padding).round();

    // Draw resting HR reference line
    if (restingHR > 0 && restingHR >= minHR && restingHR <= maxHR) {
      final restingY =
          height - ((restingHR - minHR) / (maxHR - minHR)) * height;
      final dashPaint = Paint()
        ..color = const Color(0xFF6C7F7C).withOpacity(0.5)
        ..strokeWidth = 1;

      // Draw dashed line
      double startX = 0;
      while (startX < width) {
        canvas.drawLine(
          Offset(startX, restingY),
          Offset(startX + 5, restingY),
          dashPaint,
        );
        startX += 10;
      }
    }

    // Create points from data matching weekdays (Monday=0 to Sunday=6)
    final List<Offset> points = [];
    final dataPoints = 7;

    for (int i = 0; i < dataPoints; i++) {
      final x = (width / (dataPoints - 1)) * i;

      // Find data for this weekday
      int? hrValue;
      for (var data in dailyData) {
        try {
          final date = DateTime.parse(data['date']);
          if (date.weekday - 1 == i) {
            hrValue = (data['heartRateAvg'] ?? 0) as int;
            break;
          }
        } catch (_) {}
      }

      if (hrValue != null && hrValue > 0) {
        final normalizedValue = (hrValue - minHR) / (maxHR - minHR);
        final y = height - (normalizedValue * height);
        points.add(Offset(x, y.clamp(0, height)));
      }
      // Skip days with no data - don't add a point
    }

    // Handle single point case (Today mode)
    if (points.length == 1) {
      final point = points[0];

      // Draw a centered point with fill effect
      final centerX = width / 2;
      final centerY = point.dy;

      // Draw fill gradient under the point
      final fillPath = Path()
        ..moveTo(0, height)
        ..lineTo(0, centerY + 20)
        ..quadraticBezierTo(centerX, centerY - 10, width, centerY + 20)
        ..lineTo(width, height)
        ..close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0)],
      );
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height))
          ..style = PaintingStyle.fill,
      );

      // Draw the data point in center
      canvas.drawCircle(
        Offset(centerX, centerY),
        8,
        Paint()
          ..color = (isDark ? const Color(0xFF2C3035) : Colors.white)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(centerX, centerY),
        8,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      // Draw "Today" label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Today',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6C7F7C),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, height - 14),
      );
      return;
    }

    // Need at least 2 points to draw a line
    if (points.isEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Insufficient data',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6C7F7C),
            fontSize: 14,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (width - textPainter.width) / 2,
          (height - textPainter.height) / 2,
        ),
      );
      return;
    }

    // Draw fill gradient
    final fillPath = Path()..moveTo(0, height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(width, height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.3), color.withOpacity(0)],
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height))
        ..style = PaintingStyle.fill,
    );

    // Draw line
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      // Smooth curve using quadratic bezier
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      path.quadraticBezierTo(prev.dx, prev.dy, midX, (prev.dy + curr.dy) / 2);
    }
    path.lineTo(points.last.dx, points.last.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw data points
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(
        points[i],
        4,
        Paint()
          ..color = (isDark ? const Color(0xFF2C3035) : Colors.white)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        points[i],
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DynamicHeartRateChartPainter oldDelegate) {
    return oldDelegate.dailyData != dailyData ||
        oldDelegate.restingHR != restingHR ||
        oldDelegate.isDark != isDark;
  }
}
