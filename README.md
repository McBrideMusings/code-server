# Code Server Development Container

A comprehensive development environment container based on Debian Bookworm with VS Code Server, SSH access, and extensive tooling for modern software development. 

# Disclaimer
This was made for my needs specifically. I'd recommend this be a baseline for a custom docker container, if this looks useful to you, over one you try to run directly. I don't have any checks for what tools you want, nor do I have checks for hardware like GPUs. I make no gurentte but it's proven very useful for me and the ssh work to persist and share keys with the host is extremely helpful

## Features

- **VS Code Server**: Web-based VS Code interface accessible via browser
- **SSH Access**: Full terminal access with persistent host keys
- **Multi-language Support**: Go, Rust, Node.js, Python, PHP, C/C++
- **AI Coding Tools**: Claude, OpenAI Codex, Gemini, OpenCode integration
- **GPU Support**: NVIDIA CUDA and Intel/AMD VAAPI hardware acceleration
- **Development Tools**: Docker, Git, tmux, zellij, and comprehensive build toolchain

## Architecture

### Volume Strategy
The container uses a hybrid mounting approach:
- **Full home persistence**: `/mount/point:/root`
- **Symlinked workspaces**: Host directories symlinked into container home
- **System-wide configuration**: Shell/PATH managed by container, data persisted on host

### Configuration Sources
1. **Container-managed**: PATH, PS1, system tools (via `/etc/container-bashrc`)
2. **Host-persisted**: Bash history, git config, SSH keys, project files
3. **Hybrid**: Tool configurations that need both approaches

## Directory Structure

```
/root/                          # Mounted from host for persistence
├── .bash_history              # Persistent command history
├── .gitconfig                 # Persistent git configuration
└── .ssh/                      # SSH client keys

/etc/ssh/keys/                  # Persistent SSH host keys
/etc/container-bashrc           # Container-managed shell config
```

## Development Languages & Tools

### Programming Languages
- **Go**: Latest with gopls, dlv, staticcheck
- **Rust**: Latest stable with rustfmt, clippy, cargo
- **Node.js**: LTS 20 with TypeScript, ESLint
- **Python**: 3.x with pip, venv support
- **PHP**: CLI with common extensions
- **C/C++**: GCC, Clang, CMake, Ninja

### Development Tools
- **Git**: With GitHub CLI integration
- **Docker**: Client for host Docker daemon
- **Editors**: vim, nano, VS Code
- **Terminal**: tmux, zellij for session management
- **Monitoring**: htop, nvtop for system monitoring

## Network Configuration

### Default Ports
- **VS Code**: `8443` (HTTPS web interface)
- **SSH**: `2222` (mapped to container port 22)
- **Dev Ports**: `3300-3399` for application development
- **UDP**: `60000-60020` for specialized protocols

## GPU Support

### NVIDIA
- CUDA container toolkit for GPU acceleration
- Docker-in-docker GPU access support
- `nvidia-smi` available for monitoring

### Intel/AMD
- VAAPI drivers for hardware video acceleration
- Intel media drivers when available
- `vainfo` for capability inspection

## AI Coding Integration

The container includes multiple AI coding assistants. See [AGENTS.md](./AGENTS.md) for detailed configuration and usage.

## SSH Configuration

### Host Key Persistence
SSH host keys are generated once and persisted in a host-mounted volume. This prevents SSH client warnings on container rebuilds.

### Authentication
- **Key-based**: Authorized keys mounted from host
- **No passwords**: Password authentication disabled
- **Root access**: Full root shell access via SSH

## Shell Configuration

### System-Wide Setup
The container manages shell configuration through multiple layers:
1. **`/etc/container-bashrc`**: Core PATH and prompt settings
2. **`/etc/profile.d/container-env.sh`**: Login shell integration  
3. **`/etc/bash.bashrc`**: Interactive shell integration
4. **`BASH_ENV`**: Non-interactive shell support

### Persistent Elements
- Command history via mounted `.bash_history`
- User customizations can be added to mounted home directory
- Git configuration persists across rebuilds

## Sample Compose File

```yaml
services:
  code-server:
    build:
      context: .
      dockerfile: Dockerfile
    image: code-server:latest
    container_name: code-server
    hostname: dev-server
    user: root
    restart: unless-stopped

    environment:
      - GIT_USER=your-username
      - GIT_EMAIL=your@email.com
      - SERVER_DATA_DIR=/root/.vscode-server

    ports:
      - "8443:8443"
      - "2222:22"
      - "3300-3399:3300-3399"
      - "60000-60020:60000-60020/udp"

    volumes:
      - /path/to/home:/root
      - /path/to/ssh-keys:/etc/ssh/keys
      - ~/.ssh/authorized_keys:/etc/ssh/authorized_keys:ro
      - /var/run/docker.sock:/var/run/docker.sock

    # GPU support: NVIDIA
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

    # VAAPI (Intel/AMD hardware acceleration)
    devices:
      - /dev/dri:/dev/dri
```

## Troubleshooting

### SSH Host Key Changes
If you see SSH host key warnings:
```bash
ssh-keygen -R "[<your-ip>]:2222"
```

### Missing Tools in PATH
Verify container configuration is loading:
```bash
echo $PATH
source /etc/container-bashrc
```

### GPU Not Detected
Check GPU support:
```bash
nvidia-smi              # NVIDIA
vainfo                  # Intel/AMD
```

## Security Notes

- Container runs as root for development convenience
- SSH access uses key-based authentication only
- Docker socket mounted for container management
- Host filesystem partially accessible via mounts

## Backup Strategy

### Critical Persisted Data
- Home directory mount: All user data and history
- SSH keys mount: SSH host keys
- Projects mount: Source code and projects

### Rebuild Safety
The container can be rebuilt without data loss. All critical configuration and data persists on the host filesystem.
