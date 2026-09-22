# AGENTS.md

Project: **Barco** — a ritual application.
Read `SPEC.md` for architecture, `GLOSSARY.md` for domain vocabulary.

---

## INVARIANTS

These are not preferences. Do not violate them, do not "improve" them, do not
add a flag to bypass them. If a task appears to require breaking one, stop and
say so instead of implementing it.

### Irreversibility
- No undo anywhere in the ritual flow.
- The `caderno` is append-only. Do **not** create a DELETE endpoint for it.
- Records are erasable only by full account deletion (GDPR erasure path).
- Do not add "edit entry", "hide entry", or soft-delete flags.
- **One carve-out, and only one:** `Dados.apagar_tudo()` wipes the local
  files, and it is guarded by `OS.is_debug_build()`. It returns -1 and
  does nothing in a release build, and the button that calls it is never
  constructed there. This is the workbench, not a mechanic. Do not widen
  it, do not add a way to force it, and do not let anything in the ritual
  flow call it.

- The path to the `assentamento` (Porta, the three `pontos`, eclipse,
  `fornalha`) **replays on every launch** — owner's decision, 2026-09-22.
  `Passagem` keeps progress in memory only. Replaying is not an undo:
  `depositos` and `pedidos` stay saved and are never removed.

### Money
- **No payments in this build.** No server, no Ko-fi, no credits, no
  prices. Every `oferenda` is free. Do not add a purchase path back without
  the owner asking; the old payment code is in git history up to `9eeaa6c`.
- If payments ever return: closing a `trabalho` in `PENDENTE` is always
  free, the `hora_asmodeica` is never gated, no access is sold outside a
  `dormente` window, and no subscriptions, loot boxes, randomised rewards
  or soft currency.
- Never write copy that promises an outcome. Copy describes the act performed,
  never its effect. This is a legal constraint, not a stylistic one.

### Time
- There is no server. The **device clock, in the user's local timezone**,
  is the source of time for candle burn, `sacrificio` cycles and the
  `hora_asmodeica` window (00:00–04:00 local). Owner's decision,
  2026-09-22: a user who changes their clock changes the app's time, and
  that is accepted.
- Read time through `client/scripts/ritual/relogio.gd` (`Relogio`), not
  ad hoc.

### Content
- No figurative depiction of the `sacrificio`. The death is an ellipsis:
  black screen, silence, then the `ponto_riscado` fills red. Never render an
  animal being killed.
- Entities are never depicted figuratively. No faces. Presence is indicated by
  `ponto`, light, smoke, and object movement only.

### Notifications
- Never send a notification that implies guilt, urgency, debt, or displeasure.
- The only permitted push notification: a candle has finished burning.
- Do not implement streaks, daily-login rewards, or loss-aversion mechanics.

### Scope
- The app is **Barco**, not Quimbanda. Never label it as Quimbanda in code,
  copy, metadata, or store listings. The scope declaration in `CONTENT.pt.md`
  ships on first launch and is not dismissible.

---

## Working rules

- Domain terms in `GLOSSARY.md` are **never translated**, in code or in prose.
  Use `assentamento`, not `shrine`. Use `firmeza`, not `strength`.
- Identifiers are ASCII: `hora_asmodeica`, not `hora_asmodéica`.
- `CONTENT.pt.md` is authored by hand. Do not generate, rewrite, or translate
  ritual text, entity descriptions, or `ponto_cantado` lyrics. You may add
  structural placeholders and flag gaps.
- Prefer adding to `resources/entities/*.tres` over hardcoding entity data.
- There is no server. All state lives on the device (`user://`).
- When unsure whether something is a design choice or an invariant, assume
  invariant and ask.
