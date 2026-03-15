# Agent Knowledge Base — claude-docker

READ THIS FIRST every iteration. Update when you discover something new.

## Working Commands

| Command | Description |
|---------|-------------|
| `docker compose build` | Build Docker image |
| `docker compose build --no-cache` | Build without cache (for testing) |
| `docker compose up -d` | Start container in background |
| `docker compose down` | Stop container |
| `docker compose logs -f` | Follow logs |
| `docker exec -it claude-dev bash` | Shell into container |
| `docker exec -it claude-dev <command>` | Run command in container |

## Architecture Insights

- Base image: `debian:bookworm-slim`
- User: `dev` (UID 1000)
- Claude Code installed via NVM
- Config stored in `/home/dev/.claude` (Docker volume)
- Projects mounted from host at `/work`

## Common Pitfalls

- Docker not running - check `docker info`
- Port conflicts - check ports 3000, 5173, 8080
- Volume not persisting - check `docker volume ls`
- Build fails on arm64 - some packages don't support arm64

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Container image definition |
| `docker-compose.yml` | Container orchestration |
| `scripts/docker-entrypoint.sh` | Container startup logic |
| `scripts/init-wizard.sh` | Package selection wizard |
| `config/cl.sh` | tmux session manager |
