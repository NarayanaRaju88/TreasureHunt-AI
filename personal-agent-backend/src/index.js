import "dotenv/config";
import express from "express";
import { getAuthUrl, exchangeCode } from "./google.js";
import { hasTokens } from "./tokenStore.js";
import { runInstruction } from "./claude.js";

const app = express();
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true, googleConnected: hasTokens() });
});

app.get("/oauth/start", (_req, res) => {
  if (!process.env.GOOGLE_CLIENT_ID || !process.env.GOOGLE_CLIENT_SECRET) {
    res
      .status(500)
      .send("Missing GOOGLE_CLIENT_ID or GOOGLE_CLIENT_SECRET in .env");
    return;
  }
  res.redirect(getAuthUrl());
});

app.get("/oauth/callback", async (req, res) => {
  try {
    const { code, error } = req.query;
    if (error) {
      res.status(400).send(`OAuth error: ${error}`);
      return;
    }
    if (!code) {
      res.status(400).send("Missing OAuth code");
      return;
    }
    await exchangeCode(String(code));
    res.send(
      "Google account connected. You can close this tab and POST /instruction."
    );
  } catch (err) {
    res.status(500).send(`OAuth callback failed: ${err.message}`);
  }
});

app.post("/instruction", async (req, res) => {
  try {
    if (!process.env.ANTHROPIC_API_KEY) {
      res.status(500).json({
        type: "error",
        error: "Missing ANTHROPIC_API_KEY in .env",
      });
      return;
    }
    if (!hasTokens()) {
      res.status(401).json({
        type: "error",
        error:
          "Google is not connected. Visit http://localhost:3000/oauth/start first.",
      });
      return;
    }

    const text = req.body?.text;
    if (!text || typeof text !== "string") {
      res.status(400).json({
        type: "error",
        error: "Body must include a string field `text`.",
      });
      return;
    }

    const result = await runInstruction({
      text,
      styleContext: req.body?.styleContext,
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ type: "error", error: err.message || String(err) });
  }
});

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`Personal agent backend listening on http://localhost:${port}`);
  console.log(`Connect Google: http://localhost:${port}/oauth/start`);
});
