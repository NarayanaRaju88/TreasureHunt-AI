# SHA-1 for Google Sign-In (AI Treasure Hunt)

Google Sign-In needs the **SHA-1 of the keystore that signs your APK**, not anything from the Git repo itself.

## Your project SHA-1 (stable CI / upload key)

```text
SHA1: 9F:CE:1B:79:2D:22:55:E9:84:A4:3C:4A:A5:0F:0F:D2:04:BD:36:42
SHA256: B9:9D:E1:76:C0:BD:14:22:F8:B8:61:EE:7F:DB:20:DA:0F:59:51:A0:29:56:44:1E:56:EF:3F:1D:EE:64:57:02
```

## Add it in Firebase (web)

1. Open Firebase → Project settings → Your apps → `app.aitreasurehunt`
2. Click **Add fingerprint**
3. Paste the **SHA1** value above
4. Save
5. Download a new `google-services.json` into `android/app/`
6. Rebuild/install the APK from GitHub Actions

## Get SHA-1 from GitHub Actions (web)

1. GitHub → Actions → **Build Flutter APK** → Run workflow
2. Open the run → **Print release signing SHA-1** step
3. Copy the `SHA1:` line
4. Or download the `signing-sha-fingerprints` artifact

## Important

- Guest / Email login do **not** need SHA-1
- This keystore is for development/CI. Create a new private keystore before a real Play Store release
