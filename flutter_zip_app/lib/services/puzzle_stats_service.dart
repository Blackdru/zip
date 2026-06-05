import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking puzzle statistics persistently
class PuzzleStatsService {
  static const String _totalCompletedKey = 'total_completed_puzzles';
  
  final SharedPreferences _prefs;
  
  PuzzleStatsService(this._prefs);
  
  /// Get total number of completed puzzles (persists across app sessions)
  int getTotalCompletedPuzzles() {
    return _prefs.getInt(_totalCompletedKey) ?? 0;
  }
  
  /// Increment completed puzzles count
  Future<void> incrementCompletedPuzzles() async {
    final current = getTotalCompletedPuzzles();
    await _prefs.setInt(_totalCompletedKey, current + 1);
  }
  
  /// Reset total count (for testing or user preference)
  Future<void> resetTotalCount() async {
    await _prefs.setInt(_totalCompletedKey, 0);
  }
  
  /// Clear all puzzle stats
  Future<void> clearAll() async {
    await _prefs.remove(_totalCompletedKey);
  }
}
