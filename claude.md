# The Coffee Links Lite context

This branch is a clean loyalty fork, not the full commerce app. The only customer journey is:

```text
restore session → phone → OTP → name when new → member dashboard
```

The dashboard owns point balance, dynamic QR, manual member code and recent history. Account and full history are secondary destinations. Backend state is authoritative; local storage is an offline read cache only.

Use `AppSession` for app-level routing and orchestration, repository protocols for test seams, `APIClient` for REST, `KeychainStore` for secrets, `AppAttestClient` for protected writes and `LiteCache` for the profile/history snapshot. Avoid new abstractions unless the four-feature app genuinely needs them.

Visual work follows `UI.md`. Product and security invariants follow `agents.md`. Before handing off, confirm the app builds without Swift packages and that `main` has not been modified.
