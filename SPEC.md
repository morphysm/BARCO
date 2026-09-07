# SPEC — Barco

Technical specification. Read `AGENTS.md` first for invariants and
`GLOSSARY.md` for domain vocabulary (which is never translated).

Design rationale lives in `docs/GDD_barco.md` (Portuguese). This file is the
implementation contract.

---

## 1. What this is

A paid ritual application. The user maintains an `assentamento` per entity,
traces a `ponto_riscado`, makes `oferendas`, and performs a symbolic
`sacrificio`. The digital act replaces the physical slaughter of an animal
while preserving what makes a sacrifice a sacrifice: cost, gesture, elapsed
time, irreversibility.

The product sells the act. It never sells the outcome.

### 1.1 The three phases

The app opens in three phases, in this order. A.C. set them. Each is a
gate: the next does not exist for a person who has not passed the one
before it.

**1. The three `pontos`.** The person traces the three `assinaturas` of
the `irmandade` — `Exu Caveira`, `Rosa Negra`, `Exu Aranha`. This is the
only content at first launch, and passing it is what opens the
`assentamento`. The threshold `firmeza` per `ponto`, and whether all
three must be traced in one sitting, are **not decided** —
`Passagem.FIRMEZA_MINIMA` is 0 for now, so naming the entity is enough.
A `face_indefinida` never counts, and an `abandonado` less so: the phase
asks for the three signatures, not three attempts.

Between 1 and 2 there is a passage: **the eclipse.** A huge sun, the moon
crossing it, the black sun, and the light going out — then the
`assentamento`. It runs in real time and cannot be skipped: no button, no
tap shortens it, like `permanencia` (§7). It is seen once. Sound plays
over it (`scenes/eclipse.tscn`, `shaders/eclipse.gdshader`).

**2. The `assentamento`.** The room is now reachable. The person makes
`oferendas` and `pedidos` in it. This is where a `trabalho` runs (§7),
and where everything accumulates and never leaves (§8.1).

**3. The `fornalha`.** An exercise in renewal: the person names symbols
of their own past and sets them on fire. Distinct from the `pedido`,
which asks forward and burns over seven days — the `fornalha` is about
what is behind, and it is the person's own material, not a petition to
anyone. Nothing of it is built. What burns, how it is named, how long it
takes, and what the `caderno` records of it are all **not decided**.

The `sacrificio` (§8.2) is not one of the three. Where it sits relative
to them is **not decided**.

---

## 2. Stack

- **Client:** Godot 4.x. Export target: **desktop (Linux, Windows)**.

  Web and Android are deferred, not abandoned. Models ship at source
  quality; cutting them down to fit a phone is what broke the roses, the
  staff and the bill, and that cost is not worth paying yet. The Web
  preset and `tools/decimar_modelos.py` both stay, ready for the day a
  phone build matters.

  Two designed mechanics need a phone and cannot ship on desktop: pouring
  by tilting the device (§8.1) and the `asmodeu` seal that reads how the
  device is held (GDD §3.1). Both wait for the phone build.
- **Server:** Supabase or Pocketbase. Hosted in the EU (operator is in Sweden;
  GDPR applies).
- **Payments:** Ko-fi, out of band, reconciled by webhook.

### Repo layout

```
/
├── AGENTS.md
├── SPEC.md
├── GLOSSARY.md
├── CONTENT.pt.md
├── docs/GDD_barco.md
├── client/                    # Godot project
│   ├── project.godot
│   ├── resources/
│   │   ├── entities/*.tres
│   │   ├── coroas/*.tres
│   │   └── oferendas/*.tres
│   ├── scenes/
│   ├── scripts/
│   └── shaders/
└── server/
    ├── functions/kofi_webhook/
    ├── functions/timers/
    └── migrations/
```

---

## 3. Data model

### 3.1 Entity (`Resource`, `.tres`)

Content is data, not code. Adding an entity must never require a recompile.

```gdscript
class_name Entidade extends Resource

@export var slug: String              # exu_aranha
@export var nome: String              # "Exu Aranha"
@export var coroa: String             # lucifer | belzebu | astaroth
@export var reino: String
@export var ponto_riscado: PontoData   # the whole ponto — this entity's assinatura
@export var ponto_cantado: AudioStream
@export var letra: String
@export var cores: PackedColorArray
@export var dias_semana: Array[int]   # 0=Sun .. 6=Sat
@export var hora_minima: int          # 0-23, -1 = no restriction
@export var animal_tradicional: String
@export var oferendas_aceitas: Array[String]
@export var dominio: Array[String]
@export var texto_apresentacao: String   # sourced from CONTENT.pt.md
```

`coroa` holds only the three territorial crowns. `asmodeu` is **not** an entity
field — it is a time state (§6.2).

### 3.2 Irmandade

```gdscript
class_name Irmandade extends Resource

@export var slug: String              # calunga_pequena
@export var nome: String
@export var reino: String
@export var rei: String               # exu_caveira — doctrine, not mechanics
@export var entidades: Array[Entidade]
```

Every member's `ponto_riscado` lives in the `irmandade`'s single reference
space, so one finger trace means the same thing against every member. The
signatures themselves stay independent.

### 3.3 Server tables

```
profiles        id, tz, created_at
assentamentos   id, user_id, entidade_slug, firmeza, updated_at
depositos       id, assentamento_id, oferenda_slug, entidade_slug,
                position_x, position_y, created_at
                -- append-only; visual accumulation
trabalhos       id, user_id, irmandade_slug, entidade_slug, state,
                firmeza, opened_at, permanencia_ends_at,
                candle_ends_at, closed_at
caderno         id, user_id, trabalho_id, payload jsonb, created_at
                -- APPEND ONLY. No delete endpoint. See AGENTS.md.
selos           id, user_id, coroa_slug, opened_at, vigilia_ends_at
criacao         id, user_id, entidade_slug, animal, started_at,
                ready_at, fed_days int[], consumed_at
creditos        id, user_id, ato_slug, source_payment_id, spent_at
pagamentos      id, user_id, kofi_message_id UNIQUE, amount, currency,
                raw jsonb, matched_by, created_at
reconciliacao   id, kofi_message_id, raw jsonb, resolved_by, resolved_at
```

`pagamentos.kofi_message_id` carries a UNIQUE constraint. That constraint is
the idempotency guarantee — do not rely on application-level checks alone.

---

## 4. Ponto riscado — tracing system

The core input. Not decoration.

### 4.1 Capture

- `InputEventScreenDrag` sampled into a `PackedVector2Array`.
- Normalise to a reference resolution before comparison.
- Segment starts are marked on screen; the path itself is not.
- Rendered with `Line2D` + granular shader (chalk on stone).

### 4.2 Scoring

Compare the user polyline against the reference `Curve2D` baked points using
**discrete Fréchet distance**.

```
accuracy    = clamp(1.0 - frechet_dist / TOLERANCE_PX, 0.0, 1.0)
order       = segments_started_in_sequence / total_segments
continuity  = clamp(1.0 - breaks / expected_strokes, 0.0, 1.0)

firmeza     = round(100 * (0.50*accuracy + 0.30*order + 0.20*continuity))
```

`TOLERANCE_PX = 40` at reference scale. Tune against playtest, keep the
weights.

Lifting the finger mid-segment counts as a break. `firmeza` travels with the
`trabalho` through the whole cycle.

A poor trace produces a weak `trabalho` and the app says so. Retracing costs
time, never money.

### 4.3 First contact

The first encounter with each entity is a guided trace: free, unscored,
unlimited. Scoring begins only after that.

---

## 5. Irmandades and assinaturas

An `irmandade` is a set of entities that share identities and behaviours,
answer in one `reino`, and accumulate in one `assentamento`.

The first `irmandade` is `calunga_pequena` — the cemetery. **`Exu Caveira`
reigns there.** `Rosa Negra` is the cemetery-current Pombagira beside him.
`Exu Aranha` is the teia that weaves and has presence in both.

### 5.1 One signature per entity

Every entity carries its own whole `ponto_riscado` — its `assinatura` — as
drawn. **Signatures never share geometry and are never composed from each
other.** There is no shared base and no common core: the ponto of an
entity is that entity's, and building one out of pieces of another is an
invention the app must not make.

