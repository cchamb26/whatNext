import OpenAI from "openai";

const endpoint = process.env.AZURE_OPENAI_ENDPOINT;
const apiKey = process.env.AZURE_OPENAI_API_KEY;
const deployment = process.env.AZURE_OPENAI_DEPLOYMENT;
const apiVersion = process.env.AZURE_OPENAI_API_VERSION;
if (!endpoint || !apiKey || !deployment || !apiVersion) {
  // eslint-disable-next-line no-console
  console.warn("[ai] Azure env variables are not fully set.");
}

export async function callLLM(prompt:string): Promise<string> {
  try {
    if (!endpoint || !apiKey || !deployment || !apiVersion) {
      throw new Error(
        "Azure config missing (endpoint / key / deployment / version).",
      );
    } 
    
    const response = await fetch(`${endpoint}openai/deployments/${deployment}/chat/completions?api-version=${apiVersion}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "api-key": apiKey,
      },
      body: JSON.stringify({
        messages: [{ role: "user", content: prompt }], //sends prompt value to bot
        temperature: 0.4, //randomness/creativity level
      }),
    });

    if (!response.ok) { 
      throw new Error(`Azure OpenAI error ${response.status}`);
    }

    const data = await response.json() as { choices: Array<{ message: { content: string } }> };
    return data.choices[0].message.content; //returns message

  } catch (error) {
    console.error("[callLLM] Error: ", error);
    throw error;
  }
}
