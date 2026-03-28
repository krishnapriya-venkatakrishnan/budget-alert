# Infrastructure Setup

Documents all external service configuration for the Personal Finance Dashboard project.

---

## GitHub

**Repository:** `krishnapriya-venkatakrishnan/budget-alert`

### Secrets (Settings → Secrets and variables → Actions)

| Secret                          | Purpose                                                     |
| ------------------------------- | ----------------------------------------------------------- |
| `NEXT_PUBLIC_SUPABASE_URL`      | Supabase project URL — used in CI vitest and build steps    |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key — used in CI vitest and build steps       |
| `GITLEAKS_LICENSE`              | Gitleaks org-level scan license (optional for public repos) |

### Dependabot

Configured in `.github/dependabot.yml`:

- Weekly updates for npm and GitHub Actions ecosystems
- Major-version updates suppressed per-package for: `next`, `react`, `react-dom`, `@supabase/supabase-js`, `openai`
- Security updates always bypass ignore rules

### CI Pipeline

Runs on every PR to `main` via `.github/workflows/ci.yml`:

1. TypeScript check (`tsc --noEmit`)
2. ESLint (`eslint . --max-warnings 0`)
3. Unit tests (`pnpm test`)
4. Dependency audit (`pnpm audit --audit-level=high`)
5. Secret scan (gitleaks)
6. Production build (`next build`)

---

## Supabase

### Database Tables

Three tables created in the `public` schema:

- **profiles** — one row per user, linked to `auth.users`, stores `monthly_income` and `currency`
- **transactions** — user transactions with AI categorisation fields and deduplication hash
- **budgets** — per-category monthly spend limits with alert tracking

RLS is enabled on all three tables. Users can only read/write their own rows.

### Auth Trigger

Function `public.handle_new_user()` runs `AFTER INSERT ON auth.users` and automatically creates a `profiles` row for every new signup.

### Authentication

**Providers enabled:**

- Email (default)
- Google OAuth — configured with Google Cloud Console client ID and secret

**URL Configuration:**

- Site URL: `https://<vercel-production-url>`
- Redirect URLs:
  - `http://localhost:3000/api/auth/callback`
  - `https://<vercel-production-url>/api/auth/callback`

---

## Google Cloud Console

**Project:** budget-alert (or equivalent)

**OAuth 2.0 Client (Web application):**

| Setting                       | Value                                                                                                    |
| ----------------------------- | -------------------------------------------------------------------------------------------------------- |
| Consent screen audience       | External                                                                                                 |
| Scopes                        | `email`, `profile`                                                                                       |
| Authorized JavaScript origins | `https://<supabase-project-ref>.supabase.co`, `http://localhost:3000`, `https://<vercel-production-url>` |
| Authorized redirect URIs      | `https://<supabase-project-ref>.supabase.co/auth/v1/callback`                                            |

Client ID and secret are added to Supabase → Authentication → Providers → Google.

---

## Vercel

**Project linked to:** `krishnapriya-venkatakrishnan/budget-alert` (GitHub)

### Environment Variables

| Variable                        | Environment                                                |
| ------------------------------- | ---------------------------------------------------------- |
| `NEXT_PUBLIC_SUPABASE_URL`      | Production, Preview, Development                           |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production, Preview, Development                           |
| `SUPABASE_SERVICE_ROLE_KEY`     | Production, Preview (server-only, never exposed to client) |
| `OPENAI_API_KEY`                | Production, Preview (server-only)                          |

Preview deployments are created automatically for every PR.

---

## Resend

**Status:** Account created. Using sandbox sender (`onboarding@resend.dev`) for development — can only send to your own verified email.

**Production requirement:** A custom domain must be verified in Resend before sending to arbitrary recipients. Deferred to Phase 8 (ship checklist).

Environment variables (`RESEND_API_KEY`, `RESEND_FROM_EMAIL`) are used in Supabase Edge Functions only — never in Next.js client or server code.
