import { foodEntry } from "../types.js";
import { recommendation } from "./recommendation.js";
import { callLLM } from "./client.js";

export async function whatNext (
  input: foodEntry[],
  ): Promise<String>{
  const prompt = recommendation(input);
  const output = await callLLM(prompt);
  return output;
}
