import 'package:freezed_annotation/freezed_annotation.dart';
import 'puzzle.dart';

part 'tournament.freezed.dart';
part 'tournament.g.dart';

enum TournamentStatus {
  @JsonValue('upcoming')
  upcoming,
  @JsonValue('active')
  active,
  @JsonValue('frozen')
  frozen,
  @JsonValue('archived')
  archived,
}

/// Represents a tournament
@freezed
class Tournament with _$Tournament {
  const factory Tournament({
    required String id,
    required int weekNumber,
    required int year,
    String? title,
    required TournamentStatus status,
    required String startsAt,
    required String endsAt,
    required String freezeAt,
    String? rewardDescription,
    @Default([]) List<PuzzleData> puzzles,
  }) = _Tournament;

  factory Tournament.fromJson(Map<String, dynamic> json) =>
      _$TournamentFromJson(json);
}
