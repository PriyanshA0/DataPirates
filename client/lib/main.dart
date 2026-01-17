import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize for high refresh rate displays (120Hz)
  // This prevents black screen issues on 120fps devices
  SchedulerBinding.instance.schedulerPhase;

  // Allow Google Fonts to use system fonts when offline
  GoogleFonts.config.allowRuntimeFetching = false;

  // Required for the Dashboard's date formatting
  await initializeDateFormatting();

  // Initialize notifications
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  // Schedule daily evening health check reminder (8 PM)
  await NotificationService.scheduleEveningHealthCheck();

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
      title: 'SwasthSetu',
      debugShowCheckedModeBanner: false,
      // Performance optimizations for 120Hz displays
      checkerboardOffscreenLayers: false,
      checkerboardRasterCacheImages: false,
      themeMode: _themeMode,
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
      // Always start at splash - it will check login status and navigate accordingly
      initialRoute: '/',
      routes: {
        '/': (context) => const HealthTrackerSplashScreen(),
        '/register': (context) => RegistrationScreen(
          onThemeToggle: _toggleTheme,
          onLanguageChange: _changeLanguage,
          currentLanguage: _language,
        ),
        '/login': (context) => LoginScreen(
          onThemeToggle: _toggleTheme,
          onLanguageChange: _changeLanguage,
          currentLanguage: _language,
        ),
        '/dashboard': (context) => DashboardScreen(
          onThemeToggle: _toggleTheme,
          onLanguageChange: _changeLanguage,
          currentLanguage: _language,
          initialTab: 0,
        ),
        '/analytics': (context) => DashboardScreen(
          onThemeToggle: _toggleTheme,
          onLanguageChange: _changeLanguage,
          currentLanguage: _language,
          initialTab: 1,
        ),
        '/ai-summary': (context) => DashboardScreen(
          onThemeToggle: _toggleTheme,
          onLanguageChange: _changeLanguage,
          currentLanguage: _language,
          initialTab: 2,
        ),
        '/history': (context) => DashboardScreen(
          onThemeToggle: _toggleTheme,
          onLanguageChange: _changeLanguage,
          currentLanguage: _language,
          initialTab: 3,
        ),
        '/profile': (context) => DashboardScreen(
          onThemeToggle: _toggleTheme,
          onLanguageChange: _changeLanguage,
          currentLanguage: _language,
          initialTab: 4,
        ),
      },
    );
  }
}
