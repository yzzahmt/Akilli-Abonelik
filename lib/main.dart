import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'providers/settings_provider.dart';
import 'package:home_widget/home_widget.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hata yakalayıcı (Crashes will show a red screen instead of closing)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("Uncaught error: $error\n$stack");
    return true;
  };
  
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Uygulama Çöktü!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(details.exceptionAsString(), style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 10),
              Text(details.stack?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  };

  try {
    await PurchaseService.instance.init();
    await NotificationService.init();
    await AdService.init();

    // setAppGroupId is only needed for iOS and can throw MissingPluginException on other platforms
    try {
      HomeWidget.setAppGroupId('group.com.yzzahmt.abonetakip');
    } catch (e) {
      debugPrint('HomeWidget setup warning: $e');
    }
    Intl.defaultLocale = 'tr_TR';
    await initializeDateFormatting('tr_TR', null);
    await initializeDateFormatting('tr', null);
  } catch (e, st) {
    debugPrint("Init error: $e\n$st");
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Init error: $e")))));
    return;
  }

  runApp(const ProviderScope(child: SubsTrackApp()));
}

class SubsTrackApp extends ConsumerWidget {
  const SubsTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SubsTrack — Abonelik Takibi',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      navigatorObservers: [routeObserver, _AdRouteObserver(ref)],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      home: const SplashScreen(),
    );
  }
}

class _AdRouteObserver extends NavigatorObserver {
  final WidgetRef ref;
  _AdRouteObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      AdService.onScreenChanged(ref.read(isPremiumProvider));
    }
  }
}
