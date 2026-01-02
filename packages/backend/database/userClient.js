import "dotenv/config";
import { createClient } from "@supabase/supabase-js";

export function createUserClient(jwt) {
  
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_PUBLISHABLE_KEY,
    {
      global: {
        headers: { Authorization: `Bearer ${jwt}` }
      },
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false
      }
    }
  );

}