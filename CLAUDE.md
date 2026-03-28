# Personal Finance Dashboard — Claude Context

## What This Project Is

A fullstack web app where users upload bank transaction CSVs, get AI-powered spending categorisation, visualise financial health over time, and receive email alerts when budget limits are crossed.

Built by a solo developer with 6 years of banking software experience. Goal: live deployed URL + polished README on resume by day 31 (target: 2026-04-28).

---

## Stack

| Layer            | Tool                                                      |
| ---------------- | --------------------------------------------------------- |
| Frontend         | Next.js 14, TypeScript, Tailwind CSS, shadcn/ui, Recharts |
| Forms/Validation | React Hook Form, Zod                                      |
| File Handling    | react-dropzone, papaparse (server-side only)              |
| Backend          | Next.js API routes (App Router)                           |
| Database         | Supabase PostgreSQL                                       |
| Auth             | Supabase Auth (email + Google OAuth)                      |
| Storage          | Supabase Storage                                          |
| Edge Functions   | Supabase Edge Functions (Deno)                            |
| AI               | OpenAI GPT-4o-mini                                        |
| Email            | Resend                                                    |
| Deploy           | Vercel                                                    |
| Package Manager  | pnpm                                                      |
| Runtime          | Node.js 20 LTS                                            |

---

## Folder Structure (when scaffolded)

```
app/
  (auth)/           # login, signup, callback — public
  (dashboard)/      # all protected pages
    layout.tsx      # sidebar + nav, auth-gated
    page.tsx        # main dashboard with charts
    transactions/
    budgets/
  api/              # all API route handlers
components/
  ui/               # shadcn/ui primitives
  charts/           # Recharts wrappers
  transactions/     # upload, table, review UI
  budgets/          # budget form, progress bars
lib/
  supabase/         # client + server Supabase instances
  openai.ts         # OpenAI client + categorise fn
  csv.ts            # papaparse + column normaliser
  types.ts          # shared TypeScript types
  utils.ts          # date helpers, formatters
```

---

## Database Schema

### profiles

```sql
CREATE TABLE profiles (
  id             uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  monthly_income numeric(12,2),
  currency       text DEFAULT 'SEK',
  created_at     timestamptz DEFAULT now()
);
```

Created automatically via trigger on auth.users insert.

### transactions

```sql
CREATE TABLE transactions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date           date NOT NULL,
  description    text NOT NULL,
  amount         numeric(12,2) NOT NULL,
  type           text CHECK (type IN ('debit','credit')) NOT NULL,
  category       text,           -- user-confirmed
  ai_category    text,           -- AI-suggested
  ai_confidence  numeric(3,2),   -- 0.00 to 1.00
  is_reviewed    boolean DEFAULT false,
  import_hash    text UNIQUE,    -- MD5 for deduplication
  created_at     timestamptz DEFAULT now()
);
CREATE INDEX idx_transactions_user_date ON transactions(user_id, date DESC);
```

### budgets

```sql
CREATE TABLE budgets (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category       text NOT NULL,
  monthly_limit  numeric(12,2) NOT NULL,
  alert_sent     boolean DEFAULT false,
  created_at     timestamptz DEFAULT now(),
  UNIQUE(user_id, category)
);
```

### Row Level Security

RLS is enabled on all three tables. Users can only access their own rows. The service role key (used only in Edge Functions) bypasses RLS — it must never appear in client-side code.

---

## API Routes

| Endpoint                  | Method | Purpose                               |
| ------------------------- | ------ | ------------------------------------- |
| /api/auth/callback        | GET    | OAuth redirect handler                |
| /api/auth/signout         | POST   | Clear session                         |
| /api/transactions/upload  | POST   | Parse CSV, deduplicate, AI categorise |
| /api/transactions         | GET    | Paginated list with filters           |
| /api/transactions/[id]    | PATCH  | Manual category override              |
| /api/transactions/[id]    | DELETE | Delete transaction                    |
| /api/transactions/export  | GET    | Export filtered CSV                   |
| /api/transactions/summary | GET    | Aggregated category totals for charts |
| /api/budgets              | GET    | All budgets for current user          |
| /api/budgets              | POST   | Create/upsert budget limit            |
| /api/budgets/[id]         | DELETE | Remove budget limit                   |
| /api/budgets/status       | GET    | Spend vs limit per category           |

All routes return `{ data, error }`. Every route calls `supabase.auth.getUser()` first — returns 401 if session invalid.

---

## AI Categorisation

Categories: Food & Drink, Transport, Utilities, Entertainment, Health, Shopping, Housing, Income, Savings, Other

Batched at 20 transactions per OpenAI call. Returns `{ id, category, confidence }` per transaction.

Confidence thresholds:

- `0.85–1.00` → auto-accepted, `is_reviewed = true`
- `0.70–0.84` → accepted, flagged as "Review suggested"
- `0.00–0.69` → mandatory review, `category` left null

---

## Environment Variables

| Variable                        | Used Where                                  |
| ------------------------------- | ------------------------------------------- |
| `NEXT_PUBLIC_SUPABASE_URL`      | Client + Server (safe to expose)            |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Client + Server (safe, RLS enforced)        |
| `SUPABASE_SERVICE_ROLE_KEY`     | Server / Edge Functions ONLY — bypasses RLS |
| `OPENAI_API_KEY`                | Server ONLY — never in client code          |
| `RESEND_API_KEY`                | Edge Function ONLY                          |
| `RESEND_FROM_EMAIL`             | Edge Function ONLY                          |

