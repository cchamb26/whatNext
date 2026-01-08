import "dotenv/config";
import { createClient, SupabaseClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_PUBLISHABLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn("[database] SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY not set");
}

// Defer creation to avoid crash on startup if env vars are missing
let _validatorClient: SupabaseClient | null = null;

function getValidatorClient(): SupabaseClient {
  if (!_validatorClient) {
    if (!supabaseUrl || !supabaseKey) {
      throw new Error("SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be set");
    }
    _validatorClient = createClient(supabaseUrl, supabaseKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false,
      },
    });
  }
  return _validatorClient;
}

export const validatorClient = {
  auth: {
    getUser: async (jwt: string) => getValidatorClient().auth.getUser(jwt),
  },
};

