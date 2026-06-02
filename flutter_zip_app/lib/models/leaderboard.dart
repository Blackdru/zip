import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard.freezed.dart';
part 'leaderboard.g.dart';

/// Represents a leaderboard entry
@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String id,
    required String tournamentId,
    required String userId,
    required String username,
    String? avatarUrl,
    String? countryCode,
    required int totalTimeMs,
    required int puzzlesSolved,
    String? completedAt,
    required int rank,
    @Default(false) bool isDisqualified,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}

/// Represents leaderboard response
@freezed
class LeaderboardResponse with _$LeaderboardResponse {
  const factory LeaderboardResponse({
    required List<LeaderboardEntry> entries,
    LeaderboardEntry? myEntry,
    required int total,
  }) = _LeaderboardResponse;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardResponseFromJson(json);
}
