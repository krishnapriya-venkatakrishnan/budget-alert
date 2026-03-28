Run the full test suite and summarise results.

Execute in order:

1. `npx tsc --noEmit` — TypeScript type check
2. `npx eslint . --max-warnings 0` — lint with zero warnings allowed
3. `pnpm test` — Vitest unit + integration tests

For each step, report:

- Pass or Fail
- If fail: exact error message, file, and line number
- Suggested fix if the cause is clear

At the end, print a summary table:

| Check      | Status | Issues       |
| ---------- | ------ | ------------ |
| TypeScript | ✓ / ✗  | count        |
| ESLint     | ✓ / ✗  | count        |
| Vitest     | ✓ / ✗  | failed/total |

If all pass, confirm it is safe to commit. If any fail, list what must be fixed before committing.

$ARGUMENTS
