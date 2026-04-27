# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a containerized development environment built on Debian Bookworm. It packages VS Code Server, SSH access, multiple AI coding assistants, GPU support (NVIDIA + VAAPI), and a multi-language toolchain into a single Docker image. It is a personal environment — not a library or application with tests/linting.

## Build & Run

```bash
# Build the Docker image
docker build -t code-server:latest -f Dockerfile .

# Build and run (stops old container, builds, starts new one)
./run.sh

# Or use Docker Compose
docker compose -f compose.dev.yaml up --build
```

There are no test suites, linters, or CI pipelines. Validation happens at build time via `RUN` steps in the Dockerfile that check tool installations (LLM binaries, FFmpeg NVENC, Playwright browsers).

## Architecture

### Multi-Service Container

The container runs several concurrent services, all managed from `boot/start.sh` (the ENTRYPOINT):

1. **SSH daemon** — key-based auth only, host keys persisted via volume mount
2. **OpenCode web** — port 8444
3. **OpenChamber web** — port 8445
4. **VS Code Server** (`code serve-web`) — primary process (runs via `exec`, port 8443)

### Volume Strategy (Hybrid Mounting)

The container manages runtime (tools, PATH, system config) while the host persists user data:

- `/mnt/user/appdata/code-server/home:/root` — persistent home directory
- `/mnt/user/storage/projects:/root/projects` — project files
- `/mnt/user/appdata/code-server/ssh:/etc/ssh/keys` — SSH host keys survive rebuilds
- `/var/run/docker.sock` — Docker-in-Docker via host daemon

Because `/root` is a host mount, shell configuration uses a layered approach:
- `/etc/container-bashrc` — container-managed PATH/PS1 (survives home mount)
- `/etc/profile.d/container-env.sh` — login shell integration
- `/etc/bash.bashrc` — interactive shell integration
- `BASH_ENV=/etc/container-bashrc` — non-interactive shell support

### Key Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `HOST` | `0.0.0.0` | VS Code Server bind address |
| `PORT` | `8443` | VS Code Server port |
| `SERVER_DATA_DIR` | `/root/.vscode-server` | VS Code data directory |
| `GIT_USER` / `GIT_EMAIL` | — | Git identity (set at startup) |
| `TOKEN` / `TOKEN_FILE` | — | VS Code connection token (omit for no-auth) |

### Port Map

| Port | Service |
|---|---|
| 8443 | VS Code Server (HTTPS) |
| 8444 | OpenCode web |
| 8445 | OpenChamber web |
| 22 (→ 2222) | SSH |
| 3300-3399 | Development use |
| 60000-60020/udp | mosh |

## Key Files

| File | Purpose |
|---|---|
| `Dockerfile` | Full image definition, all tooling installed here |
| `boot/start.sh` | Container entrypoint — SSH, background services, VS Code launch |
| `run.sh` | Convenience script: build image + run container with volume/port args |
| `compose.dev.yaml` | Docker Compose definition for development |
| `extras.sh.example` | Template for local build customizations (copy to `extras.sh`) |
| `scripts/dmux` | tmux session wrapper (`dmux [path] [session-name]`) |
| `scripts/dzellij` | zellij session wrapper (`dzellij [path] [session-name]`) |
| `scripts/vscode-remote.sh` | `code()` and `codeweb()` shell functions for remote file opening |

## Local Extras (gitignored)

`extras.sh` (gitignored) runs at the end of the Docker build as root. Use it to install private or local tools that shouldn't be committed to the public repo.

1. Copy the template: `cp extras.sh.example extras.sh`
2. Add a `SOURCES=(...)` array listing any local repo paths to copy into the build context
3. Add install commands below — these run inside the image, not on the host

`run.sh` reads the `SOURCES` array from `extras.sh` using `awk` (not `source`) and copies each listed directory into `tools/<dirname>/` before building. The `tools/` directory is gitignored and cleaned up after the build.

## Installed AI Coding Tools

These are installed in the Dockerfile and moved to system paths so they survive the home directory mount:

| Tool | Install Source | Binary | API Key Env Var |
|---|---|---|---|
| Claude Code | `https://claude.ai/install.sh` | `/usr/local/bin/claude` | `ANTHROPIC_API_KEY` |
| OpenAI Codex | `npm install -g @openai/codex` | `/usr/local/bin/codex` | `OPENAI_API_KEY` |
| Google Gemini | `npm install -g @google/gemini-cli` | `/usr/local/bin/gemini` | `GOOGLE_AI_API_KEY` |
| OpenCode | `https://opencode.ai/install` | `/usr/local/bin/opencode` | — |
| OpenChamber | `pnpm add -g @openchamber/web` | `/usr/local/bin/openchamber` | — |

Build-time validation in the Dockerfile checks that `claude`, `codex`, `gemini`, and `opencode` are in PATH. If adding a new AI tool, follow the same pattern: install globally, copy/link the binary to `/usr/local/bin/`, and add a validation step.

## Editing Guidelines

- **Dockerfile changes** are the primary development activity. The Dockerfile is structured in logical sections separated by comments (e.g., `# ---- Node.js ----`, `# ---- Rust toolchain ----`). Maintain this convention.
- **Rust and Go toolchains** are installed to system paths (`/usr/local/cargo`, `/usr/local/rustup`, `/usr/local/go`) specifically to survive the home directory mount. Do not move these to `$HOME`.
- **pnpm global dir** is at `/usr/local/share/pnpm` (not `$HOME`) for the same reason.
- When adding new services to `boot/start.sh`, run them in the background (`&`) before the final `exec` for VS Code Server.
- Ports bound to `100.114.249.118` in `run.sh` and `compose.dev.yaml` are Tailscale addresses — these are intentionally restricted, not bugs.
