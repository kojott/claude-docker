#!/bin/bash
# Write base Claude settings.json
set -eo pipefail

SETTINGS_DIR="$HOME/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

mkdir -p "$SETTINGS_DIR"

cat > "$SETTINGS_FILE" << 'EOF'
{
  "skipDangerousModePermissionPrompt": true,
  "prefersReducedMotion": true,
  "spinnerTipsEnabled": false
}
EOF

echo "Claude settings written to $SETTINGS_FILE"
