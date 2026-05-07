import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'screens/home_screen.dart';
import 'screens/privacy_agreement_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'tr_TR';

  runApp(
    const ProviderScope(
      child: SubsTrackApp(),
    ),
  );
}

class SubsTrackApp extends StatelessWidget {
  const SubsTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SubsTrack — Abonelik Takibi',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      home: const AppInitializationScreen(),
    );
  }
}

class AppInitializationScreen extends StatefulWidget {
  const AppInitializationScreen({super.key});

  @override
  State<AppInitializationScreen> createState() => _AppInitializationScreenState();
}

class _AppInitializationScreenState extends State<AppInitializationScreen> {
  bool _isLoading = true;
  bool _isKvkkAccepted = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await DBService.instance.database;
      await NotificationService.instance.init();
      await AdService.init();

      final prefs = await SharedPreferences.getInstance();
      _isKvkkAccepted = prefs.getBool('is_kvkk_accepted') ?? false;
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF59E0B),
          ),
        ),
      );
    }

    if (!_isKvkkAccepted) {
      return PrivacyAgreementScreen(
        onAccepted: () {
          setState(() {
            _isKvkkAccepted = true;
          });
        },
      );
    }

    return const HomeScreen();
  }
}
