import { AzureOpenAI } from "openai";
import "dotenv/config";
import {foodEntry} from "../types";

export function reccommendation(input: foodEntry[]): string {
  const foodList = input
    .map((entry) => `name: ${entry.name}, time: ${entry.hour}:${entry.minute}, mealEvent: ${entry.mealEvent}`)
    .join("\n  ");
    return `
    You are a food recommendation service. Your flow is as follows:
     1. Food is inputted into a database over a period of time.
     2. User will ask you what they should eat next.
     3. A database of food options they have eaten over will be provided to you.
     4. Based on the values: foodEvent, time, and name, you will output a 
        reccommendation based ONLY on previous eaten foods, or foods that are SIMILAR 
        in nature.
    
    Previous Foods:
      ${foodList}
    
    Output a STRING in this format:

    Recommendation:
    <one concise food recommendation>

    Why:
    <short explanation referencing prior foods or patterns>

    Simple Recipe:
    - Ingredients: <comma-separated list>
    - Steps: <2-4 short steps>
  `;
};
