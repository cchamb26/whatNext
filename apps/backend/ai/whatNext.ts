import { foodEntry } from "../types";
import { recommendation } from "./recommendation";
import { callLLM } from "./client";

export async function whatNext (
  input: foodEntry[],
  ): Promise<String>{
  const prompt = recommendation(input);
  const output = await callLLM(prompt);
  return output;
}
