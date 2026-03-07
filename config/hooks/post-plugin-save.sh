#!/bin/bash
# PostToolUse hook: auto-save plugin list after install/uninstall
input=$(cat)

# Only trigger on Bash tool calls
echo "$input" | grep -q '"tool_name".*"Bash"' || exit 0

# Check if command involves plugin install/uninstall
if echo "$input" | grep -qE '"command".*((claude plugin (install|uninstall))|install-plugins)'; then
    (save-plugins > /dev/null 2>&1) || true
fi
exit 0
