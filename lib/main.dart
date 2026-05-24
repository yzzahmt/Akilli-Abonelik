import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'screens/home_screen.dart';
import 'screens/privacy_agreement_screen.dart';
import 'screens/splash_screen.dart';
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
  bool _showSplash = true;
  bool _isKvkkAccepted = false;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return PremiumSplashScreen(
        onInitializationComplete: (isKvkkAccepted) {
          setState(() {
            _isKvkkAccepted = isKvkkAccepted;
            _showSplash = false;
          });
        },
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
