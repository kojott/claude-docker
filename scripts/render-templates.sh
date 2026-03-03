#!/bin/bash
# Render Jinja2 templates from remoteclaud into plain bash scripts
# This is a build helper, not needed at runtime
set -eo pipefail

REMOTECLAUD_DIR="${1:-/srv/remoteclaud}"
OUTPUT_DIR="${2:-/srv/claude-docker/config}"

echo "Rendering templates from $REMOTECLAUD_DIR to $OUTPUT_DIR"

# cl.sh - strip Jinja2 conditionals, hardcode --dangerously-skip-permissions
sed 's/{% if cl_default_permission_mode | default('\''skip'\'') == '\''skip'\'' %}//' \
    "$REMOTECLAUD_DIR/templates/cl.sh.j2" | \
    sed '/{% else %}/,/{% endif %}/d' | \
    sed '/{% endif %}/d' | \
    sed 's/# Deployed by Ansible/# Part of claude-docker/' \
    > "$OUTPUT_DIR/cl.sh"
chmod +x "$OUTPUT_DIR/cl.sh"
echo "  Rendered cl.sh"

# tmux-cl.conf - direct copy (no Jinja2 vars)
cp "$REMOTECLAUD_DIR/templates/tmux-cl.conf.j2" "$OUTPUT_DIR/tmux-cl.conf"
sed -i 's/# Deployed by Ansible.*/# Part of claude-docker/' "$OUTPUT_DIR/tmux-cl.conf"
echo "  Copied tmux-cl.conf"

# motd.sh - update title and add /work reference
sed 's/CLAUDE DEV SERVER/CLAUDE DOCKER/' \
    "$REMOTECLAUD_DIR/templates/motd.sh.j2" | \
    sed '/Type '\''cl'\''/a\echo "  Projects in /work"' \
    > "$OUTPUT_DIR/motd.sh"
chmod +x "$OUTPUT_DIR/motd.sh"
echo "  Rendered motd.sh"

# new-project.sh - replace {{ src_dir }} with /work
sed 's|{{ src_dir }}|/work|g' \
    "$REMOTECLAUD_DIR/templates/new-project.sh.j2" | \
    sed 's/new-project\.sh/new-project/' \
    > "$OUTPUT_DIR/new-project.sh"
chmod +x "$OUTPUT_DIR/new-project.sh"
echo "  Rendered new-project.sh"

echo "Done."
