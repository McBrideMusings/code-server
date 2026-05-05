# Stable base matching repo selections
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Enable contrib and non-free repositories for additional packages (nvtop is in contrib)
RUN printf '%s\n' \
  'deb http://deb.debian.org/debian bookworm main contrib non-free-firmware' \
  'deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware' \
  'deb http://security.debian.org bookworm-security main contrib non-free-firmware' \
  > /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends locales mosh \
  && sed -i 's/^# *\(en_US.UTF-8\) UTF-8/\1 UTF-8/' /etc/locale.gen \
  && locale-gen \
  && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US:en \
  && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
  LC_ALL=en_US.UTF-8 \
  LANGUAGE=en_US:en

# SSH will use /etc/ssh/authorized_keys, so no need for /root/.ssh creation

# Configure ssh; host keys live under /etc/ssh/keys (persisted at runtime)
RUN mkdir -p /var/run/sshd /etc/ssh/sshd_config.d /etc/ssh/keys
RUN printf '%s\n' \
  'HostKey /etc/ssh/keys/ssh_host_ed25519_key' \
  'HostKey /etc/ssh/keys/ssh_host_rsa_key' \
  > /etc/ssh/sshd_config.d/20-hostkeys.conf

# ---- Base OS + build tools, SSH, editors ----
RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates curl wget gnupg \
  openssh-server \
  bubblewrap \
  mosh \
  git jq nano unzip vim zsh htop rsync tmux gh \
  nvtop intel-gpu-tools \
  build-essential pkg-config gcc g++ make \
  clang clangd lldb gdb ccache cmake ninja-build \
  python3 python3-pip python3-venv \
  php-cli php-common php-xml php-mbstring php-curl php-zip \
  libpam0g-dev \
  && rm -rf /var/lib/apt/lists/*

# Ensure Git initializes repos with main by default
RUN git config --global init.defaultBranch main
RUN git config --global --add safe.directory '*'

# ---- Zellij (manual install; not in Debian repos) ----
ARG ZELLIJ_VERSION=latest
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) targ_arch=x86_64 ;; \
    arm64) targ_arch=aarch64 ;; \
    *) echo "unsupported arch: $arch"; exit 1 ;; \
  esac; \
  if [ "$ZELLIJ_VERSION" = "latest" ]; then \
    url="https://github.com/zellij-org/zellij/releases/latest/download/zellij-${targ_arch}-unknown-linux-musl.tar.gz"; \
  else \
    url="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${targ_arch}-unknown-linux-musl.tar.gz"; \
  fi; \
  curl -fsSL "$url" -o /tmp/zellij.tgz; \
  tar -C /usr/local/bin -xzf /tmp/zellij.tgz zellij; \
  rm /tmp/zellij.tgz

# ---- GitUI (terminal UI for Git) ----
ARG GITUI_VERSION=latest
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) targ_arch=x86_64 ;; \
    arm64) targ_arch=aarch64 ;; \
    *) echo "unsupported arch: $arch"; exit 1 ;; \
  esac; \
  if [ "$GITUI_VERSION" = "latest" ]; then \
    url="https://github.com/gitui-org/gitui/releases/latest/download/gitui-linux-${targ_arch}.tar.gz"; \
  else \
    url="https://github.com/gitui-org/gitui/releases/download/v${GITUI_VERSION}/gitui-linux-${targ_arch}.tar.gz"; \
  fi; \
  curl -fsSL "$url" -o /tmp/gitui.tgz; \
  tar -C /usr/local/bin -xzf /tmp/gitui.tgz ./gitui; \
  rm /tmp/gitui.tgz

# ---- tsshd (UDP SSH server for roaming connections, like mosh but full SSH) ----
ARG TSSHD_VERSION=0.1.6
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) targ_arch=x86_64 ;; \
    arm64) targ_arch=aarch64 ;; \
    *) echo "unsupported arch: $arch"; exit 1 ;; \
  esac; \
  curl -fsSL "https://github.com/trzsz/tsshd/releases/download/v${TSSHD_VERSION}/tsshd_${TSSHD_VERSION}_linux_${targ_arch}.tar.gz" -o /tmp/tsshd.tgz; \
  tar -C /usr/local/bin --strip-components=1 -xzf /tmp/tsshd.tgz; \
  rm /tmp/tsshd.tgz

# ---- SSH daemon config for clean UTF-8 non-interactive sessions (required by mosh) ----
# Force UTF-8 and silence all banners/MOTD so the first line is "MOSH CONNECT ..."
RUN printf '%s\n' \
  'SetEnv LANG=C.UTF-8 LC_ALL=C.UTF-8' \
  'PrintMotd no' \
  'Banner none' \
  'PrintLastLog no' \
  'UsePAM no' \
  > /etc/ssh/sshd_config.d/99-mosh-locale.conf

# ---- Node.js (NodeSource LTS 22) + global tooling ----
RUN set -eux; \
  apt-get update; apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -; \
  apt-get install -y --no-install-recommends nodejs; \
  corepack enable; \
  npm i -g typescript eslint npm-check-updates; \
  rm -rf /var/lib/apt/lists/*

# ---- Bun (fast JS runtime, bundler, package manager) ----
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) bun_arch=x64 ;; \
    arm64) bun_arch=aarch64 ;; \
    *) echo "unsupported arch: $arch"; exit 1 ;; \
  esac; \
  curl -fsSL "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-${bun_arch}.zip" -o /tmp/bun.zip; \
  unzip -j /tmp/bun.zip "bun-linux-${bun_arch}/bun" -d /usr/local/bin; \
  chmod +x /usr/local/bin/bun; \
  rm /tmp/bun.zip; \
  bun --version

# ---- Playwright browser automation framework ----
# Install system dependencies for Playwright browsers (Chromium, Firefox, WebKit)
RUN apt-get update && apt-get install -y --no-install-recommends \
  # Core browser dependencies
  libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
  libdrm2 libdbus-1-3 libxkbcommon0 libxcomposite1 libxdamage1 \
  libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 \
  libasound2 libatspi2.0-0 libxshmfence1 \
  # X11 and rendering libraries
  libx11-6 libx11-xcb1 libxcb1 libxext6 libxcb-shm0 \
  # Font support (Debian Bookworm naming)
  fonts-liberation fonts-noto-color-emoji fonts-noto-cjk \
  # Media codecs and GTK
  libvpx7 libwebpdemux2 libwebp7 libenchant-2-2 libsecret-1-0 \
  libhyphen0 libgdk-pixbuf2.0-0 libgtk-3-0 libharfbuzz-icu0 \
  libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 \
  # Utilities
  xvfb \
  && rm -rf /var/lib/apt/lists/*

# Install Playwright globally with all browsers for quick testing
# Projects should still install Playwright locally via package.json for version control
RUN npm install -g playwright@latest && \
  playwright install chromium firefox webkit && \
  rm -rf /root/.cache/ms-playwright/ffmpeg*

# ---- Go toolchain + common tools for vscode-go ----
ARG GO_VERSION=1.24.2
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
  amd64) goarch=amd64 ;; \
  arm64) goarch=arm64 ;; \
  *) echo "unsupported arch: $arch"; exit 1 ;; \
  esac; \
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${goarch}.tar.gz" -o /tmp/go.tgz; \
  rm -rf /usr/local/go; \
  tar -C /usr/local -xzf /tmp/go.tgz; \
  ln -sf /usr/local/go/bin/* /usr/local/bin/; \
  rm /tmp/go.tgz

ENV GOPATH=/root/go
ENV CARGO_HOME=/usr/local/cargo \
  RUSTUP_HOME=/usr/local/rustup \
  PATH=/usr/local/cargo/bin:/usr/local/go/bin:/root/go/bin:$PATH

# Common Go tools used by vscode-go
RUN go version && \
  go install golang.org/x/tools/gopls@latest && \
  go install github.com/go-delve/delve/cmd/dlv@latest && \
  go install honnef.co/go/tools/cmd/staticcheck@latest

# ---- Rust toolchain + components ----
# CARGO_HOME and RUSTUP_HOME are set above to /usr/local paths so Rust survives home mount
RUN set -eux; \
  curl -fsSL https://sh.rustup.rs -o /tmp/rustup-init.sh; \
  chmod +x /tmp/rustup-init.sh; \
  /tmp/rustup-init.sh -y --default-toolchain stable --profile minimal --no-modify-path; \
  rm /tmp/rustup-init.sh; \
  rustup default stable; \
  rustup component add rustfmt clippy; \
  cargo --version

# ---- Docker CLI (talk to host via mounted /var/run/docker.sock) ----
RUN set -eux; \
  install -m 0755 -d /etc/apt/keyrings; \
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" \
  > /etc/apt/sources.list.d/docker.list; \
  apt-get update; \
  apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin; \
  rm -rf /var/lib/apt/lists/*

# ---- NVIDIA GPU support (nvidia-smi + container toolkit for docker-in-docker GPU access) ----
RUN set -eux; \
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg; \
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list; \
  apt-get update; \
  apt-get install -y --no-install-recommends nvidia-container-toolkit; \
  rm -rf /var/lib/apt/lists/*

# Enable NVIDIA capabilities (required for NVENC and nvidia-smi)
# - compute: CUDA compute
# - utility: nvidia-smi and other utilities
# - video: NVENC/NVDEC video encoding/decoding
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,video

# ---- VAAPI support (Intel/AMD hardware video acceleration) ----
# Install VAAPI packages with error handling - continue build even if some packages fail
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    vainfo \
    mesa-va-drivers \
    libva-drm2 \
    libva2 || true; \
  # Try to install Intel drivers separately (may not be available in all repos)
  apt-get install -y --no-install-recommends \
    intel-media-va-driver \
    i965-va-driver || echo "Intel VA drivers not available, continuing without them"; \
  rm -rf /var/lib/apt/lists/*

# ---- FFmpeg (BtbN master-latest static GPL build — libvmaf + NVENC + full codec suite) ----
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) btbn_arch=linux64 ;; \
    arm64) btbn_arch=linuxarm64 ;; \
    *) echo "unsupported arch: $arch"; exit 1 ;; \
  esac; \
  curl -fsSL "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-${btbn_arch}-gpl.tar.xz" -o /tmp/ffmpeg.tar.xz; \
  tar -xJf /tmp/ffmpeg.tar.xz -C /tmp/ --strip-components=2 \
    --wildcards "*/bin/ffmpeg" "*/bin/ffprobe"; \
  mv /tmp/ffmpeg /usr/local/bin/ffmpeg; \
  mv /tmp/ffprobe /usr/local/bin/ffprobe; \
  chmod +x /usr/local/bin/ffmpeg /usr/local/bin/ffprobe; \
  rm /tmp/ffmpeg.tar.xz

