# Admin Console Setup

The Admin Console lets trusted operators see who signs in, browse activity logs, and review users/stats.

Access is **not** based on a client-writable profile flag. Use one of:

1. Firestore bootstrap doc: `admins/{uid}`
2. Firebase Auth custom claim: `{ "admin": true }`

## Create the first admin (recommended)

1. Sign in to the app once with the account you want as admin.
2. Open [Firebase Console](https://console.firebase.google.com/) → Authentication → find that user → copy **User UID**.
3. Firestore → create collection `admins` → document ID = that UID.
4. Optional fields (for your notes):

```json
{
  "email": "you@example.com",
  "role": "owner",
  "createdAt": "<server timestamp or ISO date>"
}
```

5. Deploy the updated security rules (includes `admins` + `activity_logs`):

```bash
firebase deploy --only firestore:rules
```

6. Force a fresh ID token (sign out / sign in, or kill and reopen the app).
7. Open **Settings** → **Admin Console**.

Clients cannot create `admins/{uid}` for themselves. The first admin must be created in the Console (or via Admin SDK). After that, an existing admin can add more `admins/{uid}` docs if your rules allow admin writes (they do).

## Optional: custom claim instead of / in addition to the doc

From a trusted backend or Cloud Function:

```js
await admin.auth().setCustomUserClaims(uid, { admin: true });
```

The user must refresh their token after the claim is set.

## What gets logged

Signed-in clients append their own rows to `activity_logs` on:

| Action | When |
|--------|------|
| `login_email` | Email/password sign-in |
| `login_google` | Google sign-in |
| `login_guest` | Guest / anonymous sign-in |
| `register` | New email registration |
| `logout` | Sign-out |

Only admins can **read** the full `activity_logs` collection.

## Collections

| Collection | Purpose |
|------------|---------|
| `admins/{uid}` | Bootstrap / grant admin |
| `activity_logs` | Login and session audit events |
| `users` | Profiles listed in Admin → Users |

## Security notes

- Do not put `isAdmin` on the user profile as the source of truth.
- Keep App Check and Firebase quotas enabled for production.
- Deploy rules before relying on the console in production.
