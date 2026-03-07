#!/bin/bash
# Install Claude plugins
# Usage: install-plugins <plugin1> [plugin2] ...
set -eo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: install-plugins <plugin1> [plugin2] ..."
    echo ""
    echo "Available plugins:"
    echo "  superpowers       - Enhanced Claude capabilities"
    echo "  context7          - Up-to-date documentation"
    echo "  playwright        - Browser automation"
    echo "  frontend-design   - Frontend design tools"
    echo "  code-review       - Code review"
    echo "  code-simplifier   - Code simplification"
    echo "  claude-mem        - Persistent memory"
    echo "  docu-optimizer    - Documentation optimization"
    echo "  feature-dev       - Feature development workflow"
    echo "  security-guidance - Security best practices"
    exit 0
fi

echo "Installing Claude plugins..."
echo ""

for plugin in "$@"; do
    echo -n "  Installing $plugin... "
    if claude plugin install "$plugin" > /dev/null 2>&1; then
        echo "done"
    else
        echo "failed (skipping)"
    fi
done

echo ""
echo "Plugin installation complete."
