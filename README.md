# claude-docker

Secure Docker sandbox for running Claude Code in YOLO mode (`--dangerously-skip-permissions`). A lightweight Debian-based image with an interactive first-run wizard that lets you pick which runtimes, tools, and Claude plugins to install.

Works on Linux, macOS, and Windows (via Docker Desktop).

## Table of Contents

- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Installation](#installation)
- [Configuration (.env)](#configuration)
- [Authentication](#authentication)
- [Init Wizard](#init-wizard)
- [Session Manager (cl)](#session-manager-cl)
- [Creating Projects (new-project)](#creating-projects)
- [Claude Plugins (install-plugins)](#claude-plugins)
- [Process Cleanup (claude-gc)](#process-cleanup)
- [Container Lifecycle](#container-lifecycle)
- [Volume Persistence](#volume-persistence)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [Advanced](#advanced)
- [License](#license)

## Quick Start

```bash
git clone https://github.com/kojott/claude-docker.git
cd claude-docker
cp .env.example .env          # set PROJECTS_DIR and ANTHROPIC_API_KEY
docker compose up -d
docker exec -it claude-dev bash
```

On first connect, the **init wizard** appears — select your runtimes (Python, Go, Rust, etc.), dev tools, and Claude plugins. Everything installs inside the container.

## How It Works

```
┌──────────────────────────────────────────────────┐
│  HOST MACHINE                                    │
│                                                  │
│  ~/projects/ ◄──────── mounted as /work ────►    │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │  DOCKER CONTAINER (claude-dev)             │  │
│  │                                            │  │
│  │  /work        ← your projects (read/write) │  │
│  │  /home/dev    ← dev user home              │  │
│  │                                            │  │
│  │  Claude Code + tmux session manager (cl)   │  │
│  │  Init wizard for runtime/tool selection    │  │
│  │  Passwordless sudo for apt installs        │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  Ports: 3000, 5173, 8080 (configurable)          │
└──────────────────────────────────────────────────┘
```

### Security Model

**What the container CAN do:**
- Read/write files in `/work` (mounted from host)
- Install any packages inside the container (`sudo apt install ...`)
- Access the internet (APIs, package registries)
- Bind to ports 3000, 5173, 8080

**What the container CANNOT do:**
- Access the Docker socket
- Access host filesystem outside `/work`
- Access other containers

### What's Pre-installed

The base image includes the minimum needed:

| Category | Packages |
|----------|----------|
| Core | git, tmux, curl, wget, sudo, locales |
| Build | build-essential, make, gcc, g++ |
| Utilities | procps, less, whiptail, openssh-client, unzip, tar, gzip, xz-utils |
| Node.js | NVM + Node.js 24 (required for Claude Code) |
| Claude | Claude Code CLI (`@anthropic-ai/claude-code`) |
| Tools | `cl` session manager, `claude-gc` process cleanup, `new-project` scaffolder |

Everything else (Python, Go, Rust, vim, etc.) is installed on-demand via the init wizard.

## Installation

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (Docker Desktop on Mac/Windows, Docker Engine on Linux)
- [Docker Compose](https://docs.docker.com/compose/install/) (included with Docker Desktop)

### Linux

```bash
# Install Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in, then:
git clone https://github.com/kojott/claude-docker.git
cd claude-docker
cp .env.example .env
# Edit .env — set PROJECTS_DIR and ANTHROPIC_API_KEY
docker compose up -d
```

### macOS / Windows

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Clone this repo and configure `.env`
3. Run `docker compose up -d`

## Configuration

All configuration is in the `.env` file. Copy `.env.example` to get started:

```bash
cp .env.example .env
```

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PROJECTS_DIR` | Path to your projects on the host, mounted as `/work` | `~/projects` |
| `ANTHROPIC_API_KEY` | Your Anthropic API key (leave empty for OAuth login) | `sk-ant-...` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GITHUB_TOKEN` | _(empty)_ | GitHub personal access token — auto-configures `gh` CLI on start |
| `GIT_USER_NAME` | `Claude Dev` | Git author name inside the container |
| `GIT_USER_EMAIL` | `dev@localhost` | Git author email inside the container |
| `CLAUDE_AUTOSTART` | `0` | Set to `1` to launch `cl` session manager immediately on `docker attach` |
| `MEMORY_LIMIT` | `8g` | Container memory limit |
| `CPU_LIMIT` | `4.0` | Container CPU limit |
| `PORT_DEV1` | `3000` | First forwarded port (host:container) |
| `PORT_DEV2` | `5173` | Second forwarded port |
| `PORT_DEV3` | `8080` | Third forwarded port |

### Environment Variable Details

**`GITHUB_TOKEN`** — If set, the entrypoint runs `gh auth login --with-token` automatically. Useful for `gh pr create`, `gh issue list`, etc. inside the container.

**`CLAUDE_AUTOSTART`** — When set to `1`, running `docker compose up -d && docker attach claude-dev` drops you directly into the `cl` session manager (instead of a bash shell). Detach with `Ctrl+P, Ctrl+Q`.

**Port mapping** — If any port is already in use on the host, change it:
```bash
PORT_DEV1=3001    # maps host 3001 → container 3000
```

## Authentication

### Option A: API Key (recommended for headless/automated use)

Set `ANTHROPIC_API_KEY` in your `.env` file:

```bash
ANTHROPIC_API_KEY=sk-ant-...
```

### Option B: OAuth (interactive login — recommended for Pro/Max subscribers)

Leave `ANTHROPIC_API_KEY` empty. On first Claude launch, you'll be prompted to authenticate interactively via the browser.

**Auth persistence**: The container sets `CLAUDE_CONFIG_DIR=/home/dev/.claude` which tells Claude Code to store ALL config files (including auth state) inside `~/.claude/` — the Docker volume. This means:

- OAuth tokens (access + refresh) persist in `~/.claude/.credentials.json`
- Config and onboarding state persist in `~/.claude/.claude.json`
- After initial login, **you stay logged in across container rebuilds** — Claude uses the long-lived refresh token (valid for months) to automatically renew the access token, just like on desktop

No re-authentication needed after `docker compose build` — the `claude-home` volume keeps everything.

### How `CLAUDE_CONFIG_DIR` Works

Without `CLAUDE_CONFIG_DIR`, Claude stores config in two separate locations:
- `~/.claude.json` (container filesystem — **lost on rebuild**)
- `~/.claude/.credentials.json` (Docker volume — persists)

With `CLAUDE_CONFIG_DIR=/home/dev/.claude`, Claude stores **everything** inside `~/.claude/`:
- `~/.claude/.claude.json` (Docker volume — **persists**)
- `~/.claude/.credentials.json` (Docker volume — **persists**)

This is the [official approach endorsed by Anthropic](https://github.com/anthropics/claude-code/issues/1736) for running Claude Code in Docker.

## Init Wizard

The init wizard is an interactive TUI (using `whiptail`) that runs on first container start. It lets you choose which runtimes, tools, and plugins to install.

### When Does It Run?

- **First start**: Automatically when you connect to the container for the first time
- **Re-run manually**: `init-wizard --force` (shows wizard again even if already initialized)
- **Silent reinstall**: `init-wizard --silent` (reinstalls from saved receipts, no UI)

### Available Packages

#### Language Runtimes

| Package | What Gets Installed |
|---------|---------------------|
| Python 3 | `python3`, `python3-pip`, `python3-venv` |
| Go 1.23 | Official Go binary from go.dev (`linux/amd64` or `linux/arm64`) |
| Rust | Via `rustup` — includes `rustc`, `cargo` |
| Bun | Via official Bun installer |
| PHP | `php-cli`, `php-mbstring`, `php-xml`, `php-curl` + Composer |
| Ruby | `ruby`, `ruby-dev` + Bundler |
| Java | OpenJDK 17 (headless) |

#### Dev Tools

| Package | What Gets Installed |
|---------|---------------------|
| vim | `vim` editor |
| htop | `htop` process monitor |
| ripgrep | `rg` — fast grep alternative |
| GitHub CLI | `gh` — GitHub from the command line |
| fzf | Fuzzy finder |
| bat | `cat` with syntax highlighting (run as `batcat` on Debian) |

#### Web & Servers

| Package | What Gets Installed |
|---------|---------------------|
| nginx | `nginx` web server |
| PostgreSQL client | `postgresql-client` (psql) |
| Redis tools | `redis-tools` (redis-cli) |
| SQLite3 | `sqlite3` + `libsqlite3-dev` |

#### Claude Plugins

| Plugin | Description | Default |
|--------|-------------|---------|
| superpowers | Enhanced Claude capabilities (brainstorming, TDD, debugging skills) | ON |
| context7 | Up-to-date library documentation | ON |
| playwright | Browser automation and testing | OFF |
| frontend-design | Frontend design tools | OFF |
| code-review | Code review workflow | OFF |
| code-simplifier | Code simplification | OFF |
| claude-mem | Persistent memory across sessions | OFF |
| docu-optimizer | Documentation optimization | OFF |

### How Receipts Work

After the wizard finishes, your selections are saved to `~/.claude/.installed-packages.json`:

```json
{
  "version": 1,
  "installed_at": "2026-03-03T14:00:00Z",
  "runtimes": ["python", "go"],
  "tools": ["vim", "htop", "ripgrep", "gh"],
  "web": ["sqlite3"],
  "plugins": ["superpowers", "context7"]
}
```

This file lives on the `claude-home` Docker volume, so it survives `docker compose down`. When the container is rebuilt (new image) but the volume persists, the entrypoint automatically reinstalls everything in the background — see [Volume Persistence](#volume-persistence).

### Text Fallback

If `whiptail` fails (e.g., non-interactive terminal), the wizard falls back to a plain-text menu where you type numbers to select packages.

## Session Manager (cl)

`cl` is a tmux-based session manager for running Claude Code. It's available on `PATH` inside the container.

### Usage

```
cl                  # interactive menu (default)
cl -n <name>        # new named session
cl -a <name>        # attach to existing session
cl -w [name]        # new worktree session
cl -c               # continue last conversation
cl -r               # resume past conversation (picker)
cl -l               # list all sessions
cl -x               # clean up dead sessions + orphaned worktrees
cl -h               # help
cl -v               # version
```

### Interactive Menu

Running `cl` with no arguments shows a menu:

```
╔══════════════════════════════════════════════╗
║  Claude Session Manager                      ║
╠══════════════════════════════════════════════╣
║  n) New session                              ║
║  w) New worktree session                     ║
║  c) Continue last conversation               ║
║  r) Resume past conversation                 ║
║  l) List sessions                            ║
║  x) Clean up                                 ║
║  q) Quit                                     ║
║                                              ║
║  Or type a session name to attach/create     ║
╚══════════════════════════════════════════════╝
```

### Session Types

**Named session** (`cl -n fix-auth`): Creates a new tmux session named `cl-fix-auth` and starts Claude in it. Claude runs with `--dangerously-skip-permissions`.

**Worktree session** (`cl -w feature`): Creates a git worktree and starts Claude in it. Useful for working on multiple features in parallel without branch switching.

**Continue** (`cl -c`): Resumes Claude's most recent conversation (equivalent to `claude --continue`).

**Resume** (`cl -r`): Opens a picker to choose from past conversations (equivalent to `claude --resume`).

### Tmux Keys

| Key | Action |
|-----|--------|
| `Ctrl+B, D` | Detach from session (keeps Claude running) |
| `Ctrl+B, [` | Enter scroll mode (navigate with arrows, `q` to exit) |
| `Ctrl+B, c` | New tmux window within session |
| `Ctrl+B, n/p` | Next/previous tmux window |

### Session Cleanup

`cl -x` removes:
- Dead tmux sessions (older than 5 minutes)
- Orphaned git worktrees from worktree sessions

### Status Bar

The tmux status bar shows:
- **Left**: Session name
- **Right**: Current time

Configuration is in `~/.tmux-cl.conf`. Mouse mode is enabled by default.

## Creating Projects

`new-project` scaffolds a new project directory in `/work`:

```bash
new-project my-app
```

This creates:

```
/work/my-app/
├── .git/              # initialized git repo
├── .gitignore         # common ignores (node_modules, .env, build/, etc.)
├── CLAUDE.md          # template for Claude context
├── src/               # source code
├── tests/             # tests
└── docs/              # documentation
```

Then start working:

```bash
cd /work/my-app
cl -n my-app           # start Claude session for this project
```

The generated `CLAUDE.md` is a template — fill it in with project-specific instructions for Claude.

## Claude Plugins

Plugins extend Claude Code with additional skills and MCP integrations.

### Installing Plugins

**Via init wizard** (recommended): Select plugins during first-run setup. They get saved to receipts and auto-reinstalled on container rebuild.

**Manually**: Use the `install-plugins` helper:

```bash
install-plugins superpowers context7 playwright
```

Or install directly via Claude CLI:

```bash
claude plugin install superpowers
```

### Available Plugins

```bash
install-plugins    # run without arguments to see the list
```

| Plugin | Description |
|--------|-------------|
| `superpowers` | Brainstorming, TDD, debugging, code review skills |
| `context7` | Query up-to-date documentation for any library |
| `playwright` | Browser automation (screenshots, clicks, form filling) |
| `frontend-design` | Distinctive frontend design generation |
| `code-review` | Structured code review workflow |
| `code-simplifier` | Simplify and refine code |
| `claude-mem` | Persistent memory across Claude sessions |
| `docu-optimizer` | CLAUDE.md and documentation optimization |

### Plugin Persistence

Plugins installed via the init wizard are saved in the receipts file and automatically reinstalled when the container is rebuilt. Plugins installed manually (via `install-plugins` or `claude plugin install`) are stored in `~/.claude/` which is on the persistent volume.

## Process Cleanup

`claude-gc` ([kojott/claude-gc](https://github.com/kojott/claude-gc)) cleans up orphaned Claude and MCP server processes that can accumulate and consume memory.

### Automatic Cleanup

The container entrypoint starts a background loop that runs `claude-gc` every 15 minutes. No action needed.

### Manual Cleanup

```bash
claude-gc              # run cleanup now (shows what was killed)
claude-gc --quiet      # run silently
```

### What Gets Cleaned

- Detached/orphaned Claude Code processes
- Orphaned MCP server processes (node processes spawned by Claude)

## Container Lifecycle

### Starting

```bash
docker compose up -d                    # start container in background
docker exec -it claude-dev bash         # connect with interactive shell
```

Or with autostart:
```bash
# In .env: CLAUDE_AUTOSTART=1
docker compose up -d
docker attach claude-dev                # drops directly into cl session manager
# Detach: Ctrl+P, Ctrl+Q
```

### What Happens on Start (Entrypoint)

1. Sources `~/.bashrc` for PATH setup
2. Syncs `lastOnboardingVersion` in config to match installed Claude version (prevents re-onboarding after Claude updates)
3. Cleans up stale config files from previous entrypoint versions
4. Configures git identity from `GIT_USER_NAME` / `GIT_USER_EMAIL` env vars
5. Runs `gh auth login` if `GITHUB_TOKEN` is set
6. Starts `claude-gc` background loop (every 15 minutes)
7. If first run (no marker file) + interactive terminal → launches init wizard
8. If marker exists but packages are missing (container rebuilt) → background reinstall
9. If `CLAUDE_AUTOSTART=1` → `exec cl`, otherwise → `exec bash`

### Stopping

```bash
docker compose down                     # stop container (volumes preserved)
docker compose down -v                  # stop + delete volumes (full reset)
```

### Connecting Multiple Terminals

You can connect multiple shells to the same container:

```bash
# Terminal 1
docker exec -it claude-dev bash

# Terminal 2 (separate shell, same container)
docker exec -it claude-dev bash
```

Each gets its own bash session. Tmux sessions are shared.

### Login Message (MOTD)

When you connect via `docker exec -it ... bash`, you see:

```
  CLAUDE DOCKER

  Sessions:  2 active (1 attached, 1 detached)
  Projects:  fix-auth, my-app

  Type 'cl' to manage sessions
  Projects in /work
```

This shows active Claude sessions and the projects they're working on. The MOTD is suppressed inside tmux panes.

## Volume Persistence

The container uses two mount points:

| Mount | Type | Purpose |
|-------|------|---------|
| `/work` | Bind mount | Your projects (from `PROJECTS_DIR` on host) |
| `/home/dev/.claude` | Named volume (`claude-home`) | Claude auth, settings, plugins, wizard receipts |

### What Survives What

| Event | `/work` (projects) | `claude-home` (config) |
|-------|---------------------|------------------------|
| `docker compose down` | Kept | Kept |
| `docker compose down -v` | Kept | **Deleted** |
| Container rebuild (`docker compose build`) | Kept | Kept |
| Host reboot | Kept | Kept |

### Automatic Reinstall After Rebuild

When you rebuild the container image (e.g., to get a newer Claude Code version):

```bash
docker compose build --no-cache
docker compose up -d
```

The entrypoint detects that packages from your receipts are missing (because the container filesystem was rebuilt) and automatically reinstalls them in the background. You can use the container immediately — run `tail -f /tmp/reinstall.log` to monitor progress.

### Full Reset

To start completely fresh:

```bash
docker compose down -v                  # removes claude-home volume
docker compose up -d                    # init wizard will run again
```

## Maintenance

### Update Claude Code

```bash
docker exec -it claude-dev bash
. ~/.nvm/nvm.sh
npm update -g @anthropic-ai/claude-code
```

### Rebuild Container

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
# Packages reinstall automatically from saved configuration
```

### Install Additional Packages

Inside the container, you have full `sudo` access:

```bash
sudo apt-get update && sudo apt-get install -y cowsay
```

These manual installs don't survive container rebuilds. For persistent installs, either:
- Add them to init wizard selections (`init-wizard --force`)
- Extend the Dockerfile (see [Advanced](#advanced))

### Shell Aliases & PATH

The container shell has these pre-configured:

| Alias/Path | Description |
|------------|-------------|
| `work` | Alias for `cd /work` |
| `~/bin` | In PATH — put custom scripts here |
| `~/.local/bin` | In PATH |
| `/usr/local/go/bin` | In PATH (if Go installed) |
| `~/.cargo/bin` | In PATH (if Rust installed) |
| `~/.bun/bin` | In PATH (if Bun installed) |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `claude: command not found` | Run `. ~/.nvm/nvm.sh` to load Node.js |
| Login/onboarding screen after rebuild | Check `CLAUDE_CONFIG_DIR` is set: `echo $CLAUDE_CONFIG_DIR` should show `/home/dev/.claude`. If not, add it to your `docker-compose.yml` environment section |
| "Configuration file not found" warning | Run `cp ~/.claude/backups/.claude.json.backup.* ~/.claude/.claude.json` to restore from Claude's automatic backup |
| Init wizard doesn't appear | Run `init-wizard` manually |
| Wizard shows garbled text | Your terminal doesn't support whiptail — the wizard will fall back to text mode |
| Packages lost after rebuild | Check that `claude-home` volume exists: `docker volume ls` |
| Auth lost after `docker compose down -v` | The `-v` flag deletes volumes including auth. You'll need to re-login. Use `down` without `-v` to preserve auth |
| Permission denied on `/work` | Check host directory permissions match UID 1000 (`id -u` on host) |
| Port already in use | Change `PORT_DEV1`/`PORT_DEV2`/`PORT_DEV3` in `.env` |
| Out of memory | Increase `MEMORY_LIMIT` in `.env` (default: 8g) |
| GitHub CLI auth fails | Set `GITHUB_TOKEN` in `.env` |
| `sudo: unable to send audit message` | Ensure `AUDIT_WRITE` is in `cap_add` in docker-compose.yml |
| Background reinstall is slow | Normal — run `tail -f /tmp/reinstall.log` to monitor. Container is usable while it runs. |
| Want to re-pick packages | Run `init-wizard --force` to show the wizard again |
| Container won't start | Check `.env` syntax — no quotes around values, no trailing spaces |

## Advanced

### Custom Dockerfile

Extend the base image for team-wide customizations:

```dockerfile
FROM ghcr.io/kojott/claude-docker:latest
USER root
RUN apt-get update && apt-get install -y your-package
USER dev
```

Build and use:

```bash
docker build -t my-claude -f Dockerfile.custom .
# Update docker-compose.yml to use image: my-claude
```

### Multiple Project Directories

Mount additional directories in `docker-compose.yml`:

```yaml
volumes:
  - ~/projects:/work
  - ~/other-projects:/other
  - claude-home:/home/dev/.claude
```

### Additional Ports

Add more port mappings in `docker-compose.yml`:

```yaml
ports:
  - "${PORT_DEV1:-3000}:3000"
  - "${PORT_DEV2:-5173}:5173"
  - "${PORT_DEV3:-8080}:8080"
  - "4000:4000"    # additional port
```

### VS Code Dev Containers

Add a `.devcontainer/devcontainer.json` to your project:

```json
{
  "image": "ghcr.io/kojott/claude-docker:latest",
  "remoteUser": "dev",
  "mounts": ["source=${localWorkspaceFolder},target=/work,type=bind"]
}
```

### Resource Limits

Adjust in `.env`:

```bash
MEMORY_LIMIT=16g    # more memory for large codebases
CPU_LIMIT=8.0       # more CPU cores
```

### Multi-Architecture

The GitHub Actions workflow builds for both `linux/amd64` and `linux/arm64`. To trigger a multi-arch build and push:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This pushes to `ghcr.io/kojott/claude-docker:v1.0.0` and `ghcr.io/kojott/claude-docker:latest`.

## File Reference

| File | Description |
|------|-------------|
| `Dockerfile` | Image definition (debian:bookworm-slim + NVM + Claude Code) |
| `docker-compose.yml` | Container orchestration with security, resources, ports |
| `.env.example` | Configuration template |
| `config/cl.sh` | `cl` tmux session manager |
| `config/tmux-cl.conf` | tmux configuration for cl sessions |
| `config/motd.sh` | Login message showing active sessions |
| `config/new-project.sh` | Project scaffolding script |
| `config/bashrc-additions.sh` | Shell PATH and aliases |
| `config/profile-path.sh` | Login shell PATH (profile.d) |
| `scripts/docker-entrypoint.sh` | Container entrypoint logic |
| `scripts/init-wizard.sh` | Interactive package selection wizard |
| `scripts/install-plugins.sh` | Claude plugin installer |
| `scripts/setup-claude-settings.sh` | Base Claude settings writer |
| `.github/workflows/build-push.yml` | CI/CD multi-arch build to ghcr.io |

## License

MIT
