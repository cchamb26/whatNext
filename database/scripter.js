import { supabase } from "./supabaseClient.js";

const { data, error } = await supabase.from("foods").select("*").limit(1);

console.log({ data, error });