Each `assinatura` is a **faithful copy** of an authored drawing in
`references/`, vectorised by `tools/extrair_sigilo.py`. Nothing is
summarised, simplified or reinvented: rain, grave-ticks, crosses, skull,
lightning and flame are all in the `ponto`, because the `ponto` is the
drawing. The difficulty is the practice, and the guided trace (§4.3) is
what carries the person through it.

Current stroke counts: `Exu Caveira` 143, `Rosa Negra` 58,
`Exu Aranha` 72.

The vectoriser measures. **Stroke order is doctrine**, not measurement.
A.C. set it: **top to bottom, left to right.** It governs two things,
and neither comes out of the drawing — both come out of the contour
walker, which starts wherever it happens to start:

1. **Which stroke comes first.** Strokes are ordered by where they begin:
   higher first, and left first among strokes that begin at the same
   height. "Same height" is a band of 3% of the sigil's height, so a
   one-pixel difference never outranks being further left.
2. **Where each stroke begins.** A stroke starts at its higher end, or at
   its left end when both ends are level. This matters as much as the
   order: the Fréchet distance walks two paths in step, so a segment
   stored against the direction the person draws it scores far away on a
   perfect trace.

`tools/extrair_sigilo.py` applies both (`endireitar`, `chave_de_leitura`).

All signatures of one `irmandade` live in a single reference space, so one
finger trace means the same thing against every member.

The user never picks an entity from a menu. They trace a signature and
find out who answered.

### 5.2 Classification

```
for each entity e in the irmandade:
    d_e = mean frechet(strokes, e.ponto_riscado segments)
          (a segment with no stroke costs 2 * TOLERANCE_PX)

if min(d) > TOLERANCE_PX           -> face_indefinida
elif min(d) / second_min(d) > 0.7  -> face_indefinida   # too close to call
else                               -> nearest entity
```

`firmeza` comes from the nearest signature's `accuracy`, `order` and
`continuity` (§4.2). Lifting the finger *between* two strokes of a
signature is not a break; lifting it *inside* one is.

### 5.3 Abandono and instinto

A risco that names no entity is not one thing. It is two, and they must
stay distinct.

**Abandonado.** Strokes of the `ponto` were never traced at all — coverage
below `COBERTURA_MINIMA` (0.75). The risco was left. It is worth nothing:
`firmeza` 0, no entity, and no benefit from the `hora_asmodeica` at any
hour. This is what stops "stop early" from being the cheapest route to a
high `firmeza` at night.

The threshold is not 1.0 on purpose: missing a four-pixel raindrop is not
giving up. It separates whoever stopped from whoever missed.

**Instinto.** The whole `ponto` was traced — in order, without stopping —
and it still settles on no `assinatura`. The hand went all the way without
binding itself to a form.

- Outside `hora_asmodeica`: `firmeza * 0.6`. The same ambiguity is failure,
  and the app does not reveal who answered.
- Inside `hora_asmodeica`: the act is what is measured. `cobertura` takes
  the place of `accuracy` in §4.2's formula — the weights are unchanged —
  and the result is then `* 1.25`, capped at 100.

```
instinto = 100 * (0.50*cobertura + 0.30*order + 0.20*continuity)
firmeza  = min(100, round(instinto * 1.25))
```

Substituting `cobertura` for `accuracy` is the rule, not a workaround. In
the hour, ambiguity outranks precision, so precision cannot be what scores
it — with `accuracy` in that slot the `* 1.25` can never overtake a
signature traced with care, and §5.3 would promise what the formula does
not deliver.

Measured, same hand: `rosa_negra` 91, `exu_caveira` 91, **instinto 100**,
instinto outside the hour 32, abandonado 0.

This inversion is the only place in the app where ambiguity outranks
precision. It is not documented in the UI. Do not add a tooltip, an
achievement, or a hint, and never announce the hour (§6.2).

## 6. Time

### 6.1 Calendar

- Each entity opens on specific weekdays (`dias_semana`) and after
  `hora_minima`.
- Outside its window an `assentamento` is `DORMENTE`. There is no way to force
  it and no way to purchase access.

