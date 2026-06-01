import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static bool _isInitialized = false;
  static InterstitialAd? _interstitialAd;
  static int _addedSubsCount = 0; // Show interstitial every 3 additions

  static Future<void> init() async {
    if (kIsWeb) return;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await MobileAds.instance.initialize();
        _isInitialized = true;
        _loadInterstitial();
      } catch (_) {}
    }
  }

  static bool get isInitialized => _isInitialized;

  // Real banner ad IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6003638370658344/7357271527';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6003638370658344/7357271527'; // iOS için ayrı ID gerekirse güncelle
    }
    return '';
  }

  // Real interstitial ad IDs
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6003638370658344/6564951109';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6003638370658344/6564951109'; // iOS için ayrı ID gerekirse güncelle
    }
    return '';
  }

  static void _loadInterstitial() {
    if (!_isInitialized) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Call after a subscription is added. Shows an ad every 3rd addition.
  static void onSubscriptionAdded() {
    _addedSubsCount++;
    if (_addedSubsCount % 3 == 0) {
      showInterstitial();
    }
  }

  static void showInterstitial() {
    if (_interstitialAd == null) {
      _loadInterstitial();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial(); // preload next
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
