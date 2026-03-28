# Claude Code & Anthropic — Project Guide
**Personal Finance Dashboard · Solo Developer Edition**

This document explains every Claude Code and Anthropic feature configured for this project, what each one does, why it was chosen, and how to use it. It is designed to be a learning reference alongside the build.

---

## 1. What is Claude Code?

Claude Code is Anthropic's AI coding assistant that runs in your terminal and integrates directly with VS Code. It can read, write, and edit files, run shell commands, browse the web, and use external tools — all within your project context.

**Key mental model:** Claude Code is not just a chat box. It is an *agent* — it can take multi-step actions autonomously. The configuration system (settings, hooks, MCPs) is how you control what it can and cannot do.

---

## 2. Configuration Architecture

Claude Code uses a **layered scope system**. Each layer can override the one below it.

```
Managed (org-wide, highest)
    ↓
Command-line flags (session only)
    ↓
Local  → .claude/settings.local.json  (your machine, this project, gitignored)
    ↓
Project → .claude/settings.json       ← THIS PROJECT uses this
    ↓
User   → ~/.claude/settings.json      (your machine, all projects)
```

**For this project**, everything lives in `.claude/settings.json` (project scope) so it is shared across sessions and committed to git. Secrets and personal overrides go in `.claude/settings.local.json` (gitignored).

### File locations in this project

| File | Purpose |
|---|---|
| `CLAUDE.md` | Auto-loaded project context for every session |
| `.claude/settings.json` | Permissions, hooks, project-level config |
| `.claude/settings.local.json` | Your personal overrides (gitignored) |
| `.mcp.json` | MCP server definitions (project scope) |
| `.claude/hooks/*.sh` | Hook shell scripts |
| `.claude/bash-history.log` | Auto-generated log of every Bash command Claude runs |

---

## 3. CLAUDE.md — Persistent Project Memory

`CLAUDE.md` in the project root is **automatically loaded into Claude's context at the start of every session**. It is the single most important file for cross-session consistency.

**What it contains for this project:**
- Full stack description (Next.js, Supabase, OpenAI, Vercel)
- Database schema (exact SQL)
- All API routes and their contracts
- Environment variable rules (which are safe client-side, which are server-only)
- Security non-negotiables
- Folder structure
- CI/CD pipeline description
- Key commands

**Why this matters for learning:** You are teaching Claude about your project once, and it remembers forever. You will never need to re-explain the stack. This is how professional teams use Claude Code — they encode their architecture decisions in CLAUDE.md.

**Additional CLAUDE.md files** can live in subdirectories. Claude loads the nearest one to the file being edited. Example: a `lib/CLAUDE.md` could describe the data access patterns for that directory specifically.

---

## 4. Settings — Permissions

Defined in `.claude/settings.json` under `"permissions"`.

### How permissions work

Rules are evaluated in order: **deny first → ask → allow → default (ask user)**.

```
Tool(specifier)
```

Examples:
- `"Bash(pnpm *)"` → matches any pnpm command
- `"Read(./.env)"` → matches reading the .env file exactly
- `"Write(./.env.*)"` → matches writing any .env variant
- `"Bash(git push *)"` → matches any git push

### What is configured for this project

**Allowed (no prompt):**
- All `pnpm` commands — daily development
- Common `git` read operations — status, diff, log, add, commit
- `tsc`, `node`, `npx` — build tools
- `chmod +x` — making hook scripts executable

**Ask (user confirms each time):**
- `git push` — intentional gate before pushing
- `git reset` / `git rebase` — destructive git ops
- `npm audit` / `gitleaks` — security scans (log them consciously)
- `supabase` / `vercel` — external service CLIs

**Denied (always blocked):**
- Reading or writing `.env` files — Claude must never touch secrets
- Reading `secrets/` directory
- `curl * | bash` / `wget * | sh` — remote code execution patterns
- `rm -rf` — destructive deletion

### Permission rule syntax reference

```
Bash(git *)          → git followed by anything
Read(./.env)         → exact file path
Read(./secrets/**)   → recursive directory match
WebFetch(domain:x)   → fetch requests to domain x
Edit(*.ts)           → any TypeScript file
```

---

## 5. Hooks — Automated Lifecycle Actions

Hooks are shell commands that Claude Code runs **automatically** at specific lifecycle points. They are deterministic — they always run, regardless of what Claude decides to do.

### Hook event types (all available)