### 6.2 hora_asmodeica

Second layer of time, overlaid on the calendar. **00:00–04:00** in the user's
declared timezone.

Resolved **server-side** from UTC plus `profiles.tz`. The client renders what
the server reports. A device clock change must not open the window.

Requires `selos` to contain an opened `asmodeu` seal.

While open:
- Every entity is worked under `asmodeu`, not its territorial `coroa`.
- Pombagira `oferendas`: `firmeza * 1.15`.
- Cutting and justice `oferendas`: `firmeza * 0.85`.
- `face_indefinida` inverts (§5.3).
- A low beat bed enters the ambient mix in every `reino` (§9).

No banner, no countdown, no announcement. Someone who works at night notices
something changed. Someone who does not never learns it exists.

**Never monetise the window.** No access sale, no extension, no notification
when it opens.

---

## 7. Ritual state machine

```
DORMENTE
   -> CHAMADO       ponto_cantado plays, light rises
   -> RISCO         trace -> firmeza, face classification
   -> OFERTA        payment consumed here (§10)
   -> PERMANENCIA   server timer, min 180s; app may be closed
   -> FECHAMENTO    extinguish, thank
   -> REGISTRADO    written to caderno, immutable
```

Exception state **`PENDENTE`**: `trabalho` not closed before its candle expired.
Renders darkened in the `assentamento`. No penalty, no notification, no charge.
It simply remains. Closing it is free and always available.

Implement as a `StateMachine` node with one script per state. Transitions are
validated server-side; the client cannot skip `PERMANENCIA`.

---

## 8. Offerings and sacrifice

### 8.1 Offering gestures

No offering is a cart addition.

- **Pour:** device tilt via accelerometer until the bottle empties. Tilting too
  fast spills outside the `ponto`.
- **Light:** drag the match, wait for the wick. The candle then burns in **real
  time** — 20 min, 7 h, or 7 days. Server-timed. The app may be closed.
- **Smoke:** circular finger motion over the `ponto`.
- **Deposit:** drag the object into place. It stays permanently — written to
  `depositos`, rendered forever.

Deposited roses wilt over months. Coins stack. A bottle stays empty until
refilled. Dust accumulates on an unvisited `assentamento`.

### 8.2 sacrificio

Three rules, all enforced in code:

1. The animal is **not an item**. It appears in no shop list, no inventory.
2. It is **raised before it is given**. A `criacao` row is created and the bird
   must be fed once per day for 7 or 21 days (`ready_at`). Feeding is one tap.
   `sacrificio` before `ready_at` is rejected server-side.
3. The moment is **silence, not spectacle**:

```
1. ponto_riscado traced, firmeza measured
2. bird brought to the ponto
3. BLACK SCREEN — 11 s, audio bus muted completely
4. ponto fills red, stroke by stroke, from inside out
5. audio returns: one atabaque hit
6. assentamento reappears, ponto firmado
```

No figurative rendering of the killing. The death is an ellipsis.

**Effect:** `sacrificio` does not raise the probability of anything. It raises
the `assentamento` firmeza ceiling permanently. Structural, not probabilistic.
Do not implement it as a buff or a multiplier on outcomes — there are no
outcomes.

---

## 9. Audio

- `ponto_cantado` per entity: real voice, atabaque, agogô. Not synthesised.
  Plays at CHAMADO and FECHAMENTO. Lyrics displayed.
- **Crowns:** no singing, no percussion. Bell and low drone only. The crowns
  sound European and cold against the percussive heat of the `reinos`.
- **`asmodeu`:** two bells tuned a few Hz apart, sounding together. The beat
  frequency between them *is* the crown. No new instrument, no voice. While
  `hora_asmodeica` is open, that beat sits very low under every `reino` bed.
- Ambient bed per `reino`: crickets and wind (`encruzilhada`), surf
  (`calunga_grande`), stone silence (`lira`), flies and standing water (`lodo`).
- Chalk-on-stone during tracing. Candle crackle loop while the app is open.
- **Silence is an event.** Hard cut, no fade, at `sacrificio` and `fechamento`.

