# Ko-fi / itch.io candidate — 2026-09-09

The current restricted candidate is `build/barco-itch-layout.zip`, SHA-256
`62e0fc9bf09f5a5d279b9b751bbac4f1c2b04de58e17b59d8c858606ca06a37c`.
It contains `index.html` at the archive root, passed ZIP integrity and is the
only playable upload on `https://kadaver-kadaver.itch.io/barco`. Keep that page
restricted until the real-payment check below passes.

## Hosted candidate

- Ten oferendas render as five items in each side column. Desktop, narrow,
  mobile and short/wide layouts were inspected on the restricted itch.io page.
- Short-screen columns scroll. Predominantly vertical touch movement within a
  side column is reserved for scrolling and cannot open checkout.
- Checkout has one action: `copiar código e abrir o Ko-fi`. Its browser
  clipboard fallback passed both local and hosted checks.
- Itch.io's mobile launch uses the full viewport without horizontal overflow.
- The page describes Barco as a browser application. It has no unsupported
  Android claim and no tag that violates the project's scope declaration.
- Fixed USD prices remain visible before Ko-fi opens.

## Hosted payment proof

Ko-fi's Webhooks URL points exactly to the hosted `kofi_webhook`. The hosted
verification secret was reset directly from Ko-fi without recording or
displaying its value. Keep `verify_jwt=false`: this endpoint authenticates the
provider with Ko-fi's verification token.

Ko-fi's built-in Webhooks tests accept only a destination URL and an example
type. They cannot set payer email, exact amount or message text, so they cannot
carry a Barco purchase code or prove an exact basket.

A controlled Ko-fi-shaped, exact-value payload was therefore sent to the live
webhook using a purchase code issued by the hosted app to a dedicated test
identity. The original delivery and an identical `message_id` replay both
returned HTTP 200. The database recorded exactly one payment and one named
credit, consumed the code, matched by code and created no reconciliation row.
The hosted app displayed `pagamento recebido`.

The purchased oferenda was deposited in the hosted app. Replaying the exact
operation UUID returned HTTP 200 again while leaving exactly one spent credit
and one append-only deposito. Reloading the browser restored the deposito.

This proof exposed a Godot Web transport problem: compressed Supabase bodies
could arrive without usable JSON. Payment and deposito `HTTPRequest` nodes now
set `accept_gzip=false`. The uploaded candidate reloads cleanly, clears the
pending operation and reports no gzip or JSON parse failure.

This controlled delivery proves the hosted application path. It does not prove
that Ko-fi charged a real payment method and delivered the resulting webhook.

## Manual reconciliation

Migration `20260909009000_reconciliacao_admin.sql` and Edge Function
`reconciliacao_admin` are deployed. The function accepts only a valid Supabase
bearer token belonging to `administradores`; the browser receives neither the
service key nor the raw provider payload.

An operator can list unresolved rows, find a person by exact email and resolve
a payment with explicitly selected named acts. The database verifies that the
acts' fixed USD prices equal the payment total, then credits and resolves the
row in one transaction. Repeating a completed resolution is idempotent. It
never guesses a person or basket.

Run the operator page locally:

```sh
node server/admin/servir.cjs
```

It binds only to `127.0.0.1:4173`. Sign in with an administrator email and its
OTP, then open `http://127.0.0.1:4173`.

The two historical unresolved rows were inspected only in aggregate. Both
remain unresolved and untouched; no person, code or basket was inferred.

## Verified versions and tests

- Hosted migrations are synchronized through `20260909009000`; no reset was
  performed.
- `kofi_webhook` version 4 and `reconciliacao_admin` version 3 are ACTIVE.
- All 30 Deno webhook tests passed.
- The complete migration, RLS, exact-payment, deposito and reconciliation SQL
  suite passed against disposable Postgres 16.
- Browser tests for reconciliation and clipboard passed.
- Layout checks passed at 1440x900, 1000x560 and 720x1000, followed by hosted
  desktop/mobile/iframe inspection and a hosted touch replay.
- Fundamento integrity passed with 55 pieces. JavaScript syntax, archive
  integrity and diff checks passed.

## Remaining release check

A different person must make one real, exact-amount Ko-fi payment with a code
from this build in the message. Confirm the provider charge, webhook HTTP 200,
`pagamento recebido`, correct named credits, deposito, browser reload and safe
replays of the delivery and deposito operation. The tester can be outside
Sweden; the creator cannot pay their own Ko-fi page.

Official references:

- https://supabase.com/docs/guides/auth/auth-email-passwordless
- https://supabase.com/docs/guides/auth/auth-anonymous
- https://supabase.com/docs/guides/auth/auth-smtp
- https://itch.io/docs/creators/html5
