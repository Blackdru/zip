import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for managing AdMob ads throughout the app
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // AdMob Ad Unit IDs
  static const String _bannerAdUnitId = 'ca-app-pub-3990640624622013/5713426486';
  static const String _interstitialAdUnitId = 'ca-app-pub-3990640624622013/7493412014';

  // Counter for interstitial ads (show after every 3-4 games)
  int _gamesCompleted = 0;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  /// Initialize the Mobile Ads SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    // Pre-load first interstitial ad
    await loadInterstitialAd();
  }

  /// Get Banner Ad Unit ID for the platform
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _bannerAdUnitId;
    } else if (Platform.isIOS) {
      return _bannerAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Get Interstitial Ad Unit ID for the platform
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _interstitialAdUnitId;
    } else if (Platform.isIOS) {
      return _interstitialAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Load an interstitial ad
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          // Set up full screen content callback
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              // Pre-load next interstitial ad
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              // Try to load another one
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 5), () {
            loadInterstitialAd();
          });
        },
      ),
    );
  }

  /// Show interstitial ad after every 3-4 games completed
  void onPuzzleCompleted() {
    _gamesCompleted++;
    
    // Show ad after 3 or 4 games (randomized between 3-4)
    final showAfter = 3 + (_gamesCompleted % 2); // Alternates between 3 and 4
    
    if (_gamesCompleted >= showAfter) {
      showInterstitialAd();
      _gamesCompleted = 0; // Reset counter
    }
  }

  /// Show the interstitial ad if ready
  void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      // If not ready, try loading it
      loadInterstitialAd();
    }
  }

  /// Dispose of any loaded ads
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
}
