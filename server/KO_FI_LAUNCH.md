# Ko-fi / itch.io candidate — 2026-09-08

The latest candidate ZIP is build/barco-itch-layout.zip. It contains
index.html at the archive root. Earlier candidate archives are retained.
The operator uploaded the checkout candidate and confirmed copying works.
The latest layout ZIP has not been uploaded.

## Oferendas layout correction — 2026-09-09

- Removed the redundant copy-only checkout button. The combined copy-and-open
  button remains, with the existing browser fallback when copying is denied.
- Moved the ten oferendas into two side columns, with five on each side,
  larger spacing and separate name/price lines. The footer holds the hint,
  comprar and the free pedido action.
- Removed the checkout scroll container's cyclic height calculation; payment
  refresh preserves the scroll position. Short screens scroll each side list.
- Vertical touch scrolling does not start an oferenda drag or open checkout;
  releasing the mouse wheel cannot drop a held oferenda.
- Layout scene checks passed at 1440x900, 1000x560 and 720x1000, using an
  isolated temporary project with conta_layout_falsa as the Conta autoload.
  Native screenshots were inspected. Previews are in build/previews/:
  assentamento-layout.png and assentamento-layout-portrait.png.
- Fundamento integrity (55 pieces), diff checks, Web release export and ZIP
  integrity passed. Export emitted sandbox editor socket warnings.
- The latest layout still needs a hosted iframe check. No real purchase or
  paid-credit recovery was verified by these layout tests.

Latest ZIP SHA-256:
915e99d88fb73fe16c64c2adbe2a51920d5fd9d7c98957619868b3c3d9329605

## Clipboard correction — 2026-09-09

- Replaced the unchecked Web clipboard call with a browser helper that reports
  copy success or failure. Payment polling has its own status label and does
  not overwrite copy feedback.
- The main button copies the code and opens Ko-fi. The copy-only button was
  subsequently removed in the layout correction above.
- If automatic copy is refused, a native browser dialog provides selectable
  text, a retry button and an explicit manual-copy link to Ko-fi. A blocked
  popup also leaves a direct link. No failed copy is reported as successful.
- Closing checkout, changing the basket, changing accounts or receiving the
  payment cancels pending UI callbacks and removes the fallback dialog.
- Passed tools/prova_clipboard.cjs in headless Chrome: actual copy/paste in
  a cross-origin sandboxed iframe with clipboard Permissions Policy disabled;
  forced clipboard denial; manual link; blocked popup; cancellation; fallback
  width at a 390px viewport. No payment requests are made by these tests.
- A separate temporary Godot Web fixture confirmed the real Godot button ->
  JavaScript helper -> GDScript callback chain inside a restricted iframe.
- Checkout availability scene tests passed; fundamento remains intact (55
  pieces). Web release export and ZIP integrity passed. Editor socket warnings
  occurred in the sandbox; export completed successfully.
- The operator subsequently confirmed copying works on the itch.io candidate.
  A full hosted purchase test remains outstanding.
- Ko-fi still requires manual entry of the exact total and pasting the code.
  No documented prefill mechanism for both was established, so no speculative
  URL parameters or automatic payment matching were introduced.

Earlier checkout ZIP SHA-256:
f6253e68a8709a808c4550147a85f936c06ebc13ef58872a22729d1e94cc1c7a

## Implemented locally

- Exact USD settlement, single-use codes, duplicate message protection.
- Code copying, server-confirmed total, payment polling, pending-code lookup.
- Email OTP sign-in and anonymous-account linking. Web checkout requires a
  verified email both in the client and pedir_codigo_recuperavel.
- Credit consumption and append-only deposito creation in one transaction,
  keyed by an operation UUID. Repeating an operation cannot spend twice.
- The client saves the pending operation before sending, retries it after a
  lost response, and reloads depositos from Supabase on sign-in.
- Session refresh failure retains the existing identity and refresh token.

The verified-account form appears only at checkout. Payments remain optional:
people buy the named oferendas they select. No subscriptions or soft currency.

## Before updating itch.io

1. DONE: `docker info` and `bash server/prova/correr.sh` succeeded with
   approved access outside the sandbox. Socket permissions were not changed.
2. DONE: inspected BARCO's hosted migration history and schema markers at
   06000; applied 07000_validar_pagamento followed by
   08000_compras_recuperaveis. Read back the history: both are recorded.
   No database reset, seed, or historical payment adjustment was performed.
