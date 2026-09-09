# Barco release follow-up — 2026-09-09

## Current candidate

- Restricted itch.io page: `https://kadaver-kadaver.itch.io/barco`
- Playable archive: `build/barco-itch-layout.zip`
- SHA-256: `62e0fc9bf09f5a5d279b9b751bbac4f1c2b04de58e17b59d8c858606ca06a37c`
- The archive contains `index.html` at its root and passed ZIP integrity.
- The page remains restricted. The current archive is its only playable upload.

## Completed without a real supporter

1. Uploaded the current archive to the restricted itch.io page.
2. Checked the hosted build at desktop, narrow/mobile and short/wide sizes:
   - ten oferendas appear as five items in each side column;
   - spacing and labels remain readable;
   - short-screen side lists scroll;
   - vertical touch movement is reserved for scrolling and does not open checkout;
   - checkout has only `copiar código e abrir o Ko-fi`;
   - the restricted iframe and mobile full-viewport launch have no horizontal overflow.
3. Removed the forbidden itch.io tag and the unsupported Android claim. The page describes Barco as a browser application and keeps fixed USD pricing.
4. Confirmed Ko-fi's Webhooks URL points exactly to the hosted `kofi_webhook`. Reset the hosted `KOFI_VERIFICATION_TOKEN` directly from Ko-fi without writing or displaying it.
5. Established that Ko-fi's built-in Webhooks tests cannot set the payer email, exact amount, or message text. They therefore cannot carry a Barco code or prove an exact basket.
6. Ran a controlled exact-value round trip against the hosted webhook with a dedicated authenticated test identity and a one-item USD basket:
   - first delivery returned HTTP 200;
   - the identical `message_id` replay returned HTTP 200;
   - exactly one payment and one named credit were created;
   - the purchase code was consumed and matched by code;
   - no reconciliation row was created;
   - Barco showed `pagamento recebido`.
7. Deposited that purchased oferenda in the hosted app, then replayed the identical operation UUID:
   - both requests returned HTTP 200;
   - exactly one credit was spent;
   - exactly one append-only deposito was created;
   - browser reload restored the deposito without another spend.
8. Fixed a hosted-only response problem discovered by that proof. Godot's HTTP client could not decode the compressed Supabase response, so payment and deposito requests now disable gzip. The current hosted build reloads without JSON parse errors or false pending-operation warnings.
9. Inspected the two historical unresolved payment rows only in aggregate. Both remain unresolved and untouched; nothing was credited or inferred.
10. Implemented and deployed the manual reconciliation admin path:
    - authenticated access is limited to `administradores`;
    - the local operator page binds only to `127.0.0.1`;
    - resolution accepts an explicit person and named acts whose exact USD total matches the payment;
    - resolution, credits and queue state change occur in one idempotent transaction;
    - the browser does not receive the service key or raw payment payload.

## Hosted state

- Database migrations are synchronized through `20260909009000_reconciliacao_admin.sql`; no reset was performed.
- `kofi_webhook` version 4 is ACTIVE with `verify_jwt=false`; it validates Ko-fi's token itself.
- `reconciliacao_admin` version 3 is ACTIVE with `verify_jwt=false`; it validates the Supabase bearer token and administrator membership itself.
- Aggregate controlled-test state: three payments, one credited payment, one credit spent, one deposito, two unresolved historical reconciliation rows, and one administrator.
- The two historical reconciliation rows are still the same unresolved Donation and Shop Order examples.

## Verification

- 30 Deno webhook tests passed.
- The complete migration, RLS, payment, deposito and reconciliation suite passed against disposable Postgres 16.
- The reconciliation admin browser test and clipboard browser test passed.
- Layout regression passed at 1440x900, 1000x560 and 720x1000.
- Hosted desktop/mobile/iframe inspection and a hosted vertical-touch replay passed.
- Fundamento integrity passed with 55 pieces.
- JavaScript syntax, archive integrity and diff checks passed.

## Only remaining release check

A different person must complete one real exact-amount Ko-fi payment with a code from the current build in the message. Verify the provider charge, webhook HTTP 200, received status, correct named credits, deposito, browser reload, and duplicate delivery/deposito protection. The controlled hosted payload proves the application path but does not replace a real transaction through Ko-fi.

Keep the itch.io page restricted until that real-payment round trip passes.

## Worktree handoff

The reconciliation implementation, hosted-response fix, touch correction, tests and documentation are uncommitted. Review the diff before committing and pushing.
