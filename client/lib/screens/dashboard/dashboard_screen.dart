import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import sub-pages correctly
import '../Analytics/analytics_screen.dart';
import '../Ai_summary/summary_screen.dart';
import '../profile_page/profile_page.dart';
import '../History_page/history_page.dart';
import '../gamification/gamification_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChange;
  final String currentLanguage;
  final int initialTab;

  const DashboardScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.currentLanguage,
    this.initialTab = 0,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;
  bool _isLoading = true;
  bool _isOffline = false;
  String _userName = 'User';
  DateTime _selectedDate = DateTime.now();
  DateTime? _lastBackPress;

  // Data Variables mapped to your UI
  int _steps = 0;
  double _sleepDuration = 0.0;
  int _distance = 0;
  int _heartRate = 0;
  int _healthScore = 0;

  // Customizable Goals
  int _stepsGoal = 10000;
  double _sleepGoal = 8.0;
  int _distanceGoal = 5000;

  // Appointments list
  List<Map<String, dynamic>> _appointments = [];
  Timer? _appointmentExpiryTimer;

  // Health tips rotation
  int _currentHealthTipIndex = 0;
  Timer? _healthTipTimer;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _loadUserName();
    _loadGoals();
    _loadAppointments();
    _fetchDataForDate(_selectedDate);
    // Check for expired appointments every minute
    _appointmentExpiryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _removeExpiredAppointments(),
    );
    // Rotate health tips every 30 seconds
    _healthTipTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _rotateHealthTip(),
    );
  }

  void _rotateHealthTip() {
    if (!mounted) return;
    setState(() {
      _currentHealthTipIndex =
          (_currentHealthTipIndex + 1) % _healthTips.length;
    });
  }

  @override
  void dispose() {
    _appointmentExpiryTimer?.cancel();
    _healthTipTimer?.cancel();
    super.dispose();
  }

  // 25 Health Tips
  final List<Map<String, String>> _healthTips = [
    {
      'tip':
          'Drink 8 glasses of water daily for better hydration and improved skin health.',
      'info':
          'Water helps flush out toxins, improves digestion, maintains body temperature, and keeps your skin glowing. Aim for 2-3 liters per day.',
    },
    {
      'tip':
          'Take a 10-minute walk after meals to aid digestion and control blood sugar.',
      'info':
          'Post-meal walking helps reduce blood sugar spikes, improves metabolism, and aids in better digestion. It can reduce the risk of type 2 diabetes.',
    },
    {
      'tip':
          'Get 7-8 hours of quality sleep each night for optimal brain function.',
      'info':
          'Sleep is crucial for memory consolidation, immune function, and mental health. Lack of sleep increases risk of obesity, diabetes, and heart disease.',
    },
    {
      'tip':
          'Practice deep breathing for 5 minutes daily to reduce stress and anxiety.',
      'info':
          'Deep breathing activates the parasympathetic nervous system, lowering cortisol levels and blood pressure. It improves oxygen flow and mental clarity.',
    },
    {
      'tip':
          'Eat a rainbow of fruits and vegetables for essential vitamins and minerals.',
      'info':
          'Different colored produce provides different antioxidants and nutrients. Aim for 5-9 servings daily to reduce disease risk and boost immunity.',
    },
    {
      'tip':
          'Limit processed sugar intake to reduce inflammation and disease risk.',
      'info':
          'Excess sugar contributes to obesity, diabetes, heart disease, and inflammation. Stick to natural sugars from fruits and limit added sugars to 25g/day.',
    },
    {
      'tip': 'Stand up and stretch every hour if you have a desk job.',
      'info':
          'Prolonged sitting increases risk of obesity, diabetes, and cardiovascular disease. Regular movement improves circulation and reduces muscle tension.',
    },
    {
      'tip':
          'Include protein in every meal to maintain muscle mass and feel fuller longer.',
      'info':
          'Protein is essential for muscle repair, hormone production, and satiety. Aim for 0.8-1g per kg of body weight from lean meats, fish, legumes, and dairy.',
    },
    {
      'tip': 'Wash your hands frequently to prevent the spread of infections.',
      'info':
          'Hand hygiene is the single most effective way to prevent disease transmission. Wash for 20 seconds with soap, especially before eating and after restroom use.',
    },
    {
      'tip': 'Limit screen time before bed to improve sleep quality.',
      'info':
          'Blue light from screens suppresses melatonin production, disrupting sleep. Stop using devices 1-2 hours before bedtime for better rest.',
    },
    {
      'tip': 'Practice gratitude daily to boost mental health and happiness.',
      'info':
          'Gratitude journaling reduces stress, improves mood, and increases resilience. Write down 3 things you\'re grateful for each day.',
    },
    {
      'tip':
          'Eat mindfully without distractions to improve digestion and prevent overeating.',
      'info':
          'Mindful eating helps you recognize hunger and fullness cues, improves nutrient absorption, and enhances your relationship with food.',
    },
    {
      'tip':
          'Include healthy fats like nuts, avocados, and olive oil in your diet.',
      'info':
          'Healthy fats support brain function, hormone production, and nutrient absorption. They reduce inflammation and support heart health.',
    },
    {
      'tip': 'Stay socially connected to reduce stress and improve longevity.',
      'info':
          'Strong social bonds lower rates of anxiety, depression, and boost immune function. Regular interaction with loved ones is as important as exercise.',
    },
    {
      'tip':
          'Limit alcohol consumption to maintain liver health and overall wellness.',
      'info':
          'Excessive alcohol damages the liver, increases cancer risk, and affects mental health. Stick to moderate drinking: up to 1 drink/day for women, 2 for men.',
    },
    {
      'tip':
          'Take regular breaks from work to prevent burnout and boost productivity.',
      'info':
          'The brain needs downtime to process information and maintain focus. Use the 52-17 rule: 52 minutes of work, 17-minute break.',
    },
    {
      'tip':
          'Eat breakfast within an hour of waking to jumpstart your metabolism.',
      'info':
          'A healthy breakfast stabilizes blood sugar, improves concentration, and provides energy. Include protein, complex carbs, and healthy fats.',
    },
    {
      'tip':
          'Practice good posture to prevent back pain and improve breathing.',
      'info':
          'Poor posture strains muscles, compresses organs, and restricts breathing. Keep shoulders back, chin up, and core engaged while sitting and standing.',
    },
    {
      'tip':
          'Reduce salt intake to lower blood pressure and protect heart health.',
      'info':
          'Excess sodium increases blood pressure and fluid retention. Limit to 2,300mg/day (1 teaspoon) by avoiding processed foods and reading labels.',
    },
    {
      'tip':
          'Exercise for at least 30 minutes daily to boost cardiovascular health.',
      'info':
          'Regular physical activity strengthens the heart, improves circulation, boosts mood, and reduces risk of chronic diseases. Mix cardio and strength training.',
    },
    {
      'tip':
          'Maintain a healthy weight through balanced diet and regular exercise.',
      'info':
          'Healthy weight reduces risk of diabetes, heart disease, and joint problems. Focus on sustainable lifestyle changes rather than quick fixes.',
    },
    {
      'tip': 'Get regular health checkups to catch potential issues early.',
      'info':
          'Preventive care helps detect diseases in early stages when treatment is most effective. Annual physicals, screenings, and dental visits are essential.',
    },
    {
      'tip':
          'Spend time in nature to reduce stress and improve mental clarity.',
      'info':
          'Nature exposure lowers cortisol, reduces anxiety, and improves mood. Even 20 minutes outdoors can boost well-being and creativity.',
    },
    {
      'tip':
          'Limit caffeine intake, especially in the afternoon, for better sleep.',
      'info':
          'Caffeine has a half-life of 5-6 hours. Consuming it late can disrupt sleep. Limit to 400mg/day (4 cups) and stop by 2 PM.',
    },
    {
      'tip':
          'Practice yoga or meditation to improve flexibility and mental peace.',
      'info':
          'Yoga combines physical movement, breathing, and meditation to reduce stress, improve flexibility, and enhance mind-body connection.',
    },
  ];

  void _showAllHealthTips(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF2C3035) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '💡 All Health Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF131615),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: _healthTips.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final tip = _healthTips[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF45A191).withOpacity(0.1),
                            const Color(0xFF45A191).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF45A191).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF45A191),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tip['tip']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 42),
                            child: Text(
                              tip['info']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF45A191),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      if (kDebugMode) print('Error loading goals: $e');
    }
  }

  // Appointments Management
  DateTime _parseAppointmentDateTime(Map<String, dynamic> apt) {
    final date = DateTime.parse(apt['date']);
    // Parse time - stored as hour and minute
    final hour = apt['hour'] as int? ?? 0;
    final minute = apt['minute'] as int? ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  // Check if appointment time has passed
  bool _isAppointmentElapsed(Map<String, dynamic> apt) {
    final aptDateTime = _parseAppointmentDateTime(apt);
    return DateTime.now().isAfter(aptDateTime);
  }

  void _removeExpiredAppointments() {
    if (!mounted || _appointments.isEmpty) return;

    final now = DateTime.now();
    // Keep appointments for 24 hours after their scheduled time
    final validAppointments = _appointments.where((apt) {
      final aptDateTime = _parseAppointmentDateTime(apt);
      final expiryTime = aptDateTime.add(const Duration(hours: 24));
      return now.isBefore(expiryTime);
    }).toList();

    if (validAppointments.length != _appointments.length) {
      setState(() => _appointments = validAppointments);
      _saveAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsJson = prefs.getString('appointments');
      if (appointmentsJson != null && mounted) {
        final List<dynamic> decoded = jsonDecode(appointmentsJson);
        final now = DateTime.now();

        // Filter out appointments older than 24 hours past their time
        final validAppointments = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .where((apt) {
              final aptDateTime = _parseAppointmentDateTime(apt);
              final expiryTime = aptDateTime.add(const Duration(hours: 24));
              return now.isBefore(expiryTime);
            })
            .toList();

        // Sort by date and time
        validAppointments.sort((a, b) {
          final aDateTime = _parseAppointmentDateTime(a);
          final bDateTime = _parseAppointmentDateTime(b);
          return aDateTime.compareTo(bDateTime);
        });

        setState(() => _appointments = validAppointments);

        // Save filtered list if any were removed
        if (validAppointments.length != decoded.length) {
          _saveAppointments();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading appointments: $e');
    }
  }

  Future<void> _saveAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appointments', jsonEncode(_appointments));
    } catch (e) {
      if (kDebugMode) print('Error saving appointments: $e');
    }
  }

  void _addAppointment(Map<String, dynamic> appointment) {
    setState(() {
      _appointments.add(appointment);
      _appointments.sort((a, b) {
        final aDateTime = _parseAppointmentDateTime(a);
        final bDateTime = _parseAppointmentDateTime(b);
        return aDateTime.compareTo(bDateTime);
      });
    });
    _saveAppointments();
  }

  void _deleteAppointment(int index) {
    setState(() => _appointments.removeAt(index));
    _saveAppointments();
  }

  void _showAddAppointmentDialog(bool isDark) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    // Default to today, with time set to current + 30 minutes
    DateTime selectedDate = DateTime.now();
    final now = TimeOfDay.now();
    TimeOfDay selectedTime = TimeOfDay(
      hour: (now.hour + (now.minute >= 30 ? 1 : 0)) % 24,
      minute: now.minute >= 30 ? 0 : 30,
    );
    Color selectedColor = const Color(0xFF45A191);

    final colors = [
      const Color(0xFF45A191),
      const Color(0xFF4F46E5),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C3035) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _translate('add Appointment'),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF131615),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Title (e.g., Dr. Smith)',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey[600],
                    ),
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
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Description (e.g., General Checkup)',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey[600],
                    ),
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
                  ),
                ),
                const SizedBox(height: 16),
                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: selectedColor),
                  title: Text(
                    DateFormat('MMM dd, yyyy').format(selectedDate),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                // Time Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.access_time, color: selectedColor),
                  title: Text(
                    selectedTime.format(context),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Color Selection
                Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: colors.map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
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
                if (titleController.text.isNotEmpty) {
                  final timeStr = selectedTime.format(context);
                  _addAppointment({
                    'date': selectedDate.toIso8601String().split('T')[0],
                    'hour': selectedTime.hour,
                    'minute': selectedTime.minute,
                    'time': timeStr,
                    'title': '$timeStr - ${titleController.text}',
                    'subtitle': subtitleController.text.isEmpty
                        ? 'Appointment'
                        : subtitleController.text,
                    'color': selectedColor.value,
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF45A191),
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

  void _showDeleteConfirmation(int index, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C3035) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Appointment?',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF131615),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this appointment?',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteAppointment(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoal(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (e) {
      if (kDebugMode) print('Error saving goal: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('userName') ?? 'User';
      if (mounted) setState(() => _userName = name);
    } catch (e) {
      if (kDebugMode) print('Error loading user name: $e');
    }
  }

  Future<void> _fetchDataForDate(DateTime date) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String dateStr = DateFormat('yyyy-MM-dd').format(date);

    try {
      // Sync Strava activities first to get latest data
      await ApiService.syncStravaActivities();

      final result = await ApiService.getHealthData(dateStr);
      if (mounted && result['success']) {
        setState(() {
          _isOffline = result['cached'] == true;
        });
        final data = result['data'];
        if (data != null) {
          final steps = data['steps'] ?? 0;
          final sleepDuration = (data['sleep']?['duration'] ?? 0).toDouble();
          final heartRate = data['heartRateAvg'] ?? 0;

          setState(() {
            _steps = steps;
            _sleepDuration = sleepDuration;
            _distance = (steps * 0.75)
                .round(); // Calculate distance from steps (0.75m per step)
            _heartRate = heartRate;
            _healthScore = _calculateScore(_steps, _sleepDuration, _distance);
          });

          // Check health data and trigger notifications if needed (only for today)
          if (DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now())) {
            // Cache health data for background notifications
            NotificationService.cacheHealthData(
              steps: steps,
              heartRate: heartRate,
              sleepHours: sleepDuration,
            );

            // Check and send notifications
            NotificationService.checkHealthAndNotify(
              steps: steps,
              heartRate: heartRate,
              sleepHours: sleepDuration,
            );
          }
        } else {
          // No data for this date, reset values
          setState(() {
            _steps = 0;
            _sleepDuration = 0.0;
            _distance = 0;
            _heartRate = 0;
            _healthScore = 0;
          });
        }
      } else {
        // API call failed or no data, reset values
        setState(() {
          _steps = 0;
          _sleepDuration = 0.0;
          _distance = 0;
          _heartRate = 0;
          _healthScore = 0;
        });
      }
    } catch (e) {
      if (kDebugMode) print("DASHBOARD_DEBUG: Exception: $e");
      // On error, reset values
      if (mounted) {
        setState(() {
          _steps = 0;
          _sleepDuration = 0.0;
          _distance = 0;
          _heartRate = 0;
          _healthScore = 0;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDateSelected(DateTime date) {
    if (date.isAfter(DateTime.now())) return; // Don't allow future dates
    setState(() => _selectedDate = date);
    _fetchDataForDate(date);
  }

  int _calculateScore(int steps, double sleep, int distance) {
    // Use explicit toDouble() to ensure floating point division
    double score =
        (steps.toDouble() / _stepsGoal.toDouble() * 40.0) +
        (sleep / _sleepGoal * 30.0) +
        (distance.toDouble() / _distanceGoal.toDouble() * 30.0);
    return score.clamp(0, 100).toInt();
  }

  void _showGoalEditDialog(String type, bool isDark) {
    final controller = TextEditingController();
    String title;
    String hint;
    String suffix;

    switch (type) {
      case 'steps':
        controller.text = _stepsGoal.toString();
        title = 'Set Steps Goal';
        hint = 'Enter daily steps goal';
        suffix = 'steps';
        break;
      case 'sleep':
        controller.text = _sleepGoal.toString();
        title = 'Set Sleep Goal';
        hint = 'Enter sleep goal in hours';
        suffix = 'hours';
        break;
      case 'distance':
        controller.text = _distanceGoal.toString();
        title = 'Set Distance Goal';
        hint = 'Enter distance goal in meters';
        suffix = 'meters';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C3035) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            hintStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.black38,
            ),
            suffixStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF45A191), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = type == 'sleep'
                  ? double.tryParse(controller.text)
                  : int.tryParse(controller.text);
              if (value != null && value > 0) {
                setState(() {
                  switch (type) {
                    case 'steps':
                      _stepsGoal = value as int;
                      _saveGoal('stepsGoal', _stepsGoal);
                      break;
                    case 'sleep':
                      _sleepGoal = value as double;
                      _saveGoal('sleepGoal', _sleepGoal);
                      break;
                    case 'distance':
                      _distanceGoal = value as int;
                      _saveGoal('distanceGoal', _distanceGoal);
                      break;
                  }
                  _healthScore = _calculateScore(
                    _steps,
                    _sleepDuration,
                    _distance,
                  );
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF45A191),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  final Map<String, Map<String, String>> _translations = {
    'English': {
      'dashboard': 'SwasthSetu',
      'healthScore': 'Health Score',
      'greatCondition': 'Great condition',
      'excellentCondition': 'Excellent condition',
      'goodCondition': 'Good condition',
      'fairCondition': 'Fair condition',
      'poorCondition': 'Poor condition',
      'criticalCondition': 'Needs attention',
      'steps': 'Steps',
      'sleep': 'Sleep',
      'distance': 'Distance',
      'bpm': 'BPM',
      'home': 'Home',
      'analytics': 'Analytics',
      'aiSummary': 'AI Summary',
      'history': 'History',
      'profile': 'Profile',
      'thisWeek': 'This Week',
      'dailyHealthTip': 'Daily Health Tip',
      'hello': 'Hello!',
      'learnMore': 'Learn More',
      'jan': 'Jan',
      'healthTipBody':
          'Drink 8 glasses of water daily for better hydration and improved skin health.',
      'appointment1': '2:30 PM - Dr. Sarah Mitchell',
      'appointment2': '11:00 AM - Dr. James Chen',
      'upcomingAppointments': 'Upcoming Appointments',
      'add Appointment': 'Add Appointment',
      'noAppointments': 'No upcoming appointments',
      'viewAll': 'View All',
      'generalCheckup': 'General Checkup',
      'labTests': 'Lab Tests & Results',
      'lastUpdatedPrefix': 'Last updated today at',
    },
    'Hindi': {
      'dashboard': 'स्वस्थसेतु',
      'healthScore': 'स्वास्थ्य स्कोर',
      'greatCondition': 'बेहतरीन स्थिति',
      'excellentCondition': 'उत्कृष्ट स्थिति',
      'goodCondition': 'अच्छी स्थिति',
      'fairCondition': 'ठीक स्थिति',
      'poorCondition': 'कमज़ोर स्थिति',
      'criticalCondition': 'ध्यान देने की जरूरत',
      'steps': 'कदम',
      'sleep': 'नींद',
      'distance': 'दूरी',
      'bpm': 'BPM',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफ़ाइल',
      'thisWeek': 'इस सप्ताह',
      'dailyHealthTip': 'दैनिक स्वास्थ्य सुझाव',
      'hello': 'नमस्ते!',
      'learnMore': 'और जानें',
      'viewAll': 'सभी देखें',
      'jan': 'जन',
      'healthTipBody':
          'बेहतर हाइड्रेशन और त्वचा के स्वास्थ्य के लिए प्रतिदिन 8 ग्लास पानी पिएं।',
      'appointment1': '2:30 PM - डॉ. Sarah Mitchell',
      'appointment2': '11:00 AM - डॉ. James Chen',
      'upcomingAppointments': 'आने वाली नियुक्तियाँ',
      'add Appointment': 'अपॉइंटमेंट जोड़ें',
      'noAppointments': 'कोई आगामी अपॉइंटमेंट नहीं',
      'generalCheckup': 'सामान्य जांच',
      'labTests': 'प्रयोगशाला परीक्षण आणि परिणाम',
      'lastUpdatedPrefix': 'आज पर अंतिम अपडेट',
    },
    'Marathi': {
      'dashboard': 'स्वस्थसेतू',
      'healthScore': 'आरोग्य स्कोअर',
      'greatCondition': 'उत्तम स्थिती',
      'excellentCondition': 'उत्कृष्ट स्थिती',
      'goodCondition': 'चांगली स्थिती',
      'fairCondition': 'ठीक स्थिती',
      'poorCondition': 'कमकुवत स्थिती',
      'criticalCondition': 'लक्ष देणे आवश्यक',
      'steps': 'पावले',
      'sleep': 'झोप',
      'distance': 'अंतर',
      'bpm': 'BPM',
      'home': 'होम',
      'analytics': 'विश्लेषण',
      'aiSummary': 'AI सारांश',
      'history': 'इतिहास',
      'profile': 'प्रोफाइल',
      'thisWeek': 'या आठवड्यात',
      'dailyHealthTip': 'दैनिक आरोग्य सुझाव',
      'hello': 'नमस्कार!',
      'learnMore': 'अधिक जाणून घ्या',
      'viewAll': 'सर्व पहा',
      'jan': 'जान',
      'healthTipBody':
          'चांगल्या हायड्रेशन आणि त्वचेच्या आरोग्यासाठी दररोज 8 ग्लास पाणी प्या.',
      'appointment1': '2:30 PM - डॉ. Sarah Mitchell',
      'appointment2': '11:00 AM - डॉ. James Chen',
      'upcomingAppointments': 'आगामी नियुक्तिस्थिती',
      'add Appointment': 'भेट जोडा',
      'noAppointments': 'आगामी भेट नाही',
      'generalCheckup': 'सामान्य तपासणी',
      'labTests': 'प्रयोगशाळा चाचणी आणि परिणाम',
      'lastUpdatedPrefix': 'आज शेवटचे अद्ययावत',
    },
  };

  String _translate(String key) =>
      _translations[widget.currentLanguage]?[key] ?? key;

  /// Returns the appropriate health remark translation key based on score
  /// Score ranges: 90-100 = Excellent, 70-89 = Good, 50-69 = Fair, 30-49 = Poor, 0-29 = Critical
  String _getHealthRemark() {
    if (_healthScore >= 90) {
      return _translate('excellentCondition');
    } else if (_healthScore >= 70) {
      return _translate('goodCondition');
    } else if (_healthScore >= 50) {
      return _translate('fairCondition');
    } else if (_healthScore >= 30) {
      return _translate('poorCondition');
    } else {
      return _translate('criticalCondition');
    }
  }

  /// Returns the appropriate color for health remark based on score
  Color _getHealthRemarkColor() {
    if (_healthScore >= 90) {
      return const Color(0xFF45A191); // Teal - Excellent
    } else if (_healthScore >= 70) {
      return const Color(0xFF4CAF50); // Green - Good
    } else if (_healthScore >= 50) {
      return const Color(0xFFFFA726); // Orange - Fair
    } else if (_healthScore >= 30) {
      return const Color(0xFFFF7043); // Deep Orange - Poor
    } else {
      return const Color(0xFFE53935); // Red - Critical
    }
  }

  /// Returns the appropriate icon for health remark based on score
  IconData _getHealthRemarkIcon() {
    if (_healthScore >= 90) {
      return Icons.check_circle;
    } else if (_healthScore >= 70) {
      return Icons.thumb_up;
    } else if (_healthScore >= 50) {
      return Icons.info;
    } else if (_healthScore >= 30) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  String _localeCode() {
    switch (widget.currentLanguage) {
      case 'Hindi':
        return 'hi';
      case 'Marathi':
        return 'mr';
      default:
        return 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
            _lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF22262A)
            : const Color(0xFFF1F2F4),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // Home/Dashboard
            _buildHomeDashboard(isDark),
            // Analytics
            AnalyticsScreen(
              onThemeToggle: widget.onThemeToggle,
              onLanguageChange: widget.onLanguageChange,
              currentLanguage: widget.currentLanguage,
            ),
            // AI Summary
            AISummaryScreen(
              onThemeToggle: widget.onThemeToggle,
              onLanguageChange: widget.onLanguageChange,
              currentLanguage: widget.currentLanguage,
            ),
            // History
            HealthHistoryScreen(
              onThemeToggle: widget.onThemeToggle,
              onLanguageChange: widget.onLanguageChange,
              currentLanguage: widget.currentLanguage,
            ),
            // Profile
            ProfileScreen(
              onThemeToggle: widget.onThemeToggle,
              onLanguageChange: widget.onLanguageChange,
              currentLanguage: widget.currentLanguage,
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(isDark),
      ),
    );
  }

  // Helper to extract body content from screens that return Scaffold
  Widget _stripScaffold(Widget child, bool isDark) {
    // Since the other screens return full Scaffolds, we need to extract just their body
    // We'll wrap them in a container to prevent double scaffolds
    return Container(
      color: isDark ? const Color(0xFF22262A) : const Color(0xFFF1F2F4),
      child: child,
    );
  }

  Widget _buildHistoryPlaceholder(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: const Color(0xFF45A191).withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'History Screen',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Coming Soon',
                    style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 72), // Space for navbar
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(isDark),
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _fetchDataForDate(_selectedDate),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildHealthScoreCard(isDark),
                          const SizedBox(height: 24),
                          _buildWeeklyCalendar(isDark),
                          const SizedBox(height: 24),
                          _buildMetricsGrid(isDark),
                          const SizedBox(height: 24),
                          _buildHealthTipsBanner(isDark),
                          const SizedBox(height: 24),
                          _buildUpcomingAppointments(isDark),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _translate('dashboard'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              _buildGamificationButton(isDark),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.sync,
                isDark: isDark,
                onTap: () => _fetchDataForDate(_selectedDate),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: widget.onLanguageChange,
                itemBuilder: (context) => [
                  'English',
                  'Hindi',
                  'Marathi',
                ].map((l) => PopupMenuItem(value: l, child: Text(l))).toList(),
                child: _buildHeaderButton(
                  icon: Icons.language,
                  isDark: isDark,
                  onTap: null,
                ),
              ),
              const SizedBox(width: 12),
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
          color: isDark ? const Color(0xFF2C3035) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildGamificationButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GamificationScreen(
              onThemeToggle: widget.onThemeToggle,
              onLanguageChange: widget.onLanguageChange,
              currentLanguage: widget.currentLanguage,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF45A191), Color(0xFF2D7A6D)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF45A191).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            const Text(
              'XP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_translate('hello')} 👋',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 4),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF45A191).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFF45A191).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF45A191),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF45A191).withOpacity(0.15),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: ProgressRingPainter(
                      progress: _healthScore / 100,
                      primaryColor: const Color(0xFF45A191),
                      backgroundColor: isDark
                          ? const Color(0xFF3A3F45)
                          : const Color(0xFFC8E6E1),
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF2C3035) : Colors.white,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_healthScore',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '/ 100',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF45A191).withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF45A191).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate('healthScore'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getHealthRemarkColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getHealthRemarkIcon(),
                        color: _getHealthRemarkColor(),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getHealthRemark(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getHealthRemarkColor(),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_translate('lastUpdatedPrefix')} ${DateFormat.jm(_localeCode()).format(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar(bool isDark) {
    final today = DateTime.now();
    final firstDay = today.subtract(Duration(days: today.weekday - 1));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              Text(
                _translate('thisWeek'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              // Show selected date
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF45A191).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MMM d', _localeCode()).format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF45A191),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = firstDay.add(Duration(days: i));
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isFuture = date.isAfter(today);

              return GestureDetector(
                onTap: isFuture ? null : () => _onDateSelected(date),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF45A191)
                            : (isDark
                                  ? const Color(0xFF3A3F45)
                                  : const Color(0xFFE8EEF0)),
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: const Color(0xFF45A191),
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : isFuture
                                ? (isDark ? Colors.white38 : Colors.black26)
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.E(
                        widget.currentLanguage == 'English'
                            ? 'en'
                            : (widget.currentLanguage == 'Hindi' ? 'hi' : 'mr'),
                      ).format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isFuture
                            ? const Color(0xFF94A3B8).withOpacity(0.5)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDark) {
    final sleepHours = _sleepDuration.toInt();
    final sleepMinutes = ((_sleepDuration - sleepHours) * 60).toInt();
    final stepsPercent = ((_steps / _stepsGoal) * 100).clamp(0, 100).toInt();
    final sleepPercent = ((_sleepDuration / _sleepGoal) * 100)
        .clamp(0, 100)
        .toInt();
    final distancePercent = ((_distance / _distanceGoal) * 100)
        .clamp(0, 100)
        .toInt();

    // Format goals for display
    String stepsGoalLabel = _stepsGoal >= 1000
        ? '${(_stepsGoal / 1000).toStringAsFixed(_stepsGoal % 1000 == 0 ? 0 : 1)}k'
        : _stepsGoal.toString();
    String sleepGoalLabel =
        '${_sleepGoal.toStringAsFixed(_sleepGoal % 1 == 0 ? 0 : 1)}h';
    String distanceGoalLabel = _distanceGoal >= 1000
        ? '${(_distanceGoal / 1000).toStringAsFixed(_distanceGoal % 1000 == 0 ? 0 : 1)}km'
        : '${_distanceGoal}m';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.95,
      children: [
        _buildMetricCard(
          Icons.directions_walk,
          const Color(0xFFEA580C),
          isDark
              ? const Color(0xFFEA580C).withOpacity(0.2)
              : const Color(0xFFFED7AA),
          NumberFormat('#,###').format(_steps),
          null,
          _translate('steps'),
          isDark,
          ChartType.waveform,
          dataValue: _steps / _stepsGoal,
          chartLabel: '$stepsPercent% of $stepsGoalLabel',
          onEditGoal: () => _showGoalEditDialog('steps', isDark),
        ),
        _buildMetricCard(
          Icons.bedtime,
          const Color(0xFF4F46E5),
          isDark
              ? const Color(0xFF4F46E5).withOpacity(0.2)
              : const Color(0xFFDDD6FE),
          '${sleepHours}h ${sleepMinutes}m',
          null,
          _translate('sleep'),
          isDark,
          ChartType.area,
          isTimeValue: true,
          hours: sleepHours,
          minutes: sleepMinutes,
          dataValue: _sleepDuration / _sleepGoal,
          chartLabel: '$sleepPercent% of $sleepGoalLabel',
          onEditGoal: () => _showGoalEditDialog('sleep', isDark),
        ),
        _buildMetricCard(
          Icons.route,
          const Color(0xFF059669),
          isDark
              ? const Color(0xFF059669).withOpacity(0.2)
              : const Color(0xFFA7F3D0),
          NumberFormat('#,###').format(_distance),
          'm',
          _translate('distance'),
          isDark,
          ChartType.bars,
          dataValue: _distance / _distanceGoal,
          chartLabel: '$distancePercent% of $distanceGoalLabel',
          onEditGoal: () => _showGoalEditDialog('distance', isDark),
        ),
        _buildMetricCard(
          Icons.favorite,
          const Color(0xFFE11D48),
          isDark
              ? const Color(0xFFE11D48).withOpacity(0.2)
              : const Color(0xFFFECDD3),
          '$_heartRate',
          null,
          _translate('bpm'),
          isDark,
          ChartType.heartbeat,
          dataValue: _heartRate / 100,
          chartLabel: _heartRate > 0
              ? _heartRate < 60 ? "Low" : (_heartRate > 100 ? "High" : "Normal")
              : '--',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    IconData icon,
    Color iconColor,
    Color iconBgColor,
    String value,
    String? unit,
    String label,
    bool isDark,
    ChartType chartType, {
    bool isTimeValue = false,
    int? hours,
    int? minutes,
    double dataValue = 0.5,
    String? chartLabel,
    VoidCallback? onEditGoal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3035) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Row(
                children: [
                  if (chartLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chartLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                  if (onEditGoal != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onEditGoal,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.edit, color: iconColor, size: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 35,
            width: double.infinity,
            child: CustomPaint(
              painter: EnhancedChartPainter(
                color: iconColor,
                isDark: isDark,
                chartType: chartType,
                dataValue: dataValue.clamp(0.0, 1.0),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (isTimeValue && hours != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$hours',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const Text(
                  'h',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '${minutes ?? 0}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const Text(
                  'm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -1,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipsBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF45A191), Color(0xFF2D8C7F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF45A191).withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 ${_translate('dailyHealthTip')}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _healthTips[_currentHealthTipIndex]['tip']!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAllHealthTips(isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _translate('learnMore'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _translate('upcomingAppointments'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showAddAppointmentDialog(isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF45A191).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          size: 14,
                          color: Color(0xFF45A191),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _translate('add Appointment'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF45A191),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_appointments.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 40,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _translate('noAppointments'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._appointments.asMap().entries.map((entry) {
            final index = entry.key;
            final apt = entry.value;
            final aptDate = DateTime.parse(apt['date']);
            final dateStr = aptDate.day.toString();
            final monthStr = DateFormat('MMM').format(aptDate);
            final color = Color(apt['color'] as int);
            final isElapsed = _isAppointmentElapsed(apt);

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _appointments.length - 1 ? 12 : 0,
              ),
              child: _buildApptCard(
                date: dateStr,
                month: monthStr,
                title: apt['title'],
                subtitle: apt['subtitle'],
                color: color,
                isDark: isDark,
                isElapsed: isElapsed,
                onDelete: () => _showDeleteConfirmation(index, isDark),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildApptCard({
    required String date,
    required String month,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    bool isElapsed = false,
    VoidCallback? onDelete,
  }) {
    final displayColor = isElapsed ? Colors.grey : color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: displayColor.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: displayColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isElapsed
                        ? (isDark ? Colors.grey[400] : Colors.grey[600])
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: isElapsed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (isElapsed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'Elapsed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          if (isElapsed) const SizedBox(width: 8),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.delete_outline,
                color: Colors.red.withOpacity(0.7),
                size: 20,
              ),
            )
          else
            Icon(
              Icons.more_vert,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C3035).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.5)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, _translate('home'), 0, isDark),
              _buildNavItem(
                Icons.analytics_outlined,
                _translate('analytics'),
                1,
                isDark,
              ),
              _buildNavItem(
                Icons.auto_awesome_outlined,
                _translate('aiSummary'),
                2,
                isDark,
              ),
              _buildNavItem(Icons.history, _translate('history'), 3, isDark),
              _buildNavItem(
                Icons.person_outline,
                _translate('profile'),
                4,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF45A191).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? const Color(0xFF45A191)
                    : isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// --- SHARED UI PAINTERS ---
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  ProgressRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(
      center,
      radius - 4,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum ChartType { waveform, area, bars, heartbeat }

class EnhancedChartPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final ChartType chartType;
  final double dataValue; // 0.0 to 1.0 normalized value

  EnhancedChartPainter({
    required this.color,
    required this.isDark,
    required this.chartType,
    this.dataValue = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (chartType) {
      case ChartType.waveform:
        _drawWaveform(canvas, size);
        break;
      case ChartType.area:
        _drawAreaChart(canvas, size);
        break;
      case ChartType.bars:
        _drawBarsChart(canvas, size);
        break;
      case ChartType.heartbeat:
        _drawHeartbeat(canvas, size);
        break;
    }
  }

  void _drawWaveform(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final barCount = 30;
    final barWidth = 2.0;
    final spacing = (width - (barWidth * barCount)) / (barCount + 1);

    // Generate heights based on actual data value with some variation
    // dataValue determines overall fill level, with natural variation
    final baseHeight = dataValue.clamp(0.1, 1.0);
    final filledBars = (barCount * dataValue).round().clamp(0, barCount);

    for (int i = 0; i < barCount; i++) {
      final x = spacing + (i * (barWidth + spacing));

      // Create a wave pattern that fills up based on data
      double heightFactor;
      if (i < filledBars) {
        // Filled bars have varying heights based on position
        heightFactor = baseHeight * (0.5 + 0.5 * math.sin(i * 0.5).abs());
      } else {
        // Unfilled bars are shorter (background indication)
        heightFactor = 0.15;
      }

      final barHeight = heightFactor * height;
      final y = (height - barHeight) / 2;

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: i < filledBars
            ? [color.withOpacity(0.7), color]
            : [color.withOpacity(0.2), color.withOpacity(0.1)],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x, y, barWidth, barHeight),
        )
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.round;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  void _drawAreaChart(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final points = <Offset>[];
    final dataPoints = 40;

    // Use dataValue to determine the overall height of the chart
    // Higher sleep = higher wave pattern
    final amplitude = 0.3 * dataValue.clamp(0.1, 1.0);
    final baseY = 1.0 - (dataValue * 0.6); // Lower base = more filled

    for (int i = 0; i < dataPoints; i++) {
      final x = (width / (dataPoints - 1)) * i;
      final normalizedX = i / dataPoints;
      // Create a smooth sleep pattern wave based on actual sleep data
      final y =
          height *
          (baseY +
              amplitude * math.sin(normalizedX * 3 * math.pi + 1.5) +
              (amplitude * 0.5) * math.sin(normalizedX * 6 * math.pi));
      points.add(Offset(x, y.clamp(0, height)));
    }

    final path = Path();
    path.moveTo(0, height);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(width, height);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.5 * dataValue + 0.1),
        color.withOpacity(0.05),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  void _drawBarsChart(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final barCount = 7;
    final barWidth = width / (barCount * 2);
    final spacing = barWidth;

    // Generate bar heights based on dataValue
    // Shows progress toward goal with the last bar being the current value
    final targetHeight = dataValue.clamp(0.1, 1.0);

    for (int i = 0; i < barCount; i++) {
      final x = spacing + (i * (barWidth + spacing));

      // Create a progression pattern - bars build up to current value
      double barHeightFactor;
      if (i < barCount - 1) {
        // Previous days/segments - slight variation around average
        barHeightFactor = targetHeight * (0.5 + 0.4 * ((i + 1) / barCount));
      } else {
        // Current/latest value - shows the actual data
        barHeightFactor = targetHeight;
      }

      final barHeight = barHeightFactor * height;
      final y = height - barHeight;

      final bgPaint = Paint()
        ..color = color.withOpacity(isDark ? 0.15 : 0.2)
        ..style = PaintingStyle.fill;

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(bgRect, bgPaint);

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.7), color],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x, y, barWidth, barHeight),
        )
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);

      // Highlight on current bar
      if (i == barCount - 1) {
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        final highlightRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight * 0.25),
          Radius.circular(barWidth / 2),
        );
        canvas.drawRRect(highlightRect, highlightPaint);
      }
    }
  }

  void _drawHeartbeat(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    final path = Path();
    final dataPoints = 80;

    // Use dataValue to affect the amplitude of the heartbeat
    // Higher heart rate = more pronounced peaks
    final amplitude = 0.2 + (dataValue.clamp(0.3, 1.0) * 0.3);
    // Heart rate affects the spacing/frequency of beats
    final beatWidth = dataValue > 0.8 ? 0.18 : (dataValue > 0.5 ? 0.2 : 0.22);

    for (int i = 0; i < dataPoints; i++) {
      final x = (width / (dataPoints - 1)) * i;
      final normalizedX = i / dataPoints;

      double y;
      // First heartbeat
      final beat1Start = 0.1;
      final beat1End = beat1Start + beatWidth;
      // Second heartbeat
      final beat2Start = 0.55;
      final beat2End = beat2Start + beatWidth;

      if (normalizedX >= beat1Start && normalizedX < beat1Start + 0.05) {
        y = centerY - height * 0.1 * amplitude;
      } else if (normalizedX >= beat1Start + 0.05 &&
          normalizedX < beat1Start + 0.1) {
        y = centerY + height * amplitude;
      } else if (normalizedX >= beat1Start + 0.1 &&
          normalizedX < beat1Start + 0.15) {
        y = centerY - height * (amplitude * 0.9);
      } else if (normalizedX >= beat1Start + 0.15 && normalizedX < beat1End) {
        y = centerY + height * 0.15 * amplitude;
      } else if (normalizedX >= beat2Start && normalizedX < beat2Start + 0.05) {
        y = centerY - height * 0.1 * amplitude;
      } else if (normalizedX >= beat2Start + 0.05 &&
          normalizedX < beat2Start + 0.1) {
        y = centerY + height * amplitude;
      } else if (normalizedX >= beat2Start + 0.1 &&
          normalizedX < beat2Start + 0.15) {
        y = centerY - height * (amplitude * 0.9);
      } else if (normalizedX >= beat2Start + 0.15 && normalizedX < beat2End) {
        y = centerY + height * 0.15 * amplitude;
      } else {
        // Flat line between beats with slight variation
        y = centerY + height * 0.02 * math.sin(normalizedX * 30);
      }

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant EnhancedChartPainter oldDelegate) {
    return oldDelegate.dataValue != dataValue ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
