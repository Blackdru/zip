import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament.dart';
import '../services/tournament_service.dart';
import 'service_providers.dart';

class TournamentState {
  final Tournament? tournament;
  final List<Tournament> allTournaments;
  final bool isLoading;
  final String? error;

  const TournamentState({
    this.tournament,
    this.allTournaments = const [],
    this.isLoading = false,
    this.error,
  });

  TournamentState copyWith({
    Tournament? tournament,
    List<Tournament>? allTournaments,
    bool? isLoading,
    String? error,
  }) {
    return TournamentState(
      tournament: tournament ?? this.tournament,
      allTournaments: allTournaments ?? this.allTournaments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TournamentNotifier extends StateNotifier<TournamentState> {
  final TournamentService _tournamentService;

  TournamentNotifier(this._tournamentService) : super(const TournamentState());

  Future<void> loadCurrentTournament() async {
    state = state.copyWith(isLoading: true);

    try {
      final tournament = await _tournamentService.getCurrent();
      state = TournamentState(
        tournament: tournament,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadAllTournaments() async {
    state = state.copyWith(isLoading: true);

    try {
      final tournaments = await _tournamentService.list();
      state = state.copyWith(
        allTournaments: tournaments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final tournamentProvider = StateNotifierProvider<TournamentNotifier, TournamentState>((ref) {
  final tournamentService = ref.watch(tournamentServiceProvider);
  return TournamentNotifier(tournamentService);
});
