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

### 1.1 The Porta, and then the three phases

**0. The `Porta`.** The first thing a fresh install shows, before
anything else loads. A monochrome 90s terminal — bone-white on black,
`PxPlus IBM VGA8`, a CRT glass over the whole screen (`shaders/crt.gdshader`:
scanlines, barrel curvature, phosphor halo, and a colour fringe that
exists **only** past 74% of the radius, so the ritual text — which ends
at 71% — is never touched by it). Three diagnostic lines flash and clear,
then the text types itself, with a deliberate stop before the last line:
*mesmo sendo só um app* is the tonal turn, and a line that undoes
everything before it needs the silence of someone about to say something
else.

The text is A.C.'s and is in `CONTENT_pt.md`. Two answers, DOS-menu
style, arrow keys or pointer: **Deixo tudo na Porta e entro** writes
`atravessou_a_porta` in `Passagem` and opens the first `ponto`; **Desisto
e apago o app** quits. The app does not delete itself — deleting is the
person's act, which is why the line says *apago* and not *apague-me*.

Crossed once. Whoever entered is never asked again; whoever gave up
closed the app without entering, so the Porta is still shut and is there
again next time.

This `Porta` is not the door of the paragraphs below. That one is the
coverage threshold that lets a person pass from one `ponto` to the next
and has no screen of its own.

**Then the three phases**, in this order. A.C. set them. Each is a
gate: the next does not exist for a person who has not passed the one
before it.

**1. The three `pontos`, one at a time.** The app opens on the first
signature of the `irmandade` with the guide drawn under it. The person
traces over it and asks the guide: *posso passar?* One measure answers —
how much of **that** drawing was traced, measured against that signature
alone and not against the best of the three (`RiscoScoring.medir`).

Coverage is **geometric**, not a pairing count. A reference segment
counts as traced when most of its length has ink within tolerance,
whatever drew it — one long stroke or twenty short ones. It used to be
`segments_with_a_stroke_assigned / segments`, with the pairing one-to-one,
which answers a different question: *did you make one stroke per
segment?* Tracing the whole `ponto` with the hand down, in long
continuous strokes, covered dozens of segments with one stroke and had
all the others counted as untraced — with 143 segments and 25 strokes the
ceiling was 17%, so 70% could not be reached at all.

Enough, and the guide puts up the next one: `Exu Caveira`, then
`Rosa Negra`, then `Exu Aranha`, in the order of the `irmandade`. Not
enough, and it says so in red and the same drawing stays. Nobody chooses
anything along the way: there is the `ponto` in front of you.

The threshold is `RiscoScoring.COBERTURA_MINIMA`, **0.70**, and the door
has no number of its own — it is the `abandonado` threshold itself
(§5.3), so the door cannot disagree with the mark. Whoever abandons does
not enter (A.C.).

Crossed once. After the third the app opens on the `assentamento`.

Between 1 and 2 there is a passage: **the eclipse.** A huge sun, the moon
crossing it, the black sun, and the light going out. It runs in real time
and cannot be skipped: no button, no tap shortens it, like `permanencia`
(§7). It is seen once. Sound plays over it (`scenes/eclipse.tscn`,
`shaders/eclipse.gdshader`).

**2. The `fornalha` — leaving the past behind.** The black sun opens onto
a dark room: a Baphomet image, the morphysm sigil on the floor, and one
furnace. A question is put — *Você renega o teu passado e tudo falso que
você serviu?* — with one answer, **SIM**. There is no "no": the person
who reached this room traced the three `pontos` and crossed the eclipse,
and the app does not ask twice.

There are two answers and both are real. **NÃO** closes the app: nobody
is held in a room they refuse. **SIM** puts a cross in front of them —
double-click takes it, they carry it to the furnace mouth, another
double-click throws it in.

Fire grows in the mouth (`shaders/fogo.gdshader` — a billboarded quad,
not a sphere: a `SphereMesh` is a shell, every fragment sits at the same
radius, so a radial falloff computed on it cuts nothing and the fire
comes out an lit egg). Figures appear and dance in front of it, built
from `FormaDancante` — the procedural body architecture of the
`Hall_of_Repetition`, joints computed per frame, cylinders between them,
a displaced echo body, no rig. The music plays. When it ends the screen
says *Bem-vindo de volta ao lar!*, and then an iris closes over the fire
and opens again on the `assentamento` — one iris across two scenes.

