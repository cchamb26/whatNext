import "dotenv/config";
import express from "express";
import { validatorClient } from "./validatorClient.js";
import { createUserClient } from "./userClient.js";

const app = express();

// test endpoint to verify server is running
app.get("/test", (req, res) => {res.json({ message: "Server is running" });});

app.get("/meals/latest", async (req, res) => {

  // get token from authorization header
  const auth = req.headers.authorization || "";
  const jwt = auth.startsWith("Bearer ") ? auth.slice(7) : null;
  if(!jwt) {
    return res.status(401).json({ error : "Missing Authorization: Bearer $(jwt)" });
  }

  // verify token
  const { data: {user}, error: userErr } = await validatorClient.auth.getUser(jwt);

  if(userErr || !user) {
    return res.status(401).json({ error: "invalid token"});
  }

  // query supabase as user
  const userClient = createUserClient(jwt);

  const {data, error} = await userClient
    .from("meals")
    .select("*")
    .order("occurred_at", { ascending:false })
    .limit(30);

  if(error) {
    return res.status(400).json({ error: error.message });
  }

  // get results
  res.json({
    user_id: user.id,
    meals: data
  });

});

app.listen(3000, () => {
  console.log("Server is running on http://localhost:3000");
});