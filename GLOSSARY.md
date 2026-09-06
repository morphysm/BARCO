# GLOSSARY

Domain vocabulary for **Barco**. These terms are **never translated** — not in
code, not in comments, not in UI copy, not in commit messages.

Identifiers are ASCII: strip accents, keep the word.
`hora_asmodeica`, not `hora_asmodéica`. `sacrificio`, not `sacrifício`.

A translated term is a lost term. If you find yourself writing `shrine` or
`strength`, you have introduced a synonym the codebase will drift on.

---

## Core mechanics

| Term | Identifier | Meaning | Never render as |
|---|---|---|---|
| assentamento | `assentamento` | The persistent space belonging to one entity. Accumulates every offering ever made. It is the save state and the main screen. | shrine, altar, settlement |
| ponto riscado | `ponto_riscado` | The traced sigil. Player input, not decoration. Drawn stroke by stroke with the finger in a required order. | sigil, glyph, symbol, seal |
| selo | `selo` | The mark of a `coroa`. Closed geometry, traced once, permanent, never re-scored. Distinct from `ponto_riscado`. | seal, sigil |
| firmeza | `firmeza` | 0–100. Quality of a traced `ponto`, and separately the standing condition of an `assentamento`. One word, two scopes — keep the word. | strength, firmness, stability, score |
| pemba | `pemba` | The chalk. Also the visual treatment of the trace: white or red, granular. | chalk |
| trabalho | `trabalho` | One complete ritual cycle, from CHAMADO to REGISTRADO. The unit of work and the unit of payment. | working, ritual, session, job |
| oferenda | `oferenda` | A single offering act: pour, light, smoke, deposit. | offering, gift, item |
| caderno | `caderno` | Append-only record of every `trabalho`. Immutable. Exportable. | journal, log, history |
| gira | `gira` | A working session in the physical world, outside the app. Referenced in copy, not modelled in code. | ceremony |
| assinatura | `assinatura` | An entity's whole `ponto_riscado`, as drawn. Signatures never share geometry and are never composed from one another. The app recognises the signature; it never offers a list. | signature, glyph |
| irmandade | `irmandade` | Entities that share identities and behaviours, answer in the same `reino`, and accumulate in one `assentamento`. The unit the app matches a risco against. | brotherhood, group, family |
| fechamento | `fechamento` | Closing a `trabalho`. Always free. | closing, completion |
| permanencia | `permanencia` | The mandatory real-time wait inside a `trabalho`. Minimum 3 minutes. Runs while the app is closed. | dwell, wait, cooldown |
| marafo | `marafo` | Cachaça. The standard `oferenda` drink for Exu. | liquor, spirits, cachaça |

## Cosmology

| Term | Identifier | Meaning | Never render as |
|---|---|---|---|
| coroa | `coroa` | One of the four sovereigns. Regulators, not recipients — they take no `oferenda`. | crown, king, ruler |
| reino | `reino` | One of the seven territories. Each has a landscape, an ambient bed, and a set of entities. | kingdom, realm, region |
| calunga | `calunga` | Two `reinos` carry it: `calunga_pequena` (cemetery) and `calunga_grande` (sea). Never abbreviate to "calunga" alone in code. | graveyard, ocean |
| encruzilhada | `encruzilhada` | Crossroads. A `reino` and a landscape. | crossroads, intersection |
| lodo | `lodo` | The mire. `Reino` of rot and reversal. | mud, swamp |
| hora asmodeica | `hora_asmodeica` | 00:00–04:00 in the user's declared timezone, validated server-side. Second layer of time, overlaid on the calendar. Never announced in the UI. | asmodean hour, witching hour, night mode |
| face | `face` | Which entity of an `irmandade` answered a risco. Not an aspect of one entity: the `irmandade` shares the `assentamento`, and each member signs it differently. | aspect, form, mode, variant |
| face indefinida | `face_indefinida` | A `ponto` traced **whole** that still names no one — the instinctive trace. Outside `hora_asmodeica` it weakens the `trabalho`; inside, it is the strongest risco there is. Distinct from `abandonado`. | undefined, null, failed |
| abandonado | `abandonado` | A `ponto` left unfinished — strokes never traced. Worth nothing, at any hour. Never a `face_indefinida`: one is hesitation carried to the end, the other is giving up. | incomplete, cancelled, failed |

## Entity names

Never translate, never anglicise, never strip honorifics.

`Exu Aranha` · `Rosa Negra` · `Tranca-Ruas das Almas` · `Exu Caveira` ·
`Maria Padilha` · `Maria Molambo` · `Pombagira Cigana` · `Dama da Noite` ·
`Sete Saias` · `Exu Marabô` · `Exu Veludo` · `Exu Capa Preta` · `Maioral`

Slugs strip accents and lowercase with underscores:
`exu_aranha`, `rosa_negra`, `tranca_ruas_das_almas`, `exu_marabo`.

`Exu Caveira` is the king of the cemetery. `Rosa Negra` is the
cemetery-current Pombagira beside him. `Exu Aranha` is the teia that
weaves and has presence in both. The three sign the `irmandade` of
`calunga_pequena`, each with its own `ponto` — the teia is doctrine, not a
shared base.

Crowns: `lucifer`, `belzebu`, `astaroth`, `asmodeu`.
Note the Portuguese forms — `belzebu` not `beelzebub`, `asmodeu` not `asmodeus`.

## Terms that are NOT domain vocabulary

Translate these normally, they carry no ritual weight:
webhook, ledger, timer, endpoint, migration, shader, viewport.
