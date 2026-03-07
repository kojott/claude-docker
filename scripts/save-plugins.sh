#!/bin/bash
# save-plugins - Sync installed Claude plugins to receipts for rebuild persistence
set -eo pipefail

RECEIPTS_FILE="$HOME/.claude/.installed-packages.json"

# Get currently installed plugins from Claude CLI
installed=$(claude plugin list 2>/dev/null | grep -oE '^[a-z][a-z0-9-]+' || true)

if [ -z "$installed" ]; then
    echo "No plugins detected."
    exit 0
fi

# If no receipts file exists, create minimal one
if [ ! -f "$RECEIPTS_FILE" ]; then
    echo '{"version": 1, "installed_at": "", "runtimes": [], "tools": [], "web": [], "plugins": []}' > "$RECEIPTS_FILE"
fi

# Build new plugins JSON array
plugins_json="["
first=true
for p in $installed; do
    if [ "$first" = true ]; then first=false; else plugins_json+=", "; fi
    plugins_json+="\"$p\""
done
plugins_json+="]"

# Update plugins field in receipts
now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
sed -i "s|\"plugins\": \[.*\]|\"plugins\": $plugins_json|" "$RECEIPTS_FILE"
sed -i "s|\"installed_at\": \"[^\"]*\"|\"installed_at\": \"$now\"|" "$RECEIPTS_FILE"

echo "Saved $(echo $installed | wc -w) plugins to receipts:"
for p in $installed; do
    echo "  - $p"
done
