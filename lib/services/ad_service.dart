import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _isInitialized = false;

  // REAL AD UNIT IDs from user
  static const String appId = 'ca-app-pub-6003638370658344';
  static const String bannerAdUnitId = 'ca-app-pub-6003638370658344/7357271527';
  static const String interstitialAdUnitId = 'ca-app-pub-6003638370658344/6564951109';
  static const String rewardedAdUnitId = 'ca-app-pub-6003638370658344/9317220459';

  static InterstitialAd? _interstitialAd;
  static int _addedSubsCount = 0; // Show interstitial every 3 additions

  RewardedAd? _rewardedAd;
  int _rewardedWatchCount = 0; // track how many rewarded ads watched
  static const int adsRequiredForPro = 3;

  // Singleton pattern for stateful rewarded ads
  static final AdService instance = AdService._internal();
  AdService._internal();

  static Future<void> init() async {
    if (kIsWeb) return;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await MobileAds.instance.initialize();
        _isInitialized = true;
        _loadInterstitial();
        instance.loadRewardedAd();
      } catch (_) {}
    }
  }

  static bool get isInitialized => _isInitialized;

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
        _loadInterstitial();
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

  // Load rewarded ad
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  // Show rewarded ad
  Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    required VoidCallback onFailed,
  }) async {
    if (_rewardedAd == null) {
      onFailed();
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onFailed();
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      _rewardedWatchCount++;
      onRewarded();
    });
    _rewardedAd = null;
  }

  int get rewardedWatchCount => _rewardedWatchCount;
  bool get hasEnoughForPro => _rewardedWatchCount >= adsRequiredForPro;
}