# ---- Microsoft VS Code repo + VS Code (provides `code`) ----
RUN set -eux; \
  install -m 0755 -d /etc/apt/keyrings; \
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg; \
  chmod 644 /etc/apt/keyrings/microsoft.gpg; \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  > /etc/apt/sources.list.d/vscode.list; \
  apt-get update; \
  apt-get install -y --no-install-recommends code; \
  rm -rf /var/lib/apt/lists/*

# ---- LLM Coding Tools ----
# Use system location for pnpm to survive home directory mount
ENV PNPM_HOME=/usr/local/share/pnpm
ENV PATH="$PNPM_HOME:$PATH"

RUN npm install -g @openai/codex
RUN npm install -g @google/gemini-cli
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    mv ~/.local/bin/claude /usr/local/bin/claude

# Container-managed bash configuration (survives home directory mount)
RUN printf '%s\n' \
  '# Container-managed environment' \
  'export PATH="/root/.local/bin:/usr/local/cargo/bin:/usr/local/go/bin:/root/go/bin:$PATH"' \
  'export PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' \
  '# Ensure Rust toolchain is configured' \
  'rustup default stable >/dev/null 2>&1 || true' \
  > /etc/container-bashrc

# Also put in profile.d for login shells (SSH)
RUN cp /etc/container-bashrc /etc/profile.d/container-env.sh

# Force it into bash.bashrc for all bash sessions
RUN cat /etc/container-bashrc >> /etc/bash.bashrc

# Set BASH_ENV so all bash shells source container config first
ENV BASH_ENV="/etc/container-bashrc"

# ---- VS Code remote helpers (code / codeweb aliases) ----
# Loaded only for interactive shells (profile.d + bash.bashrc), NOT via BASH_ENV,
# so the startup script's `code serve-web` still reaches the real binary.
COPY scripts/vscode-remote.sh /etc/vscode-remote.sh
RUN cp /etc/vscode-remote.sh /etc/profile.d/vscode-remote.sh && \
    cat /etc/vscode-remote.sh >> /etc/bash.bashrc

# Validate LLM tool installations
RUN echo "=== Validating LLM Tool Installations ===" && \
    echo "Checking codex..." && \
    (which codex && echo "✓ codex found in PATH" || echo "✗ codex NOT found in PATH") && \
    echo "Checking gemini..." && \
    (which gemini && echo "✓ gemini found in PATH" || echo "✗ gemini NOT found in PATH") && \
    echo "Checking claude..." && \
    (which claude && echo "✓ claude found in PATH" || echo "✗ claude NOT found in PATH") && \
    echo "Current PATH: $PATH" && \
    echo "Searching for missing binaries..." && \
    (find /usr /home /root /opt -name "codex" -type f 2>/dev/null | head -3 || echo "codex binary not found anywhere") && \
    (find /usr /home /root /opt -name "gemini" -type f 2>/dev/null | head -3 || echo "gemini binary not found anywhere") && \
    (find /usr /home /root /opt -name "claude" -type f 2>/dev/null | head -3 || echo "claude binary not found anywhere") && \
    echo "=== End Validation ==="

# Validate FFmpeg NVENC + libvmaf support
RUN echo "=== Validating FFmpeg Support ===" && \
    ffmpeg -version && \
    echo "Available NVENC encoders:" && \
    ffmpeg -encoders 2>/dev/null | grep nvenc && \
    echo "✓ NVENC support confirmed" && \
    echo "Checking libvmaf filter:" && \
    ffmpeg -filters 2>/dev/null | grep "libvmaf" && \
    echo "✓ libvmaf confirmed" && \
    echo "Checking NVIDIA video libraries (requires runtime with GPU access):" && \
    (ldconfig -p | grep libnvidia-encode || echo "⚠ NVIDIA video libraries not found - requires GPU runtime") && \
    echo "=== End FFmpeg Validation ==="

# Validate Playwright installation
RUN echo "=== Validating Playwright Installation ===" && \
    playwright --version && \
    echo "Installed browsers:" && \
    ls -la /root/.cache/ms-playwright/ && \
    echo "✓ Playwright configured successfully" && \
    echo "=== End Playwright Validation ==="

# Note: Shell configuration (.bashrc, .bash_profile) handled by mounted home directory
# /mnt/user/appdata/code-server/home:/root contains persistent shell config files

# Default bind host/port for code serve-web (overridable at runtime)
ENV HOST=0.0.0.0
ENV PORT=8443
ENV SHELL=/bin/bash

# ---- Custom scripts ----
COPY scripts/dmux /usr/local/bin/dmux
COPY scripts/dzellij /usr/local/bin/dzellij
RUN chmod +x /usr/local/bin/dmux
RUN chmod +x /usr/local/bin/dzellij

# ---- Startup script ----
COPY boot/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# ---- Extras (local-only, gitignored) ----
# Drop an extras.sh next to the Dockerfile to run arbitrary build steps.
# Copy extras.sh.example → extras.sh and customize it.
# Note: extras.sh.example must remain in the build context (not excluded by
# .dockerignore) so the glob always matches at least one file.
COPY extras.sh* /tmp/
RUN [ -f /tmp/extras.sh ] && bash /tmp/extras.sh || true

EXPOSE 8443 22
EXPOSE 17850 17851 17852 17853 17854
EXPOSE 3300-3399
EXPOSE 60000-60020/udp
USER root
ENTRYPOINT ["/usr/local/bin/start.sh"]
