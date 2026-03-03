#!/bin/bash
# init-wizard.sh - Interactive first-run setup for claude-docker
# Presents a TUI for selecting runtimes, tools, and plugins to install

set -o pipefail

MARKER_FILE="$HOME/.claude/.docker-init-done"
RECEIPTS_FILE="$HOME/.claude/.installed-packages.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# Install functions
# ============================================================================

install_python() {
    echo -e "  Installing Python 3..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3 python3-pip python3-venv > /dev/null 2>&1
    echo -e "  ${GREEN}Python $(python3 --version 2>&1 | awk '{print $2}') installed${NC}"
}

install_go() {
    echo -e "  Installing Go..."
    local goarch
    goarch=$(dpkg --print-architecture)
    wget -q "https://go.dev/dl/go1.23.4.linux-${goarch}.tar.gz" -O /tmp/go.tar.gz
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    export PATH="/usr/local/go/bin:$PATH"
    echo -e "  ${GREEN}Go $(go version 2>&1 | awk '{print $3}') installed${NC}"
}

install_rust() {
    echo -e "  Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null 2>&1
    . "$HOME/.cargo/env"
    echo -e "  ${GREEN}Rust $(rustc --version 2>&1 | awk '{print $2}') installed${NC}"
}

install_bun() {
    echo -e "  Installing Bun..."
    curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1
    export PATH="$HOME/.bun/bin:$PATH"
    echo -e "  ${GREEN}Bun $($HOME/.bun/bin/bun --version 2>&1) installed${NC}"
}

install_php() {
    echo -e "  Installing PHP + Composer..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq php-cli php-mbstring php-xml php-curl > /dev/null 2>&1
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1
    rm -f /tmp/composer-setup.php
    echo -e "  ${GREEN}PHP $(php -v 2>&1 | head -1 | awk '{print $2}') + Composer installed${NC}"
}

install_ruby() {
    echo -e "  Installing Ruby + Bundler..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq ruby ruby-dev > /dev/null 2>&1
    sudo gem install bundler > /dev/null 2>&1
    echo -e "  ${GREEN}Ruby $(ruby --version 2>&1 | awk '{print $2}') installed${NC}"
}

install_java() {
    echo -e "  Installing Java (OpenJDK 17)..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq openjdk-17-jdk-headless > /dev/null 2>&1
    echo -e "  ${GREEN}Java $(java --version 2>&1 | head -1) installed${NC}"
}

install_vim() {
    sudo apt-get install -y -qq vim > /dev/null 2>&1
    echo -e "  ${GREEN}vim installed${NC}"
}

install_htop() {
    sudo apt-get install -y -qq htop > /dev/null 2>&1
    echo -e "  ${GREEN}htop installed${NC}"
}

install_ripgrep() {
    sudo apt-get install -y -qq ripgrep > /dev/null 2>&1
    echo -e "  ${GREEN}ripgrep installed${NC}"
}

install_gh() {
    echo -e "  Installing GitHub CLI..."
    (type -p wget >/dev/null || sudo apt-get install wget -y -qq) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt-get update -qq \
        && sudo apt-get install -y -qq gh > /dev/null 2>&1
    rm -f "$out"
    echo -e "  ${GREEN}GitHub CLI $(gh --version 2>&1 | head -1 | awk '{print $3}') installed${NC}"
}

install_fzf() {
    sudo apt-get install -y -qq fzf > /dev/null 2>&1
    echo -e "  ${GREEN}fzf installed${NC}"
}

install_bat() {
    sudo apt-get install -y -qq bat > /dev/null 2>&1
    echo -e "  ${GREEN}bat installed${NC}"
}

install_nginx() {
    sudo apt-get install -y -qq nginx > /dev/null 2>&1
    echo -e "  ${GREEN}nginx installed${NC}"
}

install_postgresql_client() {
    sudo apt-get install -y -qq postgresql-client > /dev/null 2>&1
    echo -e "  ${GREEN}PostgreSQL client installed${NC}"
}

install_redis_tools() {
    sudo apt-get install -y -qq redis-tools > /dev/null 2>&1
    echo -e "  ${GREEN}Redis tools installed${NC}"
}

install_sqlite3() {
    sudo apt-get install -y -qq sqlite3 libsqlite3-dev > /dev/null 2>&1
    echo -e "  ${GREEN}SQLite3 installed${NC}"
}

