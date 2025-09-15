#!/usr/bin/env bash
set -euo pipefail
exec "./docker_build_run.sh" --config "profile.local.sh" "$@"

