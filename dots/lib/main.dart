import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/ad_service.dart';
import 'services/puzzle_stats_service.dart';
import 'providers/service_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize ad service
  AdService().initialize();
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // BUG FIX #16: Reset the per-session puzzle counter on every cold start.
  // The session count is stored in SharedPreferences (persists across restarts)
  // but is intended to track only the CURRENT session. Without this call, it
  // grows identically to the total count and the distinction is meaningless.
  await PuzzleStatsService(sharedPreferences).resetSessionCount();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const DotsApp(),
    ),
  );
}

class DotsApp extends StatelessWidget {
  const DotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Connect Dots',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
