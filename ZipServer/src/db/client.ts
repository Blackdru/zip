import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '../config';
import { logger } from '../utils/logger';

let supabaseInstance: SupabaseClient | null = null;

/**
 * Returns a singleton Supabase client using the service role key.
 * The service role key bypasses RLS — only use server-side.
 */
export function getSupabaseClient(): SupabaseClient {
  if (!supabaseInstance) {
    supabaseInstance = createClient(
      config.supabase.url,
      config.supabase.serviceRoleKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );
    logger.info('Supabase client initialized');
  }
  return supabaseInstance;
}

export const db = {
  get client(): SupabaseClient {
    return getSupabaseClient();
  },

  /** Run a raw query with full Postgres access */
  async query<T = unknown>(sql: string, params?: unknown[]): Promise<T[]> {
    const { data, error } = await getSupabaseClient().rpc('exec_sql', {
      query: sql,
      params: params ?? [],
    });
    if (error) throw new Error(`DB query error: ${error.message}`);
    return data as T[];
  },
};
