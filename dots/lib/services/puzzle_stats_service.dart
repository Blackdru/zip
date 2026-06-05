import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking puzzle statistics persistently
class PuzzleStatsService {
  static const String _completedPuzzlesKey = 'total_completed_puzzles';
  static const String _sessionCompletedPuzzlesKey = 'session_completed_puzzles';
  
  final SharedPreferences _prefs;
  
  PuzzleStatsService(this._prefs);
  
  /// Get total number of completed puzzles (persists across app sessions)
  int getTotalCompletedPuzzles() {
    return _prefs.getInt(_completedPuzzlesKey) ?? 0;
  }
  
  /// Get session completed puzzles (resets when app restarts)
  int getSessionCompletedPuzzles() {
    return _prefs.getInt(_sessionCompletedPuzzlesKey) ?? 0;
  }
  
  /// Increment completed puzzles count
  Future<void> incrementCompletedPuzzles() async {
    final current = getTotalCompletedPuzzles();
    await _prefs.setInt(_completedPuzzlesKey, current + 1);
    
    final sessionCount = getSessionCompletedPuzzles();
    await _prefs.setInt(_sessionCompletedPuzzlesKey, sessionCount + 1);
  }
  
  /// Reset session count (called when app starts)
  Future<void> resetSessionCount() async {
    await _prefs.setInt(_sessionCompletedPuzzlesKey, 0);
  }
  
  /// Reset total count (for testing or user preference)
  Future<void> resetTotalCount() async {
    await _prefs.setInt(_completedPuzzlesKey, 0);
  }
  
  /// Clear all puzzle stats
  Future<void> clearAll() async {
    await _prefs.remove(_completedPuzzlesKey);
    await _prefs.remove(_sessionCompletedPuzzlesKey);
  }
}
