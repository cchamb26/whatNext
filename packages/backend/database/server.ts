import "dotenv/config";
import express, { Request, Response } from "express";
import { validatorClient } from "./validatorClient";
import { createUserClient } from "./userClient";
import { whatNext } from "../ai/whatNext";

const app = express();
app.use(express.json());

interface AuthResult {
  user?: { id: string };
  jwt?: string;
  error?: string;
  status?: number;
}

// Helper: extract and verify JWT
async function authenticateRequest(req: Request): Promise<AuthResult> {
  const auth = req.headers.authorization || "";
  const jwt = auth.startsWith("Bearer ") ? auth.slice(7) : null;

  if (!jwt) {
    return { error: "Missing Authorization: Bearer <token>", status: 401 };
  }

  const {
    data: { user },
    error: userErr,
  } = await validatorClient.auth.getUser(jwt);

  if (userErr || !user) {
    return { error: "Invalid token", status: 401 };
  }

  return { user, jwt };
}

// Test endpoint
app.get("/test", (_req: Request, res: Response) => {
  res.json({ message: "Server is running" });
});

// GET /meals/latest - fetch recent meals
app.get("/meals/latest", async (req: Request, res: Response) => {
  const authResult = await authenticateRequest(req);
  if (authResult.error) {
    return res.status(authResult.status!).json({ error: authResult.error });
  }

  const userClient = createUserClient(authResult.jwt!);

  const { data, error } = await userClient
    .from("meals")
    .select("*")
    .order("occurred_at", { ascending: false })
    .limit(30);

  if (error) {
    return res.status(400).json({ error: error.message });
  }

  res.json({
    user_id: authResult.user!.id,
    meals: data,
  });
});

// POST /meals - add a new meal
app.post("/meals", async (req: Request, res: Response) => {
  const authResult = await authenticateRequest(req);
  if (authResult.error) {
    return res.status(authResult.status!).json({ error: authResult.error });
  }

  const { name, hour, minute, meal_event, occurred_at } = req.body;

  if (!name || hour === undefined || minute === undefined || !meal_event) {
    return res
      .status(400)
      .json({ error: "Missing required fields: name, hour, minute, meal_event" });
  }

  const userClient = createUserClient(authResult.jwt!);

  const { data, error } = await userClient
    .from("meals")
    .insert({
      user_id: authResult.user!.id,
      name,
      hour,
      minute,
      meal_event,
      occurred_at: occurred_at || new Date().toISOString(),
    })
    .select()
    .single();

  if (error) {
    return res.status(400).json({ error: error.message });
  }

  res.status(201).json({ meal: data });
});

// DELETE /meals/:id - delete a meal
app.delete("/meals/:id", async (req: Request, res: Response) => {
  const authResult = await authenticateRequest(req);
  if (authResult.error) {
    return res.status(authResult.status!).json({ error: authResult.error });
  }

  const userClient = createUserClient(authResult.jwt!);

  const { error } = await userClient
    .from("meals")
    .delete()
    .eq("id", req.params.id);

  if (error) {
    return res.status(400).json({ error: error.message });
  }

  res.json({ success: true });
});

// POST /recommend - get AI recommendation based on recent meals
app.post("/recommend", async (req: Request, res: Response) => {
  const authResult = await authenticateRequest(req);
  if (authResult.error) {
    return res.status(authResult.status!).json({ error: authResult.error });
  }

  const userClient = createUserClient(authResult.jwt!);

  // Fetch recent meals
  const { data: meals, error: fetchError } = await userClient
    .from("meals")
    .select("*")
    .order("occurred_at", { ascending: false })
    .limit(30);

  if (fetchError) {
    return res.status(400).json({ error: fetchError.message });
  }

  if (!meals || meals.length === 0) {
    return res.status(400).json({ error: "No meals found. Add some meals first!" });
  }

  // Convert to foodEntry format for AI
  const foodEntries = meals.map((m) => ({
    name: m.name,
    hour: m.hour,
    minute: m.minute,
    mealEvent: m.meal_event,
  }));

  try {
    const recommendation = await whatNext(foodEntries);
    res.json({ recommendation });
  } catch (err) {
    console.error("[/recommend] AI error:", err);
    res.status(500).json({ error: "Failed to generate recommendation" });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

