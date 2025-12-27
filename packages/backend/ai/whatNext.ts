import OpenAI from "openai";

const endpoint = process.env.AZURE_OPENAI_ENDPOINT;
const apiKey = process.env.AZURE_OPENAI_API_KEY;
const deployment = process.env.AZURE_OPENAI_DEPLOYMENT;
const apiVersion = process.env.AZURE_OPENAI_API_VERSION;
const modelName = process.env.AZURE_OPENAI_MODEL_NAME;

const options = { endpoint, apiKey, deployment, apiVersion };