#!/bin/bash
# Auto-runs Prettier on any file Claude writes or edits.
# Runs async (non-blocking) — Claude continues working while this runs.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only format supported file types
SUPPORTED_EXTENSIONS=("ts" "tsx" "js" "jsx" "json" "css" "md")
EXT="${FILE_PATH##*.}"

for supported in "${SUPPORTED_EXTENSIONS[@]}"; do
  if [ "$EXT" = "$supported" ]; then
    # Run prettier from project root if it exists
    if [ -f "$CLAUDE_PROJECT_DIR/node_modules/.bin/prettier" ]; then
      "$CLAUDE_PROJECT_DIR/node_modules/.bin/prettier" --write "$FILE_PATH" 2>/dev/null
    elif command -v npx &>/dev/null; then
      cd "$CLAUDE_PROJECT_DIR" && npx prettier --write "$FILE_PATH" 2>/dev/null
    fi
    break
  fi
done

exit 0
