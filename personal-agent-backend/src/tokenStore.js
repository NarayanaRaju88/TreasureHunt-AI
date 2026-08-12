import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const TOKENS_PATH = join(dirname(fileURLToPath(import.meta.url)), "..", "tokens.json");

export function loadTokens() {
  if (!existsSync(TOKENS_PATH)) return null;
  try {
    return JSON.parse(readFileSync(TOKENS_PATH, "utf8"));
  } catch {
    return null;
  }
}

export function saveTokens(tokens) {
  writeFileSync(TOKENS_PATH, JSON.stringify(tokens, null, 2), "utf8");
}

export function hasTokens() {
  return loadTokens() != null;
}