Mix headphone-first. Assume night use, alone, with headphones.

---

## 10. Payments — Ko-fi

### 10.1 Currency

Ko-fi's unit is the "coffee". Bind the app economy to it directly.

**1 coffee = 21 SEK**

| Act | Coffees | SEK |
|---|---|---|
| Candle, 20 min | 1 | 21 |
| Drink or smoke `oferenda` | 1 | 21 |
| Full `trabalho` | 3 | 63 |
| Seven-day candle | 3 | 63 |
| `assentamento` firmeza | 7 | 147 |
| `sacrificio` | 7 | 147 |

Permanently free: tracing and learning any `ponto`, opening any `selo`, hearing
any `ponto_cantado`, visiting an `assentamento`, reading the `caderno`, and
**closing a `PENDENTE` trabalho**.

### 10.2 Flow

```
1. App generates a short code:  BAR-7X2K
2. App displays the code and opens the Ko-fi link
3. User pays, pastes the code into the message field
4. Ko-fi POSTs to the webhook endpoint
5. Backend verifies token, matches code, credits the act
6. Backend returns 200
```

### 10.3 Webhook handler

Ko-fi POSTs on payment to the URL configured at `ko-fi.com/manage/webhooks`.
The payload carries a verification token and a unique message identifier.

**Confirm the exact field names against a live test payload from the Ko-fi
webhooks page before writing the parser. Do not assume the schema.**

Requirements:

- Verify the token before any processing. Reject silently otherwise.
- `INSERT ... ON CONFLICT (kofi_message_id) DO NOTHING`, then return 200.
  Ko-fi retries with the same message id until it receives 200 — a
  non-idempotent handler will credit the same payment repeatedly.
- Return 200 for duplicates too. A duplicate is a success, not an error.
- There is **no refund or subscription-end event** in the API. It fires on
  payment only. Refunds are manual reconciliation. This is a further reason
  the app has no subscriptions.

### 10.4 Reconciliation

Users will forget to paste the code. Build the fallback cascade on day one:

```
code in message  ->  payer email match  ->  manual queue
```

Never auto-credit on a guess. The manual queue is a first-class feature with a
small admin view, not a TODO.

More robust alternative, prefer where possible: **one Ko-fi Shop item per act**,
fixed SKU, no dependence on typed text.

### 10.5 Second rail

Do not couple the domain logic to Ko-fi. Put it behind a `PaymentSource`
interface. Payment processors restrict occult and spiritual services, and it is
the processor that closes the account, not the platform. Stripe direct, Gumroad,
or Swish must be droppable in without touching ritual code.

---

## 11. Art constraints

- Engraving base: black-and-white hatching, scanned, grain overlay.
- Palette: red, gold, `pemba` white. Nothing else.
- Type: serif, tall, cordel-pamphlet register.
- UI as printed page. No cards, no soft shadows, no rounded corners.
- **Entities are never depicted figuratively.** No faces, ever. Presence is
  `ponto`, light, smoke, and object movement.
- Crowns: `selo` only, gold on black. No image, no spelled-out name on the main
  screen.

---

## 12. Milestones

**Vertical slice — 4 weeks.**
The `irmandade` of `calunga_pequena` only — `Exu Aranha`, `Rosa Negra`,
`Exu Caveira`. `assentamento`, the teia as `nucleo` plus three
`assinaturas`, candle, one `oferenda` each, `permanencia`, `caderno`. No
payment. Proves that signing on a shared `nucleo` lands. If it does not,
the whole app changes.

**MVP — 3 months.**
Adds `Tranca-Ruas das Almas` and `Maria Padilha`; `selos` for `lucifer` and
`asmodeu`; `hora_asmodeica`; Ko-fi webhook; 3 recorded `pontos cantados`.

`asmodeu` ships in the MVP, not V1. `hora_asmodeica` is a rule, not an asset —
two entities across two layers of time carry more depth than ten flat entities.

**V1.** Four `coroas`, 18 entities, `criacao` and `sacrificio` cycle,
`assentamento` decay, per-`reino` ambients, full calendar.

**V2.** Seven `reinos` complete, full `pontos cantados`, printed `caderno`
export.
