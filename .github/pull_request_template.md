# What changed

<!-- Brief description of the change -->

## Why

<!-- Motivation: which build phase / feature / bug does this address? -->

## Test plan

- [ ] `pnpm test` passes
- [ ] `npx tsc --noEmit` passes
- [ ] `npx eslint .` passes
- [ ] Manual test: <!-- describe what you clicked/tested -->

## Security checklist

- [ ] No secrets or API keys committed
- [ ] No `NEXT_PUBLIC_` prefix on server-only vars
- [ ] New API routes call `supabase.auth.getUser()` before data access
- [ ] No `dangerouslySetInnerHTML` introduced
- [ ] CSV parsing stays server-side only

## Build phase

<!-- e.g. Phase 3 — Supabase setup -->
