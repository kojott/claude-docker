#!/bin/bash
# clip2docker - Paste clipboard image into the Docker container's /shared directory
# Usage: clip2docker [filename]
# Requires: macOS (uses osascript for clipboard image extraction)
#
# Part of claude-docker

set -euo pipefail

SHARED_DIR="${SHARED_DIR:-$(cd "$(dirname "$0")/.." && pwd)/shared}"
FILENAME="${1:-clipboard-$(date +%Y%m%d-%H%M%S).png}"

# Ensure .png extension
[[ "$FILENAME" != *.png ]] && FILENAME="${FILENAME}.png"

DEST="${SHARED_DIR}/${FILENAME}"

mkdir -p "$SHARED_DIR"

# Use osascript to save clipboard image as PNG (no brew dependencies needed)
osascript -e '
try
    set imgData to the clipboard as «class PNGf»
    set filePath to POSIX file "'"$DEST"'"
    set fileRef to open for access filePath with write permission
    set eof fileRef to 0
    write imgData to fileRef
    close access fileRef
    return "ok"
on error errMsg
    return "error: " & errMsg
end try
' | {
    read -r result
    if [[ "$result" == "ok" ]]; then
        echo "Saved: $DEST"
        echo "In container: /shared/$FILENAME"
    else
        echo "Failed to paste image from clipboard." >&2
        echo "$result" >&2
        echo "Make sure you have an image (not text) on the clipboard." >&2
        exit 1
    fi
}
