# 🦞 openclaw-audit

**Free security self-check for OpenClaw installations.**

One command. Seven checks. Zero data leaves your machine.

```bash
curl -fsSL https://raw.githubusercontent.com/openclawhuber/openclaw-audit/main/openclaw-audit.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/openclawhuber/openclaw-audit.git
cd openclaw-audit
./openclaw-audit.sh
```

## What It Checks

| # | Check | What It Catches |
|---|-------|----------------|
| 1 | Config file | Missing or misplaced config |
| 2 | Telegram DM Policy | Open DMs = anyone can talk to your agent |
| 3 | Telegram allowFrom | Wildcard `*` or empty allowlist |
| 4 | Gateway Bind | Exposed on LAN or internet |
| 5 | Gateway Auth | Missing authentication on control port |
| 6 | Group Policy | Open group interactions |
| 7 | Model Fallbacks | No backup if primary model goes down |

## Sample Output

```
🦞 OpenClaw Security Audit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/7] Config file
  ✔ PASS:     Config found at ~/.openclaw/openclaw.json

[2/7] Telegram DM Policy
  ✖ CRITICAL: Telegram dmPolicy is 'open' — anyone can DM your bot!
              Fix: Set dmPolicy to 'allowlist' or 'pairing'

[3/7] Telegram allowFrom
  ✖ CRITICAL: Telegram allowFrom contains '*' — all users allowed!
              Fix: Replace '*' with specific Telegram user IDs
...

Summary
  Critical: 2  Warnings: 0  Pass: 5  Info: 0

  ⚠  ACTION REQUIRED — 2 critical issue(s) found!
```

## Requirements

- `bash` 4+
- `python3` (for JSON parsing)
- An OpenClaw installation with `openclaw.json`

## Custom Config Path

```bash
./openclaw-audit.sh /path/to/your/openclaw.json
```

## Contributing

PRs welcome! Ideas for more checks:
- SSL/TLS certificate validation
- Webhook exposure detection
- Auth token entropy check
- Sandbox configuration audit
- Memory/workspace permissions

## Need Professional Help?

**[Hire us on Upwork](https://upwork.com/freelancers/openclawhuber)** for:
- Full security audit ($75)
- Setup + hardening ($250)
- Monthly maintenance ($50/mo)

## License

MIT

---

*Built by Hunter (OpenClawHuber) 🦀*
