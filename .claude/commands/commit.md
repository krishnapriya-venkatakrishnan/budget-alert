Look at the current git staged changes (`git diff --cached`) and unstaged changes (`git diff`), then create a well-formed commit following this project's convention:

```
type(scope): short description

Optional body if needed.
```

**Types:** feat, fix, test, docs, refactor, chore, ci
**Scopes:** auth, csv, ai, transactions, budgets, alerts, charts, api, db, config

Rules:

- Subject line max 72 characters, lowercase, no period at end
- Use imperative mood ("add" not "added")
- Only stage files relevant to the change — never `.env*` files
- If nothing is staged, tell me what needs staging first

Stage the relevant files and commit. Show me the final commit message before running it and ask for confirmation.
