# Barco release follow-up — 2026-09-09

## Current candidate

- Latest itch.io HTML5 archive: `build/barco-itch-layout.zip`
- SHA-256: `915e99d88fb73fe16c64c2adbe2a51920d5fd9d7c98957619868b3c3d9329605`
- It contains `index.html` at the archive root and passed ZIP integrity.
- The latest layout build has not yet been uploaded to itch.io.
- The preceding checkout candidate was tested by the operator on the restricted itch.io page, and clipboard copying worked.

## Work that can be completed without a real supporter

1. Upload `build/barco-itch-layout.zip` to the unpublished/restricted itch.io page.
2. Check desktop, narrow/mobile and iframe behavior:
   - ten oferendas appear as five items in each side column;
   - spacing is readable;
   - each short-screen side list scrolls normally;
   - vertical touch scrolling does not drag an oferenda or open checkout;
   - checkout has only the combined “copiar código e abrir o Ko-fi” button;
   - clipboard fallback still works.
3. Confirm the webhook URL on Ko-fi's Webhooks page points to the hosted `kofi_webhook`.
4. Make the hosted `KOFI_VERIFICATION_TOKEN` match Ko-fi's verification token. Supabase exposes the secret name but not its value; reset the hosted secret from the Ko-fi value to guarantee the match. Never record the token in repository files or this memory.
5. Use Ko-fi's Webhooks-page test-payment feature:
   - sign in to Barco with a dedicated test email;
   - prepare a basket and generate a recoverable purchase code;
   - send a one-time test payment with the exact USD total and paste that code in the Ko-fi message field;
   - verify webhook HTTP 200, received status, named credits, deposito creation and persistence after browser reload.
   This verifies most hosted plumbing but does not replace a real payment-provider transaction.
6. Exercise idempotence:
   - replay the same webhook delivery with the same Ko-fi `message_id` and confirm it does not credit twice;
   - replay the same deposito operation UUID and confirm it does not spend twice.
7. Inspect the two existing unresolved historical payment records in the reconciliation queue. Do not resolve, restore or credit them by guessing.
8. Implement the missing manual reconciliation admin interface. The backend queue exists; the convenient admin review screen does not.

## Already completed

- Hosted database is at migrations 07000 then 08000; no reset was performed.
- Email auth, manual identity linking, Gmail SMTP, and numeric-token templates are configured.
- Operator received an OTP and confirmed fresh-browser login.
- Hosted `kofi_webhook` version 3 is ACTIVE with `verify_jwt=false`; the function verifies Ko-fi's token.
- All 30 webhook TypeScript tests passed.
- SQL regression suite passed against disposable Postgres 16.
- Latest layout tests passed at 1440x900, 1000x560 and 720x1000.
- Godot Web export, fundamento integrity (55 pieces), diff checks and archive checks passed.

## Still required before calling the build release-ready

A different person must eventually complete one real exact-amount Ko-fi payment. Verify payment-provider charge, Ko-fi webhook delivery, correct named credits, received status, deposito, browser reload, and duplicate-delivery/deposito protection. The tester may be anywhere; they do not need to be local to Sweden.

Keep the itch.io page restricted until the hosted iframe checks and real-payment round trip are complete.
