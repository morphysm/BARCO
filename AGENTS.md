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

### Money
- Closing a `trabalho` in `PENDENTE` state is **always free**. No exceptions.
- Never gate the `hora_asmodeica` behind payment.
- Never sell access outside a `dormente` window. No "open now" purchase.
- No subscriptions, no loot boxes, no randomised rewards, no intermediate
  soft currency. Prices are fixed and shown in USD — the currency Ko-fi
  charges in, so the number on the button is the number at checkout.
- Never write copy that promises an outcome. Copy describes the act performed,
  never its effect. This is a legal constraint, not a stylistic one.

### Time
- All timers are **server-authoritative**. Never trust the device clock for
  candle burn, `sacrificio` husbandry cycles, or `hora_asmodeica` windows.
- Client-side time is display only.

### Payments
- The Ko-fi webhook handler must be idempotent, keyed on the payment's unique
  message identifier. A retried delivery must never credit twice.
- Always return HTTP 200 on successful processing, including duplicates.
- Unmatched payments go to a manual reconciliation queue. Never auto-credit
  on a guess.

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
- Server code lives in `server/`. Never move a timer into `client/`.
- When unsure whether something is a design choice or an invariant, assume
  invariant and ask.
