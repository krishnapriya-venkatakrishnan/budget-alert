Run the pre-deployment checklist before merging to main or deploying to Vercel.

Work through each item and mark pass/fail:

**Code quality**

- [ ] `npx tsc --noEmit` — zero TypeScript errors
- [ ] `npx eslint .` — zero lint errors
- [ ] `pnpm test` — all tests pass
- [ ] `pnpm build` — production build succeeds (no build errors)

**Security**

- [ ] `gitleaks detect` — no secrets in git history
- [ ] `npm audit --audit-level=high` — no high/critical vulnerabilities
- [ ] No `.env*` files in git: `git ls-files | grep -E '\.env'` returns nothing
- [ ] `SUPABASE_SERVICE_ROLE_KEY` not referenced in any client-side file
- [ ] `OPENAI_API_KEY` not prefixed with `NEXT_PUBLIC_`

**Supabase**

- [ ] RLS enabled on `profiles`, `transactions`, `budgets` tables (check via Supabase dashboard or MCP query)
- [ ] No open policies (policies must filter by `auth.uid()`)

**Vercel env vars** — confirm these are set in Vercel dashboard (do not print values):

- [ ] `NEXT_PUBLIC_SUPABASE_URL`
- [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] `SUPABASE_SERVICE_ROLE_KEY`
- [ ] `OPENAI_API_KEY`
- [ ] `RESEND_API_KEY`
- [ ] `RESEND_FROM_EMAIL`

Print a final summary. If any item fails, block deployment and explain what to fix first.
