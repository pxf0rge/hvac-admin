# lib/ layout

| Path | Purpose |
|------|---------|
| `app/` | Root `MaterialApp` / `HvacAdminApp` |
| `core/config/` | Environment, boot guards |
| `core/auth/` | Session bridge, role helpers |
| `core/controllers/` | `ChangeNotifier` controllers |
| `core/enums/` | `AdminModule`, domain enums |
| `core/errors/` | `HvacFailure` hierarchy |
| `core/routing/` | `go_router` configuration |
| `data/datasources/` | Supabase bootstrap, realtime |
| `data/mappers/` | Row ↔ model mappers |
| `data/repositories/` | Domain repository interfaces + impls |
| `data/wiring/` | Mock vs Supabase wiring |
| `design_system/` | Theme, tokens, shared widgets |
| `features/` | One folder per admin module |
| `l10n/` | Localization (English-first; optional later) |

See `docs/architecture.md` for layer rules and backend sharing.