---

## Security Rules (Non-Negotiable)

- `SUPABASE_SERVICE_ROLE_KEY` never in any file importable by client code
- `OPENAI_API_KEY` server-side only — never `NEXT_PUBLIC_` prefixed
- No `dangerouslySetInnerHTML` anywhere
- CSV parsed server-side only — never eval'd in browser
- File upload: MIME type + extension validation, 5MB max
- Every API route validates session before any data access
- `.env.local` in `.gitignore` — never committed

---

## CI/CD Pipeline (GitHub Actions)

Every push triggers:

1. `tsc --noEmit` — TypeScript check
2. `eslint .` — lint
3. `vitest run` — unit + integration tests
4. `pnpm audit` — dependency security
5. `gitleaks detect` — secret scan
6. `next build` — production build check

PRs get a Vercel preview URL. Merge to `main` auto-deploys to production.

---

## Key Commands

```bash
pnpm dev            # local dev server
pnpm build          # production build
pnpm test           # Vitest unit tests
pnpm test:e2e       # Playwright E2E tests
npx tsc --noEmit    # type check
npx eslint .        # lint
gitleaks detect     # scan for leaked secrets
pnpm audit          # check dependency vulnerabilities
```

---

## Commit Convention

```
feat(auth): add Google OAuth login
feat(csv): add papaparse CSV upload and preview
feat(ai): add GPT-4o-mini batch categorisation endpoint
fix(parser): handle empty description column
test(csv): add edge case tests for duplicate detection
docs(readme): add architecture diagram
```

---

## Build Phases (Step-by-Step Guide in Progress)

1. Local environment setup — Node 20, pnpm, VS Code extensions, git config
2. Project scaffold — Next.js + TypeScript, ESLint, Prettier, Husky + commitlint
3. Supabase setup — project, schema SQL, RLS, Auth config
4. GitHub + security baseline — repo init, .gitignore, gitleaks, env discipline
5. GitHub Actions CI pipeline
6. Vercel deployment — project link, env vars, preview-per-PR
7. Feature builds — auth → CSV upload → AI categorisation → charts → budgets/alerts
8. Monitoring — Sentry + Vercel Analytics
9. Ship checklist — security review, README, demo video

---

## Claude Code Configuration

This project has full Claude Code tooling configured. All of it is in `.claude/` and `.mcp.json`.

### Active Hooks

| Hook                         | Trigger                 | What it does                                        |
| ---------------------------- | ----------------------- | --------------------------------------------------- |
| `protect-sensitive-files.sh` | PreToolUse Write\|Edit  | Blocks writes to `.env*` files and JWT content      |
| `format-on-save.sh`          | PostToolUse Write\|Edit | Auto-runs Prettier (async, non-blocking)            |
| Bash logger                  | PostToolUse Bash        | Logs every command to `.claude/bash-history.log`    |
| Context re-injection         | SessionStart compact    | Re-injects project summary after context compaction |
| macOS notification           | Notification            | Desktop alert when Claude needs input               |

### Active MCPs (defined in `.mcp.json`)

| MCP                   | Env var required               | What it gives                           |
| --------------------- | ------------------------------ | --------------------------------------- |
| `github`              | `GITHUB_PERSONAL_ACCESS_TOKEN` | Issues, PRs, repo management            |
| `supabase` (postgres) | `SUPABASE_DB_URL`              | Direct SQL query access                 |
| `playwright`          | None                           | Real browser automation for E2E testing |

### Models

- **Daily coding / code review:** `claude-sonnet-4-6` (default)
- **Complex architecture / debugging:** `claude-opus-4-6` (use `/model` to switch)
- **AI categorisation feature (if using Claude instead of OpenAI):** `claude-haiku-4-5-20251001`

### Useful slash commands

**Built-in**

- `/hooks` — verify hooks are loaded
- `/mcp` — check MCP server status
- `/model` — switch model for this session
- `/config` — view/edit permissions

**Project skills** (`.claude/commands/`)

- `/commit` — stage and commit following project convention (feat/fix/test scopes)
- `/test` — run tsc + eslint + vitest and print pass/fail summary
- `/e2e` — run Playwright E2E tests and summarise results (pass file path to run single suite)
- `/security-check` — run gitleaks + npm audit + env discipline checks
- `/pr` — create a GitHub PR with standard template via GitHub MCP
- `/deploy-check` — full pre-deployment checklist (code, security, Supabase RLS, Vercel env vars)

### CodeRabbit (`.coderabbit.yaml`)

AI PR reviewer — automatically reviews every PR on GitHub. Configured to flag:

- Missing `supabase.auth.getUser()` in API routes
- `NEXT_PUBLIC_` prefixed secret keys
- `dangerouslySetInnerHTML` usage
- Service role key in client-side files
- CSV parsing imported into client components
- Mocked Supabase in integration tests
- Hardcoded secrets in GitHub Actions

No setup needed beyond installing the CodeRabbit GitHub App on the repo.

---

## Source Documents

- `ai.docs/finance_dashboard_plan.docx` — full project plan, week-by-week schedule
- `ai.docs/finance_dashboard_TDD.docx` — technical design document with API contracts
- `ai.docs/claude-anthropic-guide.md` — complete guide to Claude Code setup for this project (hooks, MCPs, settings, models)