The room is three walls and the furnace: `tools/gerar_sala_fornalha.gd`
writes it with real nodes — walls, floor sigil, Baphomet, three banners
(mast, crossbar, hanging cloth) and the marks where the figures stand —
so all of it is dragged in the editor, not written in code. The furnace
wears `shaders/ferro.gdshader`: raw iron with rust that catches on the
upward faces. The frame is portrait and narrow — about 4.6 m wide at the
furnace — and anything placed outside that cone is simply not seen.

**The three banners are the crucifixion** (A.C.). Each mast carries a
finial: a crown of thorns on one, and on the other two a cloth — the two
thieves. Nothing in the room says so, and nothing should; it is why there
are three and not two or four.

The two cloths ought to be white, and are the colour of the walls
instead. White is not the problem — the room's light is. Before the fire
catches, the only light is `luz_da_sala`, an ambient colour, and an
ambient gives every face the same amount whatever way it points: a white
cloth comes out a flat cut-out, not a hanging cloth, and reads as noise.
The fire's `OmniLight3D` does have a direction, so once the fire is lit a
white cloth would find its folds. What to do about the *before* is **not
decided**. Meanwhile they wear `MatPanoDeCima`, a `material_override` on
the scene, not a change to `cloth.glb` — one click undoes it.

Crossed once, and marked at the throw, not at the end: whoever closes the
app mid-fire has already burnt what they came to burn.

Once, and there is no door back. Nothing in the app clears `queimou`, and
both scenes that can open the furnace — `risco` and the eclipse — are
guarded by it. The room can still be revisited from outside, by
`tools/ver_fornalha.gd`, which points `Passagem.REGISTO` at a file of its
own before opening the scene: the rite runs whole, the throw marks that
side file, and the person's `passagem.json` is not touched. That is a
script in `tools/`, of the same standing as `Passagem.esquecer()` — it
exists, and no screen reaches it.

The furnace is one bay of the Exu Caveira furnace bank from *Iovana Is
DEAD*, copied without alteration by `tools/tirar_fornalha.py` — the
source project is read-only and never touched. Four of the five bays are
simply not referenced; the one that stays is `Bay3`, the middle one, the
only bay that sits centred without the bank having to be shoved sideways.
It came sealed, so two pieces of `Bay2` — the one that came open — are
moved 1.5 in x into it, whole and unrotated: the skull and bones, and the
open iron door. What the mouth does *not* wear is the pale refractory
ring `Bay3_RefractoryArch`: in the reference photo
(`the-ballerina/references/furnace-official.jpg`) the light firebrick is
on the inner face of the swung-open door, and the mouth itself is dark
iron and soot. The sealed door's ember seam goes with it — with no door
to run across, it hung in the air in front of the opening.

**3. The `assentamento`.** The room is now reachable. This is **the paid
phase** — the only one. `oferendas` are bought (§10.1: 1 coffee = 2 USD;
prices live in `cafes` on each `.tres` and are shown in USD, per
AGENTS.md). Everything in phases 1 and 2 is free and stays free: tracing
the three `pontos`, the eclipse, the `fornalha`.

**`pedidos` are free.** Writing one and spearing it on the trident costs
nothing, ever. What is bought is the `oferenda` placed beside it.

**`sangue` is not placed, it is thrown.** Every other `oferenda` is a
model set down on the floor; the blood is a bucket emptied over it. It
costs 7 coffees against everyone else's 1 — the `sacrificio` tier of
§10.1 — and it is the only offering with a shader of its own
(`shaders/sangue.gdshader`, on a `PocaDeSangue`). What makes it read as
liquid is not the colour but the light: the surface carries a slow skin
whose gradient becomes the normal, so the candle highlights crawl across
it on their own. The pool has a direction, a tongue that runs further
that way, and droplets that land only once the wave has reached them.
Its size is the `tamanho` on `sangue.tres`, like every other offering.

Throwing is a gesture; a deposit is a record. On reload the pool comes
back already spread — `_a_repor` — because what was deposited is not
performed again. And `_malhas()` skips it, or `_vestir()` would paint the
floor's material over the blood at the next deposit.

**An `oferenda` reinforces a `pedido`** (A.C.). That is a mechanic of the
rite, and it is the reason the two live in the same room. It is **not** a
promise: the app may show that an offering was made and that a `pedido`
burns, and must never say what either will do in the world. §10 and
AGENTS.md hold — copy describes the act performed, never its effect.
**How the reinforcement is measured is not decided.**

**Not built yet, and now visible:** prices are on the buttons but there
is no payment gate — `depor` currently costs nothing in the build. The
Ko-fi flow (§10.2–10.4) has to exist before this ships, or the prices
have to come off the screen.

