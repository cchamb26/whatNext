import "dotenv/config";
import { createClient, SupabaseClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_PUBLISHABLE_KEY;

export function createUserClient(jwt: string): SupabaseClient {
  return createClient(supabaseUrl || "", supabaseKey || "", {
    global: {
      headers: { Authorization: `Bearer ${jwt}` },
    },
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });
}

