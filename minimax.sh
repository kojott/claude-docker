#!/usr/bin/env bash
# minimax.sh - Launch MiniMax Claude container over any project folder
#
# Usage:
#   ./minimax.sh <project-path>          Start and attach
#   ./minimax.sh stop <project-path>     Stop instance
#   ./minimax.sh list                    Show running instances
#
# Each folder gets its own isolated container and volumes.
# Multiple instances can run side by side.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.minimax.yml"
ENV_FILE="$SCRIPT_DIR/.env.minimax"

# --- helpers ---------------------------------------------------------------

die()  { echo "Error: $*" >&2; exit 1; }

slug() {
    basename "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g; s/^-//; s/-$//'
}

usage() {
    cat <<'EOF'
minimax.sh - MiniMax Claude over any folder

Usage:
  ./minimax.sh <project-path>          Start and attach to instance
  ./minimax.sh stop <project-path>     Stop instance
  ./minimax.sh list                    Show running minimax instances

Examples:
  ./minimax.sh ~/Work/_moje/bcrd
  ./minimax.sh ~/Work/jandomains
  ./minimax.sh stop ~/Work/_moje/bcrd
  ./minimax.sh list
EOF
    exit 0
}

# --- commands --------------------------------------------------------------

cmd_list() {
    echo "Running minimax instances:"
    echo ""
    docker ps --filter "label=com.docker.compose.service=claude-minimax" \
        --format "  {{.Names}}\t{{.Status}}\t{{.Mounts}}" 2>/dev/null || true
    echo ""
}

cmd_stop() {
    local project_path="$1"
    local name="minimax-$(slug "$project_path")"

    echo "Stopping $name ..."
    CONTAINER_NAME="$name" \
    PROJECTS_DIR="$project_path" \
        docker compose -p "$name" -f "$COMPOSE_FILE" down
    echo "Stopped."
}

cmd_start() {
    local project_path="$1"
    local name="minimax-$(slug "$project_path")"

    [[ -f "$ENV_FILE" ]] || die "Missing $ENV_FILE (API key config)"

    echo "Starting MiniMax Claude"
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
