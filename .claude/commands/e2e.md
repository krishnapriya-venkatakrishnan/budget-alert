Run Playwright end-to-end tests and summarise results.

Steps:

1. Check that `pnpm dev` is running — if not, warn the user to start it first (`pnpm dev` in a separate terminal)
2. Run `pnpm test:e2e` and capture output
3. For each failed test, report:
   - Test name and file
   - Which step failed (e.g. "expected element .dashboard to be visible")
   - Screenshot path if Playwright saved one
   - Likely cause and suggested fix

Summary table at the end:

| Suite        | Passed | Failed | Skipped |
| ------------ | ------ | ------ | ------- |
| auth         | n      | n      | n       |
| csv upload   | n      | n      | n       |
| transactions | n      | n      | n       |
| budgets      | n      | n      | n       |

If all pass: confirm safe to merge.
If any fail: list what must be fixed, and whether it is a test issue or an app issue.

To run a single test file only, pass the file path as an argument:
`/e2e tests/auth.spec.ts`

$ARGUMENTS
