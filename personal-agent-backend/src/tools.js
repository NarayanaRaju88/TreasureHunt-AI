export const TOOL_DEFINITIONS = [
  {
    name: "find_email_thread",
    description:
      "Search the user's Gmail for threads/contacts matching a name or partial detail, to resolve ambiguous references before drafting or replying. Always call this first if the instruction references a person by first name only, a vague description, or doesn't specify a full email address.",
    input_schema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description:
            "Name, partial email, or keyword to search for, e.g. 'John' or 'quarterly report thread'",
        },
        context_hint: {
          type: "string",
          description:
            "Any extra detail from the instruction that helps narrow the search, e.g. 'about the report'",
        },
      },
      required: ["query"],
    },
  },
  {
    name: "draft_email",
    description:
      "Create a draft reply or new email in the user's Gmail. Does not send it — the user reviews and approves separately.",
    input_schema: {
      type: "object",
      properties: {
        thread_id: {
          type: "string",
          description:
            "Gmail thread ID to reply to, if this is a reply. Omit for a new email.",
        },
        to: {
          type: "string",
          description: "Recipient email address",
        },
        subject: {
          type: "string",
          description: "Email subject line",
        },
        body: {
          type: "string",
          description: "Full email body text, written in the user's tone",
        },
      },
      required: ["to", "subject", "body"],
    },
  },
  {
    name: "send_email",
    description:
      "Send an email immediately without draft review. Only use when the user explicitly says to send directly, e.g. 'send it now' or 'no need to review'.",
    input_schema: {
      type: "object",
      properties: {
        thread_id: { type: "string" },
        to: { type: "string" },
        subject: { type: "string" },
        body: { type: "string" },
      },
      required: ["to", "subject", "body"],
    },
  },
  {
    name: "summarize_inbox",
    description: "Fetch and summarize recent or unread emails.",
    input_schema: {
      type: "object",
      properties: {
        filter: {
          type: "string",
          enum: ["unread", "today", "this_week"],
          description: "Which emails to summarize",
        },
      },
      required: ["filter"],
    },
  },
  {
    name: "get_calendar_events",
    description: "Retrieve calendar events for a given date or range.",
    input_schema: {
      type: "object",
      properties: {
        start_date: {
          type: "string",
          description: "ISO date, e.g. 2026-08-13",
        },
        end_date: {
          type: "string",
          description: "ISO date, defaults to start_date if omitted",
        },
      },
      required: ["start_date"],
    },
  },
  {
    name: "create_calendar_event",
    description: "Create a new calendar event.",
    input_schema: {
      type: "object",
      properties: {
        title: { type: "string" },
        date: { type: "string", description: "ISO date" },
        start_time: { type: "string", description: "24hr HH:MM" },
        end_time: { type: "string", description: "24hr HH:MM" },
        attendees: {
          type: "array",
          items: { type: "string" },
          description: "Email addresses to invite, if any",
        },
      },
      required: ["title", "date", "start_time", "end_time"],
    },
  },
];

export const USER_FACING_TOOLS = new Set([
  "draft_email",
  "send_email",
  "summarize_inbox",
  "get_calendar_events",
  "create_calendar_event",
]);
