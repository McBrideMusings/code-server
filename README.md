# Code Server Development Container

A comprehensive development environment container based on Debian Bookworm with VS Code Server, SSH access, and extensive tooling for modern software development.

## Features

- **VS Code Server**: Web-based VS Code interface accessible via browser
- **SSH Access**: Full terminal access with persistent host keys
- **Multi-language Support**: Go, Rust, Node.js, Python, PHP, C/C++
- **AI Coding Tools**: Claude, OpenAI Codex, Gemini, OpenCode integration
- **GPU Support**: NVIDIA CUDA and Intel/AMD VAAPI hardware acceleration
- **Development Tools**: Docker, Git, tmux, zellij, and comprehensive build toolchain

## Quick Start

1. **Build and Run**:
   ```bash
   ./run-dev.sh
   ```

2. **Access Methods**:
   - **Web Interface**: `https://100.114.249.118:8443`
   - **SSH**: `ssh root@100.114.249.118 -p 2222`
   - **Local**: `https://localhost:9443` (with profile.local.sh)

## Architecture

### Volume Strategy
The container uses a hybrid mounting approach:
- **Full home persistence**: `/mnt/user/appdata/code-server/home:/root`
- **Symlinked workspaces**: Host directories symlinked into container home
- **System-wide configuration**: Shell/PATH managed by container, data persisted on host

### Configuration Sources
1. **Container-managed**: PATH, PS1, system tools (via `/etc/container-bashrc`)
2. **Host-persisted**: Bash history, git config, SSH keys, project files
3. **Hybrid**: Tool configurations that need both approaches

## Directory Structure

```
/root/                          # Mounted from host for persistence
├── projects/                   # → /mnt/user/storage/projects/
├── user-scripts/               # → /boot/config/plugins/user.scripts/scripts/
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

### Production (profile.dev.sh)
- **VS Code**: `100.114.249.118:8443`
- **SSH**: `100.114.249.118:2222`
- **Dev Ports**: `3300-3399` for application development
- **UDP**: `60000-60020` for specialized protocols

### Local Development (profile.local.sh)
- **VS Code**: `localhost:9443`
- Minimal port exposure for local testing

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
SSH host keys are generated once and persisted in `/mnt/user/appdata/code-server/ssh/`. This prevents SSH client warnings on container rebuilds.

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

## Customization

### Adding Tools
Add package installations to the appropriate section in `Dockerfile`:
```dockerfile
RUN apt-get install -y your-package
```

### Environment Variables
Set in the profile files:
```bash
ENVS=$(cat <<'EOF'
YOUR_VAR=value
EOF
)
```

### Volume Mounts
Add to profile `VOLUMES` section:
```bash
/host/path:/container/path
```

## Troubleshooting

### SSH Host Key Changes
If you see SSH host key warnings:
```bash
ssh-keygen -R "[100.114.249.118]:2222"
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
- `/mnt/user/appdata/code-server/home/`: All user data and history
- `/mnt/user/appdata/code-server/ssh/`: SSH host keys
- `/mnt/user/storage/projects/`: Source code and projects

### Rebuild Safety
The container can be rebuilt without data loss. All critical configuration and data persists on the host filesystem.