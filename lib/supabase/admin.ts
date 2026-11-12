import 'server-only'

import { createClient as createSupabaseClient } from '@supabase/supabase-js'

/**
 * Service-role Supabase client. SERVER ONLY.
 * Bypasses RLS — never import this from a "use client" module.
 * Intended for trusted server tasks: notification logging, cron jobs,
 * and reading the public_calendar view.
 */
export function createAdminClient() {
  if (typeof window !== 'undefined') {
    throw new Error('createAdminClient may only be used on the server')
  }

  return createSupabaseClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SECRET_KEY!,
    { auth: { persistSession: false } }
  )
}