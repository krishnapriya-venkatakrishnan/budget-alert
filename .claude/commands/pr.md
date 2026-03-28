Create a GitHub pull request for the current branch.

Steps:

1. Run `git log main..HEAD --oneline` to see all commits in this branch
2. Run `git diff main...HEAD --stat` to see files changed
3. Determine the PR title from the commits (follow commit convention: type(scope): description)
4. Create the PR using the GitHub MCP with this body template:

```
## What changed
- [bullet points summarising each logical change]

## Why
[one sentence on motivation — feature, bug fix, or build phase step]

## Test plan
- [ ] `pnpm test` passes
- [ ] TypeScript: `npx tsc --noEmit` passes
- [ ] Lint: `npx eslint .` passes
- [ ] Manually tested: [describe what you clicked/verified]
- [ ] No `.env*` files committed
- [ ] No secrets in code (`/security-check` passed)

## Build phase
[Which phase from CLAUDE.md this belongs to: auth / csv / ai / charts / budgets / monitoring]
```

Target branch: `main`. Do not merge — create as draft if the test plan is incomplete.

$ARGUMENTS
