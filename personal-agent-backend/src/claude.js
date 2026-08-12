import { SYSTEM_PROMPT } from "./systemPrompt.js";
import { TOOL_DEFINITIONS, USER_FACING_TOOLS } from "./tools.js";
import {
  findEmailThread,
  draftEmail,
  sendEmail,
  summarizeInbox,
} from "./gmail.js";
import { getCalendarEvents, createCalendarEvent } from "./calendar.js";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MAX_TURNS = 8;

async function callClaude(messages) {
  const response = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": process.env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: process.env.ANTHROPIC_MODEL || "claude-sonnet-4-6",
      max_tokens: 1000,
      system: SYSTEM_PROMPT,
      messages,
      tools: TOOL_DEFINITIONS,
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    const detail = data?.error?.message || JSON.stringify(data);
    throw new Error(`Anthropic API error (${response.status}): ${detail}`);
  }
  return data;
}

async function executeTool(name, input) {
  switch (name) {
    case "find_email_thread":
      return findEmailThread(input);
    case "draft_email":
      return draftEmail(input);
    case "send_email":
      return sendEmail(input);
    case "summarize_inbox":
      return summarizeInbox(input);
    case "get_calendar_events":
      return getCalendarEvents(input);
    case "create_calendar_event":
      return createCalendarEvent(input);
    default:
      return { error: `Unknown tool: ${name}` };
  }
}

function textFromContent(content = []) {
  return content
    .filter((block) => block.type === "text" && block.text)
    .map((block) => block.text)
    .join("\n")
    .trim();
}

export async function runInstruction({ text, styleContext }) {
  const style = styleContext || "Casual but professional. Short sentences.";
  const messages = [
    {
      role: "user",
      content: `style_context: ${style}\n\ninstruction: ${text}`,
    },
  ];

  let lastAction = null;

  for (let turn = 0; turn < MAX_TURNS; turn++) {
    const data = await callClaude(messages);
    const content = data.content || [];
    const toolUses = content.filter((block) => block.type === "tool_use");

    if (toolUses.length === 0) {
      const assistantText = textFromContent(content);
      if (lastAction) {
        return {
          type: "action_result",
          tool: lastAction.tool,
          input: lastAction.input,
          result: lastAction.result,
          text: assistantText || undefined,
        };
      }
      return {
        type: "message",
        text: assistantText || "I need a bit more detail to do that.",
      };
    }

    messages.push({ role: "assistant", content });

    const toolResults = [];
    for (const use of toolUses) {
      let result;
      try {
        result = await executeTool(use.name, use.input || {});
      } catch (err) {
        result = { error: err.message || String(err) };
      }

      if (USER_FACING_TOOLS.has(use.name) && !result?.error) {
        lastAction = { tool: use.name, input: use.input, result };
      }

      toolResults.push({
        type: "tool_result",
        tool_use_id: use.id,
        content: JSON.stringify(result),
      });
    }

    messages.push({ role: "user", content: toolResults });
  }

  if (lastAction) {
    return {
      type: "action_result",
      tool: lastAction.tool,
      input: lastAction.input,
      result: lastAction.result,
      text: "Stopped after too many tool turns; last action is included.",
    };
  }

  return {
    type: "message",
    text: "I couldn't finish that request. Try again with a bit more detail.",
  };
}
