import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Represents a user
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String username,
    required String email,
    String? avatarUrl,
    String? countryCode,
    @Default(false) bool isAdmin,
    required String createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// Represents user statistics
@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    required String userId,
    @Default(0) int totalPuzzlesSolved,
    @Default(0) int practiceCount,
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    int? averageSolveMs,
    int? fastestSolveMs,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
}
