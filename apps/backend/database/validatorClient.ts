import "dotenv/config";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_PUBLISHABLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn("[database] SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY not set");
}

export const validatorClient = createClient(
  supabaseUrl || "",
  supabaseKey || "",
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  }
);

