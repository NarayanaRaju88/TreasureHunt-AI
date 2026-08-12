# Personal Agent Backend (MVP)

The "brain" of your personal AI agent: takes a short text instruction,
uses Claude tool-use to decide what to do, and calls the real Gmail /
Calendar APIs on your behalf. Draft-only by default for email safety.

## 1. Prerequisites

- Node.js 18+
- A Google Cloud project with Gmail API + Calendar API enabled
- An Anthropic API key

## 2. Google Cloud Console setup

1. Go to console.cloud.google.com, create a new project.
2. Enable **Gmail API** and **Google Calendar API** (APIs & Services > Library).
3. Go to APIs & Services > Credentials > Create Credentials > OAuth client ID.
   - Application type: Web application
   - Authorized redirect URI: `http://localhost:3000/oauth/callback`
4. Copy the Client ID and Client Secret into your `.env`.
5. Under OAuth consent screen, add yourself as a **test user** — this lets
   you use sensitive scopes (gmail.modify, calendar) without going through
   Google's full verification process, which is only required for public
   apps with real end users.

## 3. Install & configure

```bash
cd personal-agent-backend
npm install
cp .env.example .env
# then fill in .env with your real keys
```

## 4. Run it

```bash
npm start
```

Then visit `http://localhost:3000/oauth/start` in a browser once, sign in
with your Google account, and approve access. This stores your tokens
locally in `tokens.json` (see security note below).

## 5. Test an instruction

```bash
curl -X POST http://localhost:3000/instruction \
  -H "Content-Type: application/json" \
  -d '{
    "text": "tell John I'\''ll send the report Friday",
    "styleContext": "Casual but professional, short sentences, signs off Thanks, Rahul"
  }'
```

Expected behavior:
- Claude calls `find_email_thread` internally first to resolve "John"
- If one clear match, it drafts a reply and returns it for your approval
- If multiple Johns match, it returns a clarifying question instead

Try also:
```bash
curl -X POST http://localhost:3000/instruction \
  -H "Content-Type: application/json" \
  -d '{"text": "what'\''s on my calendar tomorrow"}'
```

## 6. Response shapes

```jsonc
// Plain reply or clarifying question:
{ "type": "message", "text": "Did you mean John Mehta (re: Q3 Report) or John Kaur?" }

// Action that needs your approval (draft, event, send):
{
  "type": "action_result",
  "tool": "draft_email",
  "input": { "to": "john.mehta@acme.com", "subject": "Re: Q3 Report", "body": "..." },
  "result": { "status": "draft_created", "draft_id": "r-123", ... }
}
```

Your mobile app's job is: render `message` as chat text, and render
`action_result` as an approve/edit/discard card.

## 7. Security notes (read before using with real data)

- `tokens.json` stores your OAuth tokens **in plaintext** — fine for local
  testing only. Before this touches real, ongoing use, move token storage
  to an encrypted column in a real database (Supabase/Firebase/Postgres).
- Never expose this server to the public internet as-is — no auth is
  enforced on `/instruction` beyond it running on your machine. Add an
  API key or session check before deploying anywhere reachable.
- `send_email` bypasses draft review — the system prompt restricts when
  Claude uses it, but double check this behavior in testing before trusting it.

## 8. Next steps (not included in this MVP)

- Swap `tokenStore.js` for a real database
- Add the `style_samples` memory layer (feed past sent emails as context)
- Add auth/session handling for more than one user
- Wire this endpoint up to the Flutter mobile app's chat screen
