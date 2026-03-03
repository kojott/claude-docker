# claude-docker

Secure Docker sandbox for running Claude Code in YOLO mode (`--dangerously-skip-permissions`). A lightweight Debian-based image with an interactive first-run wizard that lets you pick which runtimes, tools, and Claude plugins to install.

Works on Linux, macOS, and Windows (via Docker Desktop).

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
- Escalate to host root (`no-new-privileges`)
- Access host filesystem outside `/work`
- Access other containers

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

## Authentication

### Option A: API Key (recommended for headless/automated use)

Set `ANTHROPIC_API_KEY` in your `.env` file:

```bash
ANTHROPIC_API_KEY=sk-ant-...
```

### Option B: OAuth (interactive login)

Leave `ANTHROPIC_API_KEY` empty. On first Claude launch, you'll be prompted to authenticate interactively via the browser. The auth token is stored in the `claude-home` Docker volume and persists across container restarts.

## Daily Usage

### Start / Stop / Connect

```bash
docker compose up -d          # start container
docker exec -it claude-dev bash  # connect
docker compose down           # stop

# Or with CLAUDE_AUTOSTART=1 in .env:
docker compose up -d
docker attach claude-dev      # directly in cl session manager
```

### Session Manager (cl)

Inside the container, use `cl` to manage Claude tmux sessions:

```
cl                  # interactive menu (default)
cl -n fix-auth      # new named session
cl -w feature       # new worktree session
cl -c               # continue last conversation
cl -r               # resume past conversation
cl -l               # list sessions
cl -x               # clean up dead sessions
cl -h               # help
```

Detach from tmux: `Ctrl+B, D`. Reconnect: `docker exec -it claude-dev bash` then `cl`.

### Init Wizard

The init wizard runs automatically on first start. To re-run it:

```bash
init-wizard --force    # interactive re-selection
```

Your selections are saved. If the container is rebuilt but the Docker volume persists, packages are automatically reinstalled on next start.

### Create New Project

```bash
new-project my-app     # creates /work/my-app with git, CLAUDE.md, .gitignore
cd /work/my-app
cl                     # start Claude session
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

### Clean Up

```bash
# Remove container and volumes (loses installed packages + auth)
docker compose down -v

# Remove just the container (keeps claude-home volume)
docker compose down
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `claude: command not found` | Run `. ~/.nvm/nvm.sh` to load Node.js |
| Init wizard doesn't appear | Run `init-wizard` manually |
| Packages lost after rebuild | Check that `claude-home` volume exists: `docker volume ls` |
| Permission denied on `/work` | Check host directory permissions match UID 1000 |
| Port already in use | Change `PORT_DEV1`/`PORT_DEV2`/`PORT_DEV3` in `.env` |
| Out of memory | Increase `MEMORY_LIMIT` in `.env` (default: 8g) |
| GitHub CLI auth fails | Set `GITHUB_TOKEN` in `.env` |

## Advanced

### Custom Dockerfile

Extend the base image:

```dockerfile
FROM ghcr.io/kojott/claude-docker:latest
RUN sudo apt-get update && sudo apt-get install -y your-package
```

### Multiple Project Directories

Mount additional directories in `docker-compose.yml`:

```yaml
volumes:
  - ~/projects:/work
  - ~/other-projects:/other
  - claude-home:/home/dev/.claude
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

## License

MIT