install_plugin() {
    local plugin="$1"
    echo -e "  Installing plugin: ${plugin}..."
    claude plugin install "$plugin" > /dev/null 2>&1 || true
    echo -e "  ${GREEN}Plugin ${plugin} installed${NC}"
}

# ============================================================================
# Receipts management
# ============================================================================

save_receipts() {
    local runtimes="$1"
    local tools="$2"
    local web="$3"
    local plugins="$4"

    # Build JSON manually (no jq dependency needed)
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local json="{\n"
    json+="  \"version\": 1,\n"
    json+="  \"installed_at\": \"${now}\",\n"

    # Helper to format array
    format_array() {
        local items="$1"
        if [ -z "$items" ]; then
            echo "[]"
            return
        fi
        local result="["
        local first=true
        for item in $items; do
            if [ "$first" = true ]; then
                first=false
            else
                result+=", "
            fi
            result+="\"${item}\""
        done
        result+="]"
        echo "$result"
    }

    json+="  \"runtimes\": $(format_array "$runtimes"),\n"
    json+="  \"tools\": $(format_array "$tools"),\n"
    json+="  \"web\": $(format_array "$web"),\n"
    json+="  \"plugins\": $(format_array "$plugins")\n"
    json+="}"

    echo -e "$json" > "$RECEIPTS_FILE"
}

read_receipts_field() {
    local field="$1"
    if [ ! -f "$RECEIPTS_FILE" ]; then
        echo ""
        return
    fi
    # Simple JSON array extraction without jq
    grep "\"$field\"" "$RECEIPTS_FILE" | sed 's/.*\[//;s/\].*//' | tr -d '"' | tr ',' ' ' | tr -s ' '
}

# ============================================================================
# Silent reinstall mode
# ============================================================================

silent_reinstall() {
    echo -e "${BOLD}Reinstalling packages from saved configuration...${NC}"
    echo ""

    local apt_updated=false

    ensure_apt_updated() {
        if [ "$apt_updated" = false ]; then
            sudo apt-get update -qq
            apt_updated=true
        fi
    }

    local runtimes tools web plugins
    runtimes=$(read_receipts_field "runtimes")
    tools=$(read_receipts_field "tools")
    web=$(read_receipts_field "web")
    plugins=$(read_receipts_field "plugins")

    local count=0

    for item in $runtimes; do
        ensure_apt_updated
        case "$item" in
            python)  install_python || true ;;
            go)      install_go || true ;;
            rust)    install_rust || true ;;
            bun)     install_bun || true ;;
            php)     install_php || true ;;
            ruby)    install_ruby || true ;;
            java)    install_java || true ;;
        esac
        (( ++count ))
    done

    for item in $tools; do
        ensure_apt_updated
        case "$item" in
            vim)     install_vim || true ;;
            htop)    install_htop || true ;;
            ripgrep) install_ripgrep || true ;;
            gh)      install_gh || true ;;
            fzf)     install_fzf || true ;;
            bat)     install_bat || true ;;
        esac
        (( ++count ))
    done

    for item in $web; do
        ensure_apt_updated
        case "$item" in
            nginx)             install_nginx || true ;;
            postgresql-client) install_postgresql_client || true ;;
            redis-tools)       install_redis_tools || true ;;
            sqlite3)           install_sqlite3 || true ;;
        esac
        (( ++count ))
    done

    for item in $plugins; do
        install_plugin "$item" || true
        (( ++count ))
    done

    echo ""
    echo -e "${GREEN}Reinstalled $count packages from saved configuration.${NC}"
    touch "$MARKER_FILE"
}

# ============================================================================
# Interactive wizard
# ============================================================================

text_fallback_wizard() {
    # Plain text fallback when whiptail is not available or fails
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "  ${BOLD}CLAUDE DOCKER - First Run Setup${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Enter comma-separated items to install (or press Enter to skip)."
    echo ""

    echo -e "  ${BOLD}LANGUAGE RUNTIMES${NC}"
    echo "    python, go, rust, bun, php, ruby, java"
    echo -n "  > "
    read -r runtimes_input

    echo -e "  ${BOLD}DEV TOOLS${NC}"
    echo "    vim, htop, ripgrep, gh, fzf, bat"
    echo -n "  > "
    read -r tools_input

    echo -e "  ${BOLD}WEB & SERVERS${NC}"
    echo "    nginx, postgresql-client, redis-tools, sqlite3"
    echo -n "  > "
    read -r web_input

    echo -e "  ${BOLD}CLAUDE PLUGINS${NC} (superpowers,context7 recommended)"
    echo "    superpowers, context7, playwright, frontend-design,"
    echo "    code-review, code-simplifier, claude-mem, docu-optimizer"
    echo -n "  > "
    read -r plugins_input

    # Normalize input: trim spaces, replace commas with spaces
    local result=""
    for input in "$runtimes_input" "$tools_input" "$web_input" "$plugins_input"; do
        local items
        items=$(echo "$input" | tr ',' ' ' | tr -s ' ')
        result+=" $items"
    done
    echo "$result"
}

