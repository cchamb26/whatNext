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

// Root endpoint - API info
app.get("/", (_req: Request, res: Response) => {
  res.json({
    name: "whatNext API",
    status: "running",
    endpoints: {
      "GET /test": "Health check",
      "GET /meals/latest": "Get recent meals (requires auth)",
      "POST /meals": "Add a meal (requires auth)",
      "DELETE /meals/:id": "Delete a meal (requires auth)",
      "POST /recommend": "Get AI recommendation (requires auth)",
    },
  });
});

// Test endpoint
app.get("/test", (_req: Request, res: Response) => {
  res.json({ message: "Server is running" });
});

// Health check endpoint (Azure App Service)
app.get("/health", (_req: Request, res: Response) => {
  res.status(200).json({ status: "healthy" });
});

// GET /meals/latest - fetch recent meals with foods
app.get("/meals/latest", async (req: Request, res: Response) => {
  const authResult = await authenticateRequest(req);
  if (authResult.error) {
    return res.status(authResult.status!).json({ error: authResult.error });
  }

  const userClient = createUserClient(authResult.jwt!);

  // Fetch meals with their food items
  const { data, error } = await userClient
    .from("meals")
    .select(`
      id,
      occurred_at,
      meal_type,
      meal_items (
        food_id,
        foods (
          id,
          name
        )
      )
    `)
    .order("occurred_at", { ascending: false })
    .limit(30);

  if (error) {
    return res.status(400).json({ error: error.message });
  }

  // Transform to simpler format for the iOS app
  const meals = data?.map((meal: any) => {
    const occurredAt = new Date(meal.occurred_at);
    const foodNames = meal.meal_items
      ?.map((item: any) => item.foods?.name)
      .filter(Boolean)
      .join(", ");

    return {
      id: meal.id,
      name: foodNames || "Unknown",
      hour: occurredAt.getHours(),
      minute: occurredAt.getMinutes(),
      meal_event: meal.meal_type,
      occurred_at: meal.occurred_at,
    };
  });

  res.json({
    user_id: authResult.user!.id,
    meals: meals || [],
  });
});

// POST /meals - add a new meal
app.post("/meals", async (req: Request, res: Response) => {
  const authResult = await authenticateRequest(req);
  if (authResult.error) {
    return res.status(authResult.status!).json({ error: authResult.error });
  }

  const { name, meal_event, occurred_at } = req.body;

  if (!name || !meal_event) {
    return res.status(400).json({ error: "Missing required fields: name, meal_event" });
  }

  const userClient = createUserClient(authResult.jwt!);
  const userId = authResult.user!.id;
  const normalizedName = name.toLowerCase().trim();

  // 1. Find or create the food
  let { data: existingFood } = await userClient
    .from("foods")
    .select("id")
    .eq("normalized_name", normalizedName)
    .single();

  let foodId: string;

  if (existingFood) {
    foodId = existingFood.id;
  } else {
    const { data: newFood, error: foodError } = await userClient
      .from("foods")
      .insert({
        user_id: userId,
        name: name.trim(),
        normalized_name: normalizedName,
      })
      .select("id")
      .single();

    if (foodError) {
      return res.status(400).json({ error: foodError.message });
    }
    foodId = newFood.id;
  }

  // 2. Create the meal
  const { data: meal, error: mealError } = await userClient
    .from("meals")
    .insert({
      user_id: userId,
      meal_type: meal_event,
      occurred_at: occurred_at || new Date().toISOString(),
    })
    .select("id, occurred_at, meal_type")
    .single();

  if (mealError) {
    return res.status(400).json({ error: mealError.message });
  }

  // 3. Link meal to food via meal_items
  const { error: linkError } = await userClient
    .from("meal_items")
    .insert({
      user_id: userId,
      meal_id: meal.id,
      food_id: foodId,
    });

  if (linkError) {
    return res.status(400).json({ error: linkError.message });
  }

  const occurredAt = new Date(meal.occurred_at);
  res.status(201).json({
    meal: {
      id: meal.id,
      name: name.trim(),
      hour: occurredAt.getHours(),
      minute: occurredAt.getMinutes(),
      meal_event: meal.meal_type,
      occurred_at: meal.occurred_at,
    },
  });
});

// DELETE /meals/:id - delete a meal (meal_items cascade automatically)
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

  // Fetch recent meals with foods
  const { data: meals, error: fetchError } = await userClient
    .from("meals")
    .select(`
      id,
      occurred_at,
      meal_type,
      meal_items (
        foods (
          name
        )
      )
    `)
    .order("occurred_at", { ascending: false })
    .limit(30);

  if (fetchError) {
    return res.status(400).json({ error: fetchError.message });
  }

  if (!meals || meals.length === 0) {
    return res.status(400).json({ error: "No meals found. Add some meals first!" });
  }

  // Convert to foodEntry format for AI
  const foodEntries = meals.map((meal: any) => {
    const occurredAt = new Date(meal.occurred_at);
    const foodNames = meal.meal_items
      ?.map((item: any) => item.foods?.name)
      .filter(Boolean)
      .join(", ");

    return {
      name: foodNames || "Unknown",
      hour: occurredAt.getHours(),
      minute: occurredAt.getMinutes(),
      mealEvent: meal.meal_type,
    };
  });

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