The `sacrificio` (§8.2) is not one of the three. Where it sits relative
to them is **not decided**. So is what the `caderno` records of the
`fornalha`.

Two assets are A.C.'s and still missing: the Baphomet image (drop the PNG
in `client/resources/imagens/`, set `baphomet` on the scene root) and the
music (`client/resources/audio/`, set `musica`). Both have working
placeholders; neither is authored content of mine. The iris waits for the
music to finish, so no duration is written down anywhere — swapping the
file is enough.

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
- **Server:** Supabase — decided, not open any more. Postgres with RLS,
  Edge Functions in Deno. Hosted in the EU (operator is in Sweden; GDPR
  applies). `server/LEIA-ME.md` says how to prove it without an account.
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

For the same reason, `creditos.source_payment_id` is UNIQUE: **one payment,
at most one credit.** The code channel was already single-use — `codigos.usado_em`,
set inside the settling transaction with `and usado_em is null` in the UPDATE
itself, so the check and the mark are one atomic step — and a Ko-fi retry
already stopped at the message id. What was missing was the constraint on
the other side. No path writes a second credit today, but the manual queue
resolver (§10.4) does not exist yet, and the obvious way to write it —
*credit this queued payment* — doubles on a second click. The defence cannot
be the care of whoever writes that view.

If a payment ever has to pay for more than one act, that constraint is what
gets rethought. It is not to be worked around with a second credit row.

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

### 4.3 The guide

The guide is always on and cannot be turned off. It draws the signature
under the field, to be traced over, and it is what carries the person
from one `ponto` to the next. There is no toggle and no way to pick a
different one.

A field with no guide is a black sheet, and a black sheet teaches nobody
to trace. Tracing from memory belongs to the `trabalho`, later — not to
the way in.

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

**1 coffee = 2 USD**

| Act | Coffees | USD |
|---|---|---|
| Candle, 20 min | 1 | 2 |
| Drink or smoke `oferenda` | 1 | 2 |
| Full `trabalho` | 3 | 6 |
| Seven-day candle | 3 | 6 |
| `assentamento` firmeza | 7 | 14 |
| `sacrificio` | 7 | 14 |

The currency went SEK -> EUR -> USD, and USD is the one that holds:
**Ko-fi charges in USD, so the number on the button is the number at
checkout.** The app being in Portuguese does not change that — showing
R$ or € beside a dollar charge would read as a bait.

The currency lives in one place in the client:
`AssentamentoScreen.POR_CAFE` and `MOEDA`. Changing it is two lines.

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

**Checked, 2026-09-08, against the four example payloads Ko-fi publishes**
(tip, first monthly, membership tier, shop order), held in
`server/functions/kofi_webhook/payloads/` and read by the proof suite.
Every field name and type the parser assumes holds. `amount` is a string,
not a number. Three findings, and the third was a bug:

- **A shop order carries `message: null`.** There is nowhere to paste a
  code in a shop purchase, so for the SKU rail the only route is SKU for
  the act plus payer email for the person. That is the cascade above, and
  it is why an email alone still had to be worth gathering.
- **`shipping` is a full postal address**, and there are `discord_username`
  and `discord_userid` besides. All of it lands in `pagamentos.raw`. That
  is why `pagamentos` has no RLS policy at all: not tidiness, GDPR (§2,
  operator in Sweden). Never expose that row to a client, not even to the
  person who paid.
- **`shop_items` entries carry `quantity`**, which was not known and was
  not read. `quantity: 5` of one item is five acts; the parser was
  returning the SKU and would have credited **one** — silently giving less
  than was paid for. It now requires a single item of a single unit;
  anything else goes to the manual queue, since one payment may produce at
  most one credit (§3.3).

Still open: these are documentation examples, not a payload observed from
a real payment on the live account. The published examples and the test
button can both differ from production.

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

**Correction, found while building it.** That queue is not a queue,
because its steps do not answer the same question. Crediting needs two:
*whose payment is this*, and *what act does it pay for*.

- The code answers both. The app issued it and knows who for and what for.
- A **shop SKU answers only the what.** An item does not know who bought it.
- A **payer email answers only the who.** The amount cannot pick the act:
  two acts cost 1 coffee, two cost 3, two cost 7 (§10.1).

So the implementation gathers what each step knows and credits only when
both answers exist. An email alone yields a person and no act, and that is
not a credit — it is a queue entry with the person already identified,
which is most of the work done for whoever resolves it. Inferring the act
from the amount would have been exactly the guess §10.4 forbids.

`server/functions/_shared/cascata.ts`, proved in `cascata_test.ts`.

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
