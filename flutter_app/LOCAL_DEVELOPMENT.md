# Local development with Supabase

Select `JUMA: local development (Supabase)` in VS Code and launch in debug mode.
Click **Әзірлеуші ретінде кіру**. No registration, password or SMS input is needed.
This uses real Supabase sessions and persistent database records, not demo data.
VS Code's pre-launch task starts `scripts/local_development_login.py` on
127.0.0.1:8081. The script requires Python 3 and an authenticated Supabase CLI.

On first launch it creates a separate development account and the company
`JUMA — әзірлеу` through the normal company-creation RPC, which assigns the
owner role. A random account password is stored only in the gitignored
`.local-development/account.json` (0600 permissions). Keep that file to reuse
the same company and test records. The administrative API key is used in memory
only for provisioning, never returned to the browser or saved in that file.

The session endpoint accepts POST requests only from the two local port-8080
origins, with a custom request header. Do not expose or proxy port 8081 publicly.
Stop the VS Code development-login task when finished. To run manually:

```sh
python3 scripts/local_development_login.py
# In another terminal, from flutter_app/:
flutter run -d chrome --web-port 8080 --web-hostname 127.0.0.1 --dart-define=LOCAL_DEVELOPMENT_ACCESS=true
```

Only the configured `DEVELOPMENT_USER_ID` may postpone contact verification,
and only in a debug web build served from localhost/loopback with
`LOCAL_DEVELOPMENT_ACCESS=true`. Release/profile builds ignore this option.
Supabase email sign-in requirements, company membership, roles and RLS remain
enforced. No password or privileged API key is stored in the launch configuration.

The optional existing-account verification bypass is separate from the button.
The button always signs in to the dedicated account, never to another user.

iOS simulator builds can also opt in with
`--dart-define=LOCAL_DEVELOPMENT_SIMULATOR=true`, together with
`LOCAL_DEVELOPMENT_ACCESS=true`. Start the broker on the Mac first; the iOS
simulator reaches it through 127.0.0.1. Release builds always disable this path.

For the normal verification flow, launch `JUMA Flutter (Chrome, 8080)` instead.
Before shipping, configure email/SMS delivery and test registration without these
defines. The development option does not modify email/phone verification records.
