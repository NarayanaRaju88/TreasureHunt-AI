import { google } from "googleapis";
import { loadTokens, saveTokens } from "./tokenStore.js";

const SCOPES = [
  "https://www.googleapis.com/auth/gmail.modify",
  "https://www.googleapis.com/auth/calendar",
];

export function createOAuthClient() {
  const client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_REDIRECT_URI || "http://localhost:3000/oauth/callback"
  );

  const tokens = loadTokens();
  if (tokens) {
    client.setCredentials(tokens);
  }

  client.on("tokens", (fresh) => {
    const current = loadTokens() || {};
    saveTokens({ ...current, ...fresh });
  });

  return client;
}

export function getAuthUrl() {
  const client = createOAuthClient();
  return client.generateAuthUrl({
    access_type: "offline",
    prompt: "consent",
    scope: SCOPES,
  });
}

export async function exchangeCode(code) {
  const client = createOAuthClient();
  const { tokens } = await client.getToken(code);
  saveTokens(tokens);
  client.setCredentials(tokens);
  return tokens;
}

export function getGmail() {
  return google.gmail({ version: "v1", auth: createOAuthClient() });
}

export function getCalendar() {
  return google.calendar({ version: "v3", auth: createOAuthClient() });
}