run_wizard() {
    local result=""
    local use_whiptail=true

    # Check if whiptail works with the current terminal
    if ! command -v whiptail >/dev/null 2>&1; then
        use_whiptail=false
    fi

    if [ "$use_whiptail" = true ]; then
        # Check terminal size for whiptail
        local rows cols
        rows=$(tput lines 2>/dev/null || echo 24)
        cols=$(tput cols 2>/dev/null || echo 80)
        local list_height=$(( rows - 12 ))
        [ "$list_height" -lt 10 ] && list_height=10
        [ "$list_height" -gt 20 ] && list_height=20

        # Try whiptail, fall back to text if it fails
        result=$(whiptail --title "CLAUDE DOCKER - First Run Setup" \
            --checklist "Select what to install (SPACE to toggle, ENTER to confirm):" \
            "$rows" "$cols" "$list_height" \
            "python"    "Python 3 + pip" OFF \
            "go"        "Go 1.23" OFF \
            "rust"      "Rust + Cargo" OFF \
            "bun"       "Bun" OFF \
            "php"       "PHP + Composer" OFF \
            "ruby"      "Ruby + Bundler" OFF \
            "java"      "Java (OpenJDK 17)" OFF \
            "vim"       "vim editor" OFF \
            "htop"      "htop process viewer" OFF \
            "ripgrep"   "ripgrep (rg) fast search" OFF \
            "gh"        "GitHub CLI" OFF \
            "fzf"       "fzf fuzzy finder" OFF \
            "bat"       "bat (cat with syntax highlighting)" OFF \
            "nginx"             "nginx web server" OFF \
            "postgresql-client" "PostgreSQL client" OFF \
            "redis-tools"       "Redis tools" OFF \
            "sqlite3"           "SQLite3" OFF \
            "superpowers" "Claude plugin: superpowers (recommended)" ON \
            "context7"    "Claude plugin: context7 docs (recommended)" ON \
            "playwright"  "Claude plugin: browser automation" OFF \
            "frontend-design" "Claude plugin: frontend design" OFF \
            "code-review"     "Claude plugin: code review" OFF \
            "code-simplifier" "Claude plugin: code simplifier" OFF \
            "claude-mem"      "Claude plugin: persistent memory" OFF \
            "docu-optimizer"  "Claude plugin: docs optimizer" OFF \
            3>&1 1>&2 2>&3)

        local whiptail_exit=$?

        if [ "$whiptail_exit" -eq 1 ]; then
            # User pressed Cancel
            echo ""
            echo -e "${YELLOW}Skipped setup. Run 'init-wizard --force' anytime to install tools.${NC}"
            touch "$MARKER_FILE"
            save_receipts "" "" "" ""
            return
        elif [ "$whiptail_exit" -ne 0 ]; then
            # whiptail failed (terminal issue) — use text fallback
            echo -e "${DIM}(whiptail unavailable, using text mode)${NC}"
            result=$(text_fallback_wizard)
        fi
    else
        result=$(text_fallback_wizard)
    fi

    # Parse selections
    local selected_runtimes="" selected_tools="" selected_web="" selected_plugins=""

    for item in $result; do
        # Remove quotes from whiptail output
        item=$(echo "$item" | tr -d '"')

        # Skip separator lines
        [[ "$item" == ---* ]] && continue

        case "$item" in
            nodejs)  ;; # already installed
            python|go|rust|bun|php|ruby|java)
                selected_runtimes+="$item "
                ;;
            vim|htop|ripgrep|gh|fzf|bat)
                selected_tools+="$item "
                ;;
            nginx|postgresql-client|redis-tools|sqlite3)
                selected_web+="$item "
                ;;
            superpowers|context7|playwright|frontend-design|code-review|code-simplifier|claude-mem|docu-optimizer)
                selected_plugins+="$item "
                ;;
        esac
    done

    # Trim trailing spaces
    selected_runtimes=$(echo "$selected_runtimes" | xargs)
    selected_tools=$(echo "$selected_tools" | xargs)
    selected_web=$(echo "$selected_web" | xargs)
    selected_plugins=$(echo "$selected_plugins" | xargs)

    # Count total items
    local total=0
    for _ in $selected_runtimes $selected_tools $selected_web $selected_plugins; do
        (( ++total ))
    done

    if [ "$total" -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}Nothing selected. Run 'init-wizard' anytime to install tools.${NC}"
        touch "$MARKER_FILE"
        save_receipts "" "" "" ""
        return
    fi

    echo ""
    echo -e "${BOLD}Installing $total selected packages...${NC}"
    echo ""

    local current=0
    local apt_updated=false

    ensure_apt_updated() {
        if [ "$apt_updated" = false ]; then
            sudo apt-get update -qq
            apt_updated=true
        fi
    }

    local failed_items=""

    # Helper: run install with error handling
    safe_install() {
        local name="$1"
        shift
        if ! "$@" 2>&1; then
            echo -e "  ${RED}Failed to install $name (continuing...)${NC}"
            failed_items+="$name "
        fi
    }

    # Install runtimes
    for item in $selected_runtimes; do
        (( ++current ))
        echo -e "${DIM}[$current/$total]${NC}"
        ensure_apt_updated
        case "$item" in
            python) safe_install python install_python ;;
            go)     safe_install go install_go ;;
            rust)   safe_install rust install_rust ;;
            bun)    safe_install bun install_bun ;;
            php)    safe_install php install_php ;;
            ruby)   safe_install ruby install_ruby ;;
            java)   safe_install java install_java ;;
        esac
    done

    # Install tools
    for item in $selected_tools; do
        (( ++current ))
        echo -e "${DIM}[$current/$total]${NC}"
        ensure_apt_updated
        case "$item" in
            vim)     safe_install vim install_vim ;;
            htop)    safe_install htop install_htop ;;
            ripgrep) safe_install ripgrep install_ripgrep ;;
            gh)      safe_install gh install_gh ;;
            fzf)     safe_install fzf install_fzf ;;
            bat)     safe_install bat install_bat ;;
        esac
    done

    # Install web
    for item in $selected_web; do
        (( ++current ))
        echo -e "${DIM}[$current/$total]${NC}"
        ensure_apt_updated
        case "$item" in
            nginx)             safe_install nginx install_nginx ;;
            postgresql-client) safe_install postgresql-client install_postgresql_client ;;
            redis-tools)       safe_install redis-tools install_redis_tools ;;
            sqlite3)           safe_install sqlite3 install_sqlite3 ;;
        esac
    done

    # Install plugins
    for item in $selected_plugins; do
        (( ++current ))
        echo -e "${DIM}[$current/$total]${NC}"
        safe_install "$item" install_plugin "$item"
    done

    # Save receipts
    save_receipts "$selected_runtimes" "$selected_tools" "$selected_web" "$selected_plugins"
    touch "$MARKER_FILE"

    # Summary
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}${BOLD}Setup complete!${NC} Installed $total packages."
    echo ""
    [ -n "$selected_runtimes" ] && echo -e "  ${BOLD}Runtimes:${NC} $selected_runtimes"
    [ -n "$selected_tools" ] && echo -e "  ${BOLD}Tools:${NC}    $selected_tools"
    [ -n "$selected_web" ] && echo -e "  ${BOLD}Web:${NC}      $selected_web"
    [ -n "$selected_plugins" ] && echo -e "  ${BOLD}Plugins:${NC}  $selected_plugins"
    if [ -n "$failed_items" ]; then
        echo ""
        echo -e "  ${RED}Failed:${NC}   $failed_items"
        echo -e "  ${DIM}Re-run 'init-wizard --force' to retry${NC}"
    fi
    echo ""
    echo -e "  Run ${BOLD}init-wizard --force${NC} anytime to modify your setup."
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    mkdir -p "$HOME/.claude"

    # Silent mode (--silent flag or called from entrypoint for reinstall)
    if [ "$1" = "--silent" ]; then
        if [ -f "$RECEIPTS_FILE" ]; then
            silent_reinstall
        fi
        return
    fi

    # Force mode (--force flag, user wants to re-run wizard)
    if [ "$1" = "--force" ]; then
        run_wizard
        return
    fi

    # Normal mode: run wizard if not done yet
    if [ ! -f "$MARKER_FILE" ]; then
        run_wizard
    else
        echo -e "${DIM}Setup already completed. Use 'init-wizard --force' to re-run.${NC}"
    fi
}

main "$@"
