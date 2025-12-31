import OpenAI from "openai";
import { foodEntry } from "../types";
import { reccommendation } from "./reccomendation";

const endpoint = process.env.AZURE_OPENAI_ENDPOINT;
const apiKey = process.env.AZURE_OPENAI_API_KEY;
const deployment = process.env.AZURE_OPENAI_DEPLOYMENT;
const apiVersion = process.env.AZURE_OPENAI_API_VERSION;
const modelName = process.env.AZURE_OPENAI_MODEL_NAME;

if (!endpoint || !apiKey || !deployment || !apiVersion) {
  // eslint-disable-next-line no-console
  console.warn("[ai] Azure env variables are not fully set.");
}

export async function callLLM(foodHistory: foodEntry[]): Promise<string> {
  try {
    if (!endpoint || !apiKey || !deployment || !apiVersion) {
      throw new Error(
        "Azure config missing (endpoint / key / deployment / version).",
      );
    }

    const prompt = reccommendation(foodHistory);
    
    const response = await fetch(`${endpoint}openai/deployments/${deployment}/chat/completions?api-version=${apiVersion}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "api-key": apiKey,
      },
      body: JSON.stringify({
        messages: [{ role: "user", content: prompt }],
        temperature: 0.4,
      }),
    });

    if (!response.ok) {
      throw new Error(`Azure OpenAI error ${response.status}`);
    }

    const data = await response.json() as { choices: Array<{ message: { content: string } }> };
    return data.choices[0].message.content;

  } catch (error) {
    console.error("[callLLM] Error: ", error);
    throw error;
  }
}
