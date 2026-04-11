#!/usr/bin/env bash
# claude.sh - Launch Claude Code container over any project folder
#
# Usage:
#   ./claude.sh <project-path>          Start and attach
#   ./claude.sh stop <project-path>     Stop instance
#   ./claude.sh list                    Show running instances
#
# Each folder gets its own isolated container and volumes.
# Multiple instances can run side by side.
# Uses Anthropic API (OAuth or API key from .env).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
ENV_FILE="$SCRIPT_DIR/.env"

# --- helpers ---------------------------------------------------------------

die()  { echo "Error: $*" >&2; exit 1; }

slug() {
    basename "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g; s/^-//; s/-$//'
}

usage() {
    cat <<'EOF'
claude.sh - Claude Code over any folder

Usage:
  ./claude.sh <project-path>          Start and attach to instance
  ./claude.sh stop <project-path>     Stop instance
  ./claude.sh list                    Show running Claude instances

Examples:
  ./claude.sh ~/Work/_moje/bcrd
  ./claude.sh ~/Work/jandomains
  ./claude.sh stop ~/Work/_moje/bcrd
  ./claude.sh list
EOF
    exit 0
}

# --- commands --------------------------------------------------------------

cmd_list() {
    echo "Running Claude instances:"
    echo ""
    docker ps --filter "label=com.docker.compose.service=claude" \
        --format "  {{.Names}}\t{{.Status}}" 2>/dev/null || true
    echo ""
}

cmd_stop() {
    local project_path="$1"
    local name="claude-$(slug "$project_path")"

    echo "Stopping $name ..."
    CONTAINER_NAME="$name" \
    PROJECTS_DIR="$project_path" \
        docker compose -p "$name" -f "$COMPOSE_FILE" down
    echo "Stopped."
}

cmd_start() {
    local project_path="$1"
    local name="claude-$(slug "$project_path")"

    [[ -f "$ENV_FILE" ]] || die "Missing $ENV_FILE (create from .env.example)"

    echo "Starting Claude Code"
    echo "  Project:   $project_path"
    echo "  Instance:  $name"
    echo ""

    CONTAINER_NAME="$name" \
    PROJECTS_DIR="$project_path" \
        docker compose --env-file "$ENV_FILE" -p "$name" -f "$COMPOSE_FILE" up -d

    echo ""
    echo "Attaching ... (Ctrl+P, Ctrl+Q to detach without stopping)"
    docker attach "$name"
}

# --- main ------------------------------------------------------------------

[[ $# -eq 0 ]] && usage

case "${1:-}" in
    -h|--help|help)
        usage
        ;;
    list)
        cmd_list
        ;;
    stop)
        [[ -z "${2:-}" ]] && die "Usage: $0 stop <project-path>"
        target="$(cd "$2" && pwd)" || die "Directory not found: $2"
        cmd_stop "$target"
        ;;
    *)
        target="$(cd "$1" && pwd)" || die "Directory not found: $1"
        [[ -d "$target" ]] || die "Not a directory: $target"
        cmd_start "$target"
        ;;
esac
