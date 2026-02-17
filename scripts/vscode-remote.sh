# VS Code Remote helpers — open files/folders on the Mac or in code-server web UI
# Note: This shadows the container's `code` binary in interactive shells.
# Use `command code` or `/usr/bin/code` to access the original VS Code CLI.

# Open file/folder in local VS Code on Mac via vscode:// URI scheme
# Requires VS Code + Remote-SSH extension on the Mac, plus Tailscale connectivity.
code() {
  local target="${1:-.}"
  local abs_path
  abs_path="$(realpath "$target" 2>/dev/null || echo "$target")"

  # Must match the Host entry in the Mac's ~/.ssh/config
  local remote_host
  remote_host="$(hostname)"

  local uri="vscode://vscode-remote/ssh-remote+${remote_host}${abs_path}"

  echo "Opening: $uri"

  # Send the open command to the Mac over Tailscale
  if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    pierce@100.94.40.126 "open '$uri'" 2>/dev/null; then
    echo "Failed to reach Mac at 100.94.40.126. Falling back to printing URI:"
    echo "$uri"
  fi
}

# Open file/folder in code-server web UI
codeweb() {
  local target="${1:-.}"
  local abs_path
  abs_path="$(realpath "$target" 2>/dev/null || echo "$target")"

  local url="https://code.pierceserver.com/?folder=${abs_path}"
  echo "$url"
}
