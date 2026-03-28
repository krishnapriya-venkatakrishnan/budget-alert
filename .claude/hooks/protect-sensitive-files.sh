#!/bin/bash
# Blocks any write/edit to .env files, secrets, or Supabase service role key files.
# Exit 2 = block the action and send reason to Claude.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# .env.example is safe to commit (no real values) — always allow it
if [[ "$FILE_PATH" == *".env.example" ]]; then
  exit 0
fi

PROTECTED_PATTERNS=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.development"
  ".env.test"
  ".env.*"
  "secrets/"
  "secrets.json"
  ".secret"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "BLOCKED: Writing to '$FILE_PATH' is not allowed. Sensitive files (.env, secrets) must be managed manually, never by Claude. Use .env.example for documenting required variables." >&2
    exit 2
  fi
done

# Also block if content contains what looks like a real service role key
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null)
if echo "$CONTENT" | grep -qE 'eyJ[A-Za-z0-9_-]{20,}'; then
  echo "BLOCKED: Content appears to contain a JWT/service role key. Never write secrets into code files. Use environment variables only." >&2
  exit 2
fi

exit 0
