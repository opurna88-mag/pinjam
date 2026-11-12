import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

/**
 * Server-side Supabase client for Server Components and Route Handlers.
 * `cookies()` is async in Next 15, and @supabase/ssr requires the
 * getAll/setAll cookie adapter (get/set/remove are deprecated).
 */
export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Called from a Server Component where cookies are read-only.
            // Safe to ignore: session refresh is handled by middleware.
          }
        },
      },
    }
  )
}