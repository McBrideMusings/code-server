#!/bin/bash
# Build the code-server Docker image.
# If extras.sh is present, any directories listed in SOURCES are copied into
# the build context before building and cleaned up after.

set -euo pipefail

if [ -f extras.sh ]; then
  rm -rf tools/
  SOURCES=()
  eval "$(awk '/^SOURCES=\(/{found=1} found{print} /^\)/{found=0}' extras.sh)"
  if [ ${#SOURCES[@]} -gt 0 ]; then
    mkdir -p tools/
    for src in "${SOURCES[@]}"; do
      name="$(basename "$src")"
      echo "Copying local tool source: $name"
      cp -r "$src" "tools/$name"
    done
  fi
fi

echo "Building image..."
if ! docker build -t code-server:latest -f Dockerfile .; then
  rm -rf tools/
  echo "Error: Docker build failed!"
  exit 1
fi

rm -rf tools/
echo "Build complete."
