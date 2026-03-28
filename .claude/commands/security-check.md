Run a full security audit of the project and report findings.

Execute these checks in order:

1. **Secret scan** — run `gitleaks detect --no-banner` and report any leaked secrets found
2. **Dependency audit** — run `npm audit --audit-level=moderate` and list any moderate/high/critical vulnerabilities with their package name and fix command
3. **Env discipline check** — verify no `.env*` files are tracked in git (`git ls-files | grep -E '\.env'`)
4. **NEXT*PUBLIC* check** — scan source files for any `NEXT_PUBLIC_OPENAI` or `NEXT_PUBLIC_SUPABASE_SERVICE` patterns that would expose secret keys (`grep -r "NEXT_PUBLIC_OPENAI\|NEXT_PUBLIC_SUPABASE_SERVICE" src/ app/ lib/ 2>/dev/null`)
5. **Service role key check** — scan client-side files for the service role key variable name used directly (`grep -r "SUPABASE_SERVICE_ROLE_KEY" app/ components/ lib/supabase/client* 2>/dev/null`)

Summarise with a pass/fail table. For any failure, explain the risk and the exact fix command.
