#!/usr/bin/env bash
set -euo pipefail
set -x

echo "Starting container (VS Code Web + SSH)"

# Must be root; sshd binds 22 and we write under /root
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Container not running as root (uid $(id -u)). Remove any --user override." >&2
  exit 1
fi

# Configure global git identity if provided
if command -v git >/dev/null 2>&1; then
  if [ -n "${GIT_USER:-}" ]; then
    git config --global user.name "${GIT_USER}"
  fi
  if [ -n "${GIT_EMAIL:-}" ]; then
    git config --global user.email "${GIT_EMAIL}"
  fi
fi

# Host keys: generate once into /etc/ssh/keys (persisted via volume)
mkdir -p /etc/ssh/keys
chmod 700 /etc/ssh/keys 2>/dev/null || true

if [ ! -f /etc/ssh/keys/ssh_host_ed25519_key ]; then
  ssh-keygen -t ed25519 -f /etc/ssh/keys/ssh_host_ed25519_key -N '' -C ''
fi
if [ ! -f /etc/ssh/keys/ssh_host_rsa_key ]; then
  ssh-keygen -t rsa -b 4096 -f /etc/ssh/keys/ssh_host_rsa_key -N '' -C ''
fi

# Permissions for private/public keys (sshd will refuse wrong perms)
chmod 600 /etc/ssh/keys/*_key 2>/dev/null || true
chmod 644 /etc/ssh/keys/*.pub 2>/dev/null || true
chown root:root /etc/ssh/keys/* 2>/dev/null || true

echo "SSH host key fingerprints:"
for f in /etc/ssh/keys/*.pub; do
  [ -f "$f" ] && ssh-keygen -lf "$f" || true
done

# Ensure SSH can use a bind-mounted authorized_keys without modifying host files
# - Do NOT chown/chmod authorized_keys (may be read-only or host-managed)
# - Relax StrictModes so sshd accepts host-managed permissions
mkdir -p /root/.ssh || true
chmod 700 /root/.ssh 2>/dev/null || true

# Configure sshd to not enforce strict permissions on user files
mkdir -p /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/10-auth.conf <<'EOF'
# Authentication policy
PermitRootLogin yes
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2
# Accept host-managed authorized_keys without strict permission checks
StrictModes no
EOF

# Fallback: if config.d includes are not supported, force StrictModes no in main config
if ! grep -qE '^[#[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config.d/\*\.conf' /etc/ssh/sshd_config 2>/dev/null; then
  echo 'StrictModes no' >>/etc/ssh/sshd_config
fi

# Validate sshd config; print diagnostics then start sshd in background
if ! /usr/sbin/sshd -t; then
  echo "ERROR: sshd configuration test failed" >&2
  exit 1
fi

mkdir -p /var/run/sshd
/usr/sbin/sshd -e

# VS Code Web
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8333}"

# Flags (arrays so empty ones don't add '')
declare -a TOKEN_FLAGS=()
declare -a VERBOSE_FLAG=()
declare -a LOG_LEVEL_FLAG=()
declare -a CLI_DATA_DIR_FLAG=()
declare -a SERVER_DATA_DIR_FLAG=()
declare -a SERVER_BASE_PATH_FLAG=()
declare -a SOCKET_PATH_FLAG=()

# Optional flags
if [ -n "${SERVER_DATA_DIR:-}" ]; then
  SERVER_DATA_DIR_FLAG=(--server-data-dir "${SERVER_DATA_DIR}")
else
  SERVER_DATA_DIR_FLAG=(--server-data-dir "/root/.vscode-server")
fi
if [ -n "${SERVER_BASE_PATH:-}" ]; then SERVER_BASE_PATH_FLAG=(--server-base-path "${SERVER_BASE_PATH}"); fi
if [ -n "${SOCKET_PATH:-}" ]; then SOCKET_PATH_FLAG=(--socket-path "${SOCKET_PATH}"); fi

# Token handling
if [ -n "${TOKEN_FILE:-}" ]; then
  TOKEN_FLAGS=(--connection-token-file "${TOKEN_FILE}")
elif [ -n "${TOKEN:-}" ]; then
  TOKEN_FLAGS=(--connection-token "${TOKEN}")
else
  TOKEN_FLAGS=(--without-connection-token)
fi

if [ "${VERBOSE:-false}" = "true" ]; then VERBOSE_FLAG=(--verbose); fi
if [ -n "${LOG_LEVEL:-}" ]; then LOG_LEVEL_FLAG=(--log "${LOG_LEVEL}"); fi
if [ -n "${CLI_DATA_DIR:-}" ]; then CLI_DATA_DIR_FLAG=(--cli-data-dir "${CLI_DATA_DIR}"); fi

CMD=( code serve-web
  --host "${HOST}"
  --port "${PORT}"
  --accept-server-license-terms
  "${SERVER_DATA_DIR_FLAG[@]}"
  "${SERVER_BASE_PATH_FLAG[@]}"
  "${SOCKET_PATH_FLAG[@]}"
  "${TOKEN_FLAGS[@]}"
  "${VERBOSE_FLAG[@]}"
  "${LOG_LEVEL_FLAG[@]}"
  "${CLI_DATA_DIR_FLAG[@]}"
)

echo "Executing: ${CMD[*]}"
exec "${CMD[@]}"
