import { getGmail } from "./google.js";

function headerMap(headers = []) {
  const map = {};
  for (const h of headers) {
    if (h.name) map[h.name.toLowerCase()] = h.value || "";
  }
  return map;
}

function parseAddressList(value = "") {
  const results = [];
  const parts = value.split(",").map((p) => p.trim()).filter(Boolean);
  for (const part of parts) {
    const match = part.match(/^(?:"?([^"<]*)"?\s*)?<([^>]+)>$/);
    if (match) {
      results.push({ name: match[1].trim(), email: match[2].trim() });
    } else if (part.includes("@")) {
      results.push({ name: "", email: part.replace(/[<>]/g, "").trim() });
    }
  }
  return results;
}

function encodeRawMessage({ to, subject, body }) {
  const message = [
    `To: ${to}`,
    `Subject: ${subject}`,
    "MIME-Version: 1.0",
    "Content-Type: text/plain; charset=utf-8",
    "",
    body,
  ].join("\r\n");
  return Buffer.from(message).toString("base64url");
}

async function getMyEmail(gmail) {
  const profile = await gmail.users.getProfile({ userId: "me" });
  return (profile.data.emailAddress || "").toLowerCase();
}

export async function findEmailThread({ query, context_hint }) {
  const gmail = getGmail();
  const me = await getMyEmail(gmail);
  const q = [`(from:${query} OR to:${query} OR "${query}")`];
  if (context_hint) q.push(`(${context_hint})`);

  const list = await gmail.users.messages.list({
    userId: "me",
    q: q.join(" "),
    maxResults: 20,
  });

  let messages = list.data.messages || [];
  if (messages.length === 0 && context_hint) {
    const fallback = await gmail.users.messages.list({
      userId: "me",
      q: `from:${query} OR to:${query} OR "${query}"`,
      maxResults: 20,
    });
    messages = fallback.data.messages || [];
  }

  const byEmail = new Map();
  for (const m of messages) {
    const full = await gmail.users.messages.get({
      userId: "me",
      id: m.id,
      format: "metadata",
      metadataHeaders: ["From", "To", "Cc", "Subject", "Date"],
    });
    const headers = headerMap(full.data.payload?.headers);
    const people = [
      ...parseAddressList(headers.from),
      ...parseAddressList(headers.to),
      ...parseAddressList(headers.cc),
    ].filter((p) => p.email && p.email.toLowerCase() !== me);

    for (const person of people) {
      const key = person.email.toLowerCase();
      if (byEmail.has(key)) continue;
      byEmail.set(key, {
        name: person.name || person.email,
        email: person.email,
        thread_id: full.data.threadId,
        last_subject: headers.subject || "",
        last_date: headers.date || "",
      });
    }
  }

  return [...byEmail.values()];
}

export async function draftEmail({ thread_id, to, subject, body }) {
  const gmail = getGmail();
  const requestBody = {
    message: {
      raw: encodeRawMessage({ to, subject, body }),
    },
  };
  if (thread_id) requestBody.message.threadId = thread_id;

  const created = await gmail.users.drafts.create({
    userId: "me",
    requestBody,
  });

  return {
    status: "draft_created",
    draft_id: created.data.id,
    message_id: created.data.message?.id,
    thread_id: created.data.message?.threadId || thread_id || null,
    to,
    subject,
  };
}

export async function sendEmail({ thread_id, to, subject, body }) {
  const gmail = getGmail();
  const requestBody = {
    raw: encodeRawMessage({ to, subject, body }),
  };
  if (thread_id) requestBody.threadId = thread_id;

  const sent = await gmail.users.messages.send({
    userId: "me",
    requestBody,
  });

  return {
    status: "sent",
    message_id: sent.data.id,
    thread_id: sent.data.threadId || thread_id || null,
    to,
    subject,
  };
}

function startOfToday() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

function startOfWeek() {
  const d = startOfToday();
  const day = d.getDay();
  const diff = day === 0 ? 6 : day - 1;
  d.setDate(d.getDate() - diff);
  return d;
}

function gmailAfterQuery(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `after:${y}/${m}/${day}`;
}

export async function summarizeInbox({ filter }) {
  const gmail = getGmail();
  let q = "";
  if (filter === "unread") q = "is:unread";
  else if (filter === "today") q = gmailAfterQuery(startOfToday());
  else if (filter === "this_week") q = gmailAfterQuery(startOfWeek());
  else q = "is:unread";

  const list = await gmail.users.messages.list({
    userId: "me",
    q,
    maxResults: 15,
  });
  const messages = list.data.messages || [];
  const items = [];

  for (const m of messages) {
    const full = await gmail.users.messages.get({
      userId: "me",
      id: m.id,
      format: "metadata",
      metadataHeaders: ["From", "Subject", "Date"],
    });
    const headers = headerMap(full.data.payload?.headers);
    items.push({
      thread_id: full.data.threadId,
      from: headers.from || "",
      subject: headers.subject || "",
      date: headers.date || "",
      snippet: full.data.snippet || "",
    });
  }

  return { filter, count: items.length, emails: items };
}
