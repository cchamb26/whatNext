const endpoint = process.env.AZURE_ENDPOINT;
const modelName = process.env.AZURE_MODELNAME
const deployment = process.env.AZURE_DEPLOYMENT;
const key = process.env.AZURE_KEY;


import { AzureOpenAI } from "openai";

export async function main() {

  const apiKey = "<your-api-key>";
  const apiVersion = "2024-12-01-preview";
  const options = { endpoint, apiKey, deployment, apiVersion }

  const client = new AzureOpenAI(options);

  const response = await client.chat.completions.create({
    messages: [
      { role:"system", content: "You are a helpful assistant." },
      { role:"user", content: "I am going to Paris, what should I see?" }
    ],
    max_completion_tokens: 40000,
      model: modelName
  });

  if (response?.error !== undefined && response.status !== "200") {
    throw response.error;
  }
  console.log(response.choices[0].message.content);
}

main().catch((err) => {
  console.error("The sample encountered an error:", err);
});