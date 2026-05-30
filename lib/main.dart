import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'providers/settings_provider.dart';
import 'package:home_widget/home_widget.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  HomeWidget.setAppGroupId('group.com.yzzahmt.abonetakip');
  Intl.defaultLocale = 'tr_TR';

  // Google Play / RevenueCat Ayarları
  // API Key'inizi buraya girin ve yorum satırlarını kaldırın:
  // await Purchases.setLogLevel(LogLevel.debug);
  // PurchasesConfiguration configuration = PurchasesConfiguration("goog_BURAYA_REVENUECAT_API_KEY_GELECEK");
  // await Purchases.configure(configuration);

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
