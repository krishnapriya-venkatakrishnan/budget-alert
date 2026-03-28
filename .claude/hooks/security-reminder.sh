#!/bin/bash
# Fires on Stop (when Claude finishes a response).
# If Claude wrote any files this session, remind about security checks.
# Uses stop_hook_active to prevent infinite loop.

INPUT=$(cat)

# Prevent infinite loop
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

# Only surface reminder if files were written in this turn
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# This is informational only — exit 0 so Claude can stop normally
exit 0
