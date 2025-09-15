# Stable base matching repo selections
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends locales mosh \
 && sed -i 's/^# *\(en_US.UTF-8\) UTF-8/\1 UTF-8/' /etc/locale.gen \
 && locale-gen \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US:en \
 && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

# Ensure root's home subdirs exist so bind-mounts have valid parents
RUN mkdir -p \
    /root/.ssh \
    /root/.config/code-server \
    /root/.local/share/code-server \
    /root/.codex \
    /root/.vscode/extensions \
    /root/.config/Code \
    /root/.local/share/Code \
 && chmod 700 /root/.ssh

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
    mosh \
    git nano unzip vim zsh htop rsync tmux gh \
    build-essential pkg-config gcc g++ make \
    python3 python3-pip python3-venv \
    php-cli php-common php-xml php-mbstring php-curl php-zip \
  && rm -rf /var/lib/apt/lists/*

# ---- SSH daemon config for clean UTF-8 non-interactive sessions (required by mosh) ----
# Force UTF-8 and silence all banners/MOTD so the first line is "MOSH CONNECT ..."
RUN printf '%s\n' \
  'SetEnv LANG=C.UTF-8 LC_ALL=C.UTF-8' \
  'PrintMotd no' \
  'Banner none' \
  'PrintLastLog no' \
  'UsePAM no' \
  > /etc/ssh/sshd_config.d/99-mosh-locale.conf

# Ensure .bashrc does nothing for non-interactive shells (no extra output)
RUN printf '%s\n' 'case $- in *i*) ;; *) return ;; esac' >> /root/.bashrc

# ---- Node.js (NodeSource LTS 20) + global tooling ----
RUN set -eux; \
  apt-get update; apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -; \
  apt-get install -y --no-install-recommends nodejs; \
  corepack enable; \
  npm i -g typescript eslint npm-check-updates; \
  rm -rf /var/lib/apt/lists/*

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
  rm /tmp/go.tgz

ENV GOPATH=/root/go
ENV PATH=/usr/local/go/bin:/root/go/bin:$PATH

# Common Go tools used by vscode-go
RUN go version && \
    go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest

# ---- Docker CLI (talk to host via mounted /var/run/docker.sock) ----
RUN set -eux; \
  install -m 0755 -d /etc/apt/keyrings; \
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" \
    > /etc/apt/sources.list.d/docker.list; \
  apt-get update; \
  apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin; \
  rm -rf /var/lib/apt/lists/*

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
RUN npm install -g @openai/codex
RUN npm install -g @anthropic-ai/claude-code

# Green prompt: root@host:/cwd#
RUN echo 'export PS1="\[\e[0;32m\]\u@\h:\w# \[\e[0m\]"' >> /root/.bashrc

# Default bind host/port for code serve-web (overridable at runtime)
ENV HOST=0.0.0.0
ENV PORT=8443

# ---- Startup script ----
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8443 22
EXPOSE 3300-3399
EXPOSE 60000-60020/udp
USER root
ENTRYPOINT ["/usr/local/bin/start.sh"]
