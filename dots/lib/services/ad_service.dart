import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob service for managing banner and interstitial ads
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Ad Unit IDs
  static const String _bannerAdUnitId = 'ca-app-pub-3990640624622013/4492374380';
  static const String _interstitialAdUnitId = 'ca-app-pub-3990640624622013/8048476017';

  // Test Ad Unit IDs (use for testing)
  // static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  // static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int _puzzlesCompleted = 0;

  // Show interstitial ad every 5-6 games
  static const int _interstitialFrequency = 5;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    // Preload the first interstitial ad
    _loadInterstitialAd();
  }

  void onPuzzleCompleted() {
    _puzzlesCompleted++;
    
    // Show interstitial ad every 5-6 puzzles
    if (_puzzlesCompleted % _interstitialFrequency == 0) {
      _showInterstitialAd();
    }
  }

  // Banner Ad Methods
  BannerAd? createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    
    _bannerAd?.load();
    return _bannerAd;
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  BannerAd? get bannerAd => _bannerAd;

  // Interstitial Ad Methods
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              // Preload next interstitial ad
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              // Preload next interstitial ad
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd?.show();
    } else {
      print('Interstitial ad not ready yet');
      // Try to load it for next time
      _loadInterstitialAd();
    }
  }

  void dispose() {
    disposeBannerAd();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
}
