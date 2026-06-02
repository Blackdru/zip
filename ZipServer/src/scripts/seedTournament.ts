import { TournamentService } from '../api/tournaments/tournaments.service';

async function seedTournament() {
  const now = new Date();
  const weekEnd = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

  const tournament = await TournamentService.createTournament(
    21,
    2026,
    now,
    weekEnd,
    'Weekly Tournament Prize'
  );

  console.log('Tournament created:', tournament.id);

  await TournamentService.setStatus(tournament.id, 'active');
  console.log('Tournament activated!');
  process.exit(0);
}

seedTournament().catch(console.error);
