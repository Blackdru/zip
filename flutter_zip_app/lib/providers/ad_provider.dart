import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ad_service.dart';

/// Provider for the AdService singleton
final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

/// Provider to track games completed for interstitial ads
final gamesCompletedProvider = StateProvider<int>((ref) => 0);