3. Email signup is enabled. Manual identity linking was enabled on the
   hosted project and the configuration read back without declared differences.
   2026-09-09: operator saved Gmail custom SMTP. Hosted configuration confirms
   enabled=true, smtp.gmail.com:587, sender name Barco, and matching sender
   and SMTP username. Operator subsequently confirmed code delivery to Proton.
   Local config.toml changes do not configure the hosted project.
4. DONE 2026-09-09: applied Magic Link, Confirm Signup, and Change Email
   templates containing the numeric `{{ .Token }}` from
   server/templates/email_codigo.html. The app verifies codes directly,
   so the player does not need a redirect into the itch.io iframe.
   The earlier default-provider HTTP 400 blocker is resolved. A subsequent
   hosted comparison reported Auth up to date, with no changes required.
   SMTP credentials and unrelated hosted settings were preserved.
5. Verify login with a real email, then close/clear a separate test browser
   and log in again with that email. Check the user ID and purchased credits.
   2026-09-09: operator confirmed the candidate shows the same email session
   in the original and incognito browsers after fresh OTP login. This is a
   user-observed login check; matching user IDs and purchased-credit recovery
   have not yet been independently verified. The restricted itch.io page
   password grants page access only; it is separate from Barco authentication.
6. Confirm Ko-fi's one-time payment page charges USD at $2 per coffee, and
   the hosted kofi_webhook has the correct KOFI_VERIFICATION_TOKEN.
   Keep verify_jwt=false: the function checks the Ko-fi token.
   Observed: deployed kofi_webhook version 3 has verify_jwt=false, and the
   secret name KOFI_VERIFICATION_TOKEN exists. Its match with Ko-fi is not
   verified. On 2026-09-09, all 30 TypeScript tests passed in a disposable
   Deno container, then the candidate webhook was deployed. Hosted function
   listing confirms version 3 is ACTIVE. No real purchase has been verified.
7. Verify a real exact-amount purchase using a code from this build, including
   webhook 200, named credits, received status, deposition and browser reload.
   Replay the delivery and the deposit operation: neither may credit/spend twice.
8. Upload the candidate ZIP as the itch.io HTML5 build after these checks.
   Use an unpublished/restricted test page first to verify browser behavior.

Official references:
- https://supabase.com/docs/guides/auth/auth-email-passwordless
- https://supabase.com/docs/guides/auth/auth-anonymous
- https://supabase.com/docs/guides/auth/auth-smtp
- https://itch.io/docs/creators/html5

## Evidence and limits

Passed locally: mocked auth recovery tests, purchase availability scene tests,
Godot Web release export, fundamento integrity, shell syntax and diff checks.
The export emitted editor socket/settings permission warnings in this restricted
session. The latest layout was inspected in native renders; local browser
clipboard/bridge tests also passed. Full hosted layout testing remains pending.

SQL regression tests now PASS against disposable Postgres 16, including
RLS, exact payment validation, duplicate settlement, recoverable checkout,
deposito retry and failed-gesture rollback. The first run exposed a PL/pgSQL
CASE-expression syntax error in validar_pagamento.sql; the test was corrected
and the entire suite rerun successfully. Output: /tmp/barco-sql-regression.log
(temporary evidence, not a durable repository artifact).

Hosted BARCO (awlwysjbgiijfnceieog, EU Central) is now at migration 08000.
Before applying, aggregate inspection found two payments, both unresolved in
reconciliacao, and zero historical used codes. No payment payloads were read,
and neither payment was credited or resolved by this work.

SMTP configuration and all three code templates are verified as saved;
SMTP delivery and fresh-browser OTP login were confirmed by the operator.
Purchased-credit recovery and the Ko-fi round trip remain unverified. The
browser connector currently fails with ECONNREFUSED at 127.0.0.1:80.
Hosted migrations, manual linking and webhook version 3 were deployed.
The operator reports the candidate is uploaded on restricted itch.io; no
itch.io upload was performed by the agent.

The earlier candidate ZIP passed archive integrity checking and contains
index.html at its root. SHA-256:
0298404a5760a53003272652d0bb2c18c1900b4ea2ce6fd66f8b7c8189b6fd3f
It is superseded by the layout ZIP documented above.

## Remaining limits

- The manual reconciliation admin interface remains to be implemented.
- Historical used codes without a confirmed linked payment show review status.
  Inspect them before rollout; do not silently restore or credit them.
- Existing local-only depositos have no server credit linkage and remain local;
  this change does not invent payment records for those earlier gestures.
- Ritual progress and pedido text remain local. Only purchased credits and new
  paid depositos are recovered by this change; it is not whole-account save sync.
- Test mobile/iframe layout and clipboard/browser restrictions on the hosted
  test page before describing the candidate as release-ready.
