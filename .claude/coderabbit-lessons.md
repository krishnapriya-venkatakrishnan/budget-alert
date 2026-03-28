# CodeRabbit Review Lessons

Findings raised in PR #7 (feat/scaffold-nextjs) and how they were resolved.
Apply these patterns upfront in future PRs to avoid repeat flags.

---

## 1. Dependabot — scope major-version ignores per package

**Finding:** Blanket `dependency-name: "*"` ignore suppresses all major-version PRs.
**Fix:** Use per-package ignore entries for libraries where major bumps are disruptive (next, react, react-dom, @supabase/supabase-js, openai). All other packages get major-version PRs.
**Note:** Security updates always bypass ignore rules regardless.

---

## 2. Markdown — PR template must start with H1

**Finding:** `## What changed` (H2) at line 1 violates markdownlint rule MD041.
**Fix:** First heading in any markdown file must be `#` (H1), not `##`.

---

## 3. Shell hooks — always add `set -e`

**Finding:** Pre-commit hook ran tsc then eslint with no fail-fast; a failing tsc still ran eslint.
**Fix:** Add `set -e` immediately after the shebang line in all `.husky/*` scripts.

---

## 4. Audit script — match CI audit level

**Finding:** `package.json` `audit` script used `--audit-level=moderate`; CI used `--audit-level=high`.
**Fix:** Both must use the same level. This project uses `--audit-level=high`.

---

## 5. Package manager — never mix npm and pnpm commands

**Finding:** CI used `npm audit` but the project uses pnpm (no `package-lock.json` exists).
**Fix:** Use `pnpm audit` everywhere — CI, package.json scripts, docs, and skill commands.

---

## 6. ESM — avoid `import.meta.url` in Next.js config

**Finding:** `import.meta.url` in `next.config.ts` caused Next.js to emit ESM syntax in the compiled config, breaking the build with `exports is not defined`.
**Fix:** Use `process.cwd()` instead of `path.resolve(__dirname)` in `next.config.ts`. Never use `import.meta.url` in Next.js config files.

---

## 7. ESM — use `fileURLToPath` in Vite/Vitest configs

**Finding:** `__dirname` is unavailable in native ESM. Vitest injects it internally but that is an implementation detail.
**Fix:** Derive `__dirname` explicitly in `vitest.config.ts` and any Vite config:

```ts
import { fileURLToPath } from "url";
import path from "path";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
```

---

## 8. PR descriptions — fill all template sections

**Finding:** `Why` and `Build phase` sections left empty; `Manual test` lacked detail.
**Fix:** Every PR must have:

- **What changed** — specific list of files/packages added or modified
- **Why** — which build phase and motivation
- **Test plan** — all checkboxes ticked with real manual test description
- **Build phase** — e.g. "Phase 2 — Project scaffold"

---

## 9. Pre-commit scope — do not add slow checks

CodeRabbit suggested adding vitest, pnpm audit, and gitleaks to pre-commit.
**Decision: won't fix.** Pre-commit stays fast (tsc + eslint only, ~5s). Full checks run in CI on every PR. Adding slow checks to pre-commit incentivises `--no-verify` bypasses.
