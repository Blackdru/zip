import 'dotenv/config';
import { db } from '../db/client';

(async () => {
  const { data: t } = await db.client
    .from('tournaments')
    .select('id')
    .eq('status', 'active')
    .limit(1)
    .single();

  console.log('Tournament ID:', t?.id);

  const { data, error } = await db.client
    .from('puzzles')
    .select('id, seed, grid_size, difficulty, clue_numbers, obstacles, order_index')
    .eq('tournament_id', t!.id)
    .eq('is_practice', false)
    .limit(1)
    .single();

  if (error) {
    console.error('DB ERROR:', JSON.stringify(error, null, 2));
    process.exit(1);
  }

  console.log('Raw puzzle row:');
  console.log('  id:', data?.id);
  console.log('  grid_size:', data?.grid_size);
  console.log('  difficulty:', data?.difficulty);
  console.log('  clue_numbers type:', typeof data?.clue_numbers);
  console.log('  clue_numbers isArray:', Array.isArray(data?.clue_numbers));
  console.log('  clue_numbers value:', JSON.stringify(data?.clue_numbers)?.slice(0, 100));
  console.log('  obstacles type:', typeof data?.obstacles);
  console.log('  obstacles value:', JSON.stringify(data?.obstacles)?.slice(0, 60));
  process.exit(0);
})().catch(e => { console.error('Unhandled:', e.message); process.exit(1); });