| Event | When it fires | Blocking? |
|---|---|---|
| `PreToolUse` | Before any tool executes | Yes — can block the tool |
| `PostToolUse` | After a tool succeeds | No — tool already ran |
| `PostToolUseFailure` | After a tool fails | No |
| `PermissionRequest` | Before permission dialog appears | Yes — can auto-approve/deny |
| `SessionStart` | Session begins or resumes | No |
| `SessionEnd` | Session terminates | No |
| `Stop` | Claude finishes responding | Yes — can force Claude to continue |
| `StopFailure` | Turn ends due to API error | No |
| `Notification` | Claude needs your attention | No |
| `UserPromptSubmit` | You submit a message | Yes — can block/modify prompt |
| `ConfigChange` | A settings file changes | Yes — can block the change |
| `CwdChanged` | Working directory changes | No |
| `FileChanged` | A watched file changes on disk | No |
| `SubagentStart` / `SubagentStop` | Subagent spawned/finished | No |
| `PreCompact` / `PostCompact` | Context compaction | No |
| `InstructionsLoaded` | CLAUDE.md or rules file loaded | No |
| `WorktreeCreate` / `WorktreeRemove` | Git worktree lifecycle | Yes |
| `Elicitation` / `ElicitationResult` | MCP server requests user input | Yes |

### Hook types

| Type | What it does |
|---|---|
| `"command"` | Runs a shell script. Communicates via stdin/stdout/exit codes. |
| `"http"` | POSTs event data to a URL (useful for external audit services). |
| `"prompt"` | Single-turn LLM evaluation — model returns `{"ok": true/false, "reason": "..."}`. |
| `"agent"` | Multi-turn subagent with tool access — can read files, run commands to verify. |

### How hooks communicate with Claude

**Input:** Claude Code sends JSON to your script's stdin.

```json
{
  "session_id": "abc123",
  "cwd": "/Users/krishna/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "src/lib/openai.ts",
    "content": "..."
  }
}
```

**Output — exit codes:**
- `exit 0` → allow the action
- `exit 2` → **block** the action (write reason to stderr, Claude receives it as feedback)
- Any other exit → non-blocking error (logged in verbose mode)

**Output — structured JSON** (printed to stdout, exit 0):
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "reason shown to Claude"
  }
}
```

### Hooks configured for this project

#### `PreToolUse` → `protect-sensitive-files.sh`
**Matcher:** `Write|Edit`
**What it does:** Blocks any write/edit attempt to `.env` files or files containing JWT tokens.
**Why:** The number one security risk in this project is accidentally committing API keys. This is a hard gate — Claude cannot write to `.env` files even if it tries.

#### `PostToolUse` → `format-on-save.sh`
**Matcher:** `Write|Edit`
**What it does:** Runs Prettier on the file Claude just wrote/edited. Runs `async: true` so Claude is not blocked.
**Why:** Consistent formatting without manual effort. Every file Claude touches is auto-formatted.

#### `PostToolUse` → bash history log
**Matcher:** `Bash`
**What it does:** Appends every Bash command Claude runs (with timestamp) to `.claude/bash-history.log`.
**Why:** Audit trail. You can review everything Claude ran in a session.

#### `SessionStart` → context re-injection
**Matcher:** `compact` and `startup`
**What it does:** After context compaction (or on fresh start), injects a brief project reminder into Claude's context.
**Why:** When Claude's context window fills up and gets compacted, it can lose critical details. This ensures the stack, key rules, and current phase are always present.

#### `Notification` → macOS desktop alert
**What it does:** Fires a macOS system notification when Claude needs your attention.
**Why:** You can work on other tasks and get notified when Claude is done or needs input, instead of watching the terminal.

#### `Stop` → security-reminder.sh
**What it does:** Currently a pass-through (exit 0). Can be extended to run `gitleaks detect` or `npm audit` automatically after each Claude turn.
**Why:** Placeholder for adding automated security scanning. The `stop_hook_active` guard prevents infinite loops.

### Matcher syntax

```
"matcher": "Write|Edit"          → regex: matches Write OR Edit
"matcher": "Bash"                 → exact tool name
"matcher": "mcp__github__.*"      → all GitHub MCP tools
"matcher": "compact"              → SessionStart only on compaction
"matcher": ""                     → fires on every occurrence
```

### The `if` field (fine-grained filtering)

```json
{
  "type": "command",
  "if": "Bash(git *)",
  "command": "./hooks/check-git.sh"
}
```
`if` uses permission rule syntax to filter within a matched group. Only spawns the hook process when the tool call matches. Requires Claude Code v2.1.85+.

---

## 6. MCP — Model Context Protocol

MCP (Model Context Protocol) is an open standard that lets Claude Code connect to external tools, databases, and services. When an MCP server is connected, Claude gets new tools it can use natively in conversation.

**Analogy:** MCP servers are like browser extensions — they extend what Claude can do beyond its built-in tools.

### How MCPs are configured

MCP servers are **not** in `settings.json`. They use separate files:

| Scope | File | Who sees it |
|---|---|---|
| Project | `.mcp.json` in project root | Everyone (committed to git) |
| User | `~/.claude.json` | You, across all projects |
| Local | `~/.claude.json` (per-project section) | You, this project only |

**Precedence:** local > project > user

### CLI commands

```bash
# Add an MCP server
claude mcp add --transport http github https://api.github.com/mcp
claude mcp add --transport stdio myserver -- npx -y @some/package
claude mcp add --scope project supabase -- npx -y @supabase/mcp-server-supabase

# List servers
claude mcp list

# Check status inside Claude Code
/mcp
```

### MCPs configured for this project

#### `github` — GitHub MCP
**What it gives Claude:** Read/write access to GitHub — issues, PRs, repo data, comments.
**How to use:**
- "Create a PR for the current branch with a description of what changed"
- "List all open issues and summarise what's left to build"
- "Comment on PR #12 with my review notes"

**Setup required:** Set `GITHUB_PERSONAL_ACCESS_TOKEN` in your environment.

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
# Or add to ~/.zshrc
```

#### `supabase` (postgres) — Database MCP
**What it gives Claude:** Direct SQL query access to your Supabase PostgreSQL database.
**How to use:**
- "Show me all transactions for user X"
- "Check if RLS is enabled on all tables"
- "Count how many transactions were imported this week"
- "Verify user A cannot see user B's data"

**Setup required:** Set `SUPABASE_DB_URL` in your environment (use the direct connection string from Supabase dashboard, not the anon key).

#### `playwright` — Browser Automation MCP
**What it gives Claude:** Real browser automation — navigate, click, fill forms, screenshot.
**How to use:**
- "Open the dev server and test the CSV upload flow"
- "Screenshot the dashboard and check if the charts render"
- "Run through the signup → upload → categorise flow and tell me what broke"

**Setup required:** None — uses npx. `pnpm exec playwright install` to install browsers.

### Environment variable expansion in `.mcp.json`

The `.mcp.json` uses `${VAR}` syntax for secrets — they are read from your shell environment and never stored in the file:

```json
"env": {
  "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
}
```

---

## 7. Claude Models — Choosing the Right One

All current models support tool use and structured output (JSON mode).

### Current models (March 2026)

| Model | API ID | Best for | Speed | Cost |
|---|---|---|---|---|
| **Opus 4.6** | `claude-opus-4-6` | Complex reasoning, architecture decisions, agentic tasks | Moderate | $5/$25 per MTok |
| **Sonnet 4.6** | `claude-sonnet-4-6` | Daily coding, code review, most tasks | Fast | $3/$15 per MTok |
| **Haiku 4.5** | `claude-haiku-4-5-20251001` | Simple tasks, fast iteration, low cost | Fastest | $1/$5 per MTok |

All have **1M token context window** (Opus 4.6, Sonnet 4.6) or 200k (Haiku 4.5).

### For this project's AI feature (transaction categorisation)

The TDD specifies **GPT-4o-mini** for categorisation, but if you wanted to use Claude instead:

```typescript
// In lib/openai.ts — or a Claude version
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const response = await client.messages.create({
  model: "claude-haiku-4-5-20251001", // cheapest, fast, good enough for categorisation
  max_tokens: 1024,
  messages: [{ role: "user", content: prompt }],
});
```

**Why Haiku for categorisation:** The task is straightforward (classify into 10 buckets). Haiku is 5x cheaper than Sonnet and fast. Use Sonnet for architecture review sessions and debugging.

### Structured output (tool use)

Claude guarantees valid JSON when you use tool use format:

```typescript
const response = await client.messages.create({
  model: "claude-haiku-4-5-20251001",
  max_tokens: 1024,
  tools: [
    {
      name: "categorise_transactions",
      description: "Categorise a batch of transactions",
      input_schema: {
        type: "object",
        properties: {
          results: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id: { type: "string" },
                category: { type: "string", enum: ["Food & Drink", "Transport", "..."] },
                confidence: { type: "number" },
              },
              required: ["id", "category", "confidence"],
            },
          },
        },
      },
    },
  ],
  tool_choice: { type: "tool", name: "categorise_transactions" },
  messages: [{ role: "user", content: prompt }],
});
```

---

## 8. Slash Commands Reference

These are built-in Claude Code commands you will use during development:

| Command | What it does |
|---|---|
| `/hooks` | Browse all configured hooks, see which are active |
| `/mcp` | Check MCP server status, authenticate with OAuth servers |
| `/config` | Open settings UI — modify permissions, model, features |
| `/model` | Switch the active model (Opus/Sonnet/Haiku) |
| `/memory` | View and manage Claude's memory files |
| `/clear` | Clear context and start fresh (triggers `SessionEnd → clear`) |
| `/compact` | Manually trigger context compaction |
| `/resume` | Resume a previous session |
| `/fast` | Toggle fast mode (same model, faster output) |
| `/effort low\|medium\|high` | Adjust reasoning depth (Opus/Sonnet 4.6 only) |
| `/vim` | Toggle vim key bindings in the input prompt |
| `/review-pr` | Built-in PR review skill |
| `/commit` | Built-in commit helper skill |

---

## 9. How to Use Claude at Each Build Phase

### Phase 1 — Setup & Scaffold
```
"Review this Next.js folder structure and tell me what's missing for our stack."
"Generate the full Supabase schema SQL for our three tables plus the RLS policies."
"What's the correct way to set up a Supabase client for both server components and client components in Next.js 14 App Router?"
```

### Phase 2 — Feature Development
```
"Write the CSV upload API route. Requirements: server-side papaparse, MD5 deduplication, batch to 20 rows for OpenAI. Return {total, imported, skipped, flagged}."
"Write the OpenAI categorisation function. Categories: [list]. Return JSON array with id, category, confidence."
"This API route returns 401 even when I'm logged in. Here's the code: [paste]. Here's the error: [paste]."
```

### Phase 3 — Security Review
```
"Review all my API routes for missing auth checks. Here are the files: [paste or @files]."
"Can user A access user B's data with these RLS policies? Walk me through each policy."
"Check this environment variable setup — am I accidentally exposing any server-side secrets to the client?"
```

### Phase 4 — Testing
```
"Write Vitest unit tests for this CSV parser function, including edge cases for malformed rows and empty files."
"What inputs would break this duplicate detection logic? Write a test for each."
"Write a Playwright test for the happy path: sign up → upload CSV → see categorised transactions → set budget."
```

### Phase 5 — Code Review
```
"Review this code for N+1 queries and unnecessary re-renders."
"How would you refactor this to be more readable? Explain your reasoning."
"Is there a simpler way to achieve this without the abstraction layer?"
```

---

## 10. Security Configuration Summary

This is why each security measure was set up:

| Measure | Where | What it prevents |
|---|---|---|
| `deny Read(./.env*)` | settings.json | Claude accidentally reading your secrets |
| `deny Write(./.env*)` | settings.json | Claude writing to your env files |
| `protect-sensitive-files.sh` hook | PreToolUse | Claude writing JWT tokens into code files |
| `ask Bash(git push *)` | settings.json | Unreviewed pushes to GitHub |
| `ask Bash(gitleaks *)` | settings.json | You're aware when secrets are scanned |
| `.env` in `.gitignore` | (to be added) | Secrets never committed to git |
| RLS on all Supabase tables | Database | Cross-user data access at DB level |
| `SUPABASE_SERVICE_ROLE_KEY` server-only rule in CLAUDE.md | Context | Claude never puts service key in client code |

---

## 11. The `bash-history.log` Audit Trail

Every Bash command Claude runs is logged to `.claude/bash-history.log` with a timestamp. Add this to `.gitignore` — it is for your review only.

```bash
tail -f .claude/bash-history.log   # Watch in real time
cat .claude/bash-history.log       # Review session history
```

This is useful for:
- Understanding what Claude did during a long autonomous session
- Debugging when something unexpected happened
- Learning — see exactly what commands were run and why

---

## 12. Adding the Project to `.gitignore`

Once git is initialised, add these Claude-specific entries:

```gitignore
# Claude Code
.claude/settings.local.json
.claude/bash-history.log
```

Keep `.claude/settings.json`, `.mcp.json`, and `.claude/hooks/` committed — they are part of the project's shared configuration.

---

## 13. Quick Reference — CLI Commands

```bash
# Verify hooks are loaded
# (inside Claude Code)
/hooks

# Check MCP server status
/mcp

# Add a user-scoped MCP (personal, all projects)
claude mcp add --scope user --transport stdio name -- command

# Add a project-scoped MCP (everyone on this project)
claude mcp add --scope project --transport http name https://url

# See all configured MCPs
claude mcp list

# Switch model for this session
/model

# Review your permissions
/config
```

---

## Sources

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Claude Code Settings](https://code.claude.com/docs/en/settings)
- [Claude Code MCP](https://code.claude.com/docs/en/mcp)
- [Claude Models Overview](https://platform.claude.com/docs/en/docs/about-claude/models/overview)
- [Model Context Protocol](https://modelcontextprotocol.io/introduction)
