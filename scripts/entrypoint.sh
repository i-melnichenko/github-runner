#!/usr/bin/env bash
set -euo pipefail

resolve_runner_dir() {
  if [ -n "${RUNNER_DIR:-}" ]; then
    if [ -f "${RUNNER_DIR}/config.sh" ] && [ -f "${RUNNER_DIR}/run.sh" ]; then
      echo "$RUNNER_DIR"
      return 0
    fi
    echo "Configured RUNNER_DIR is invalid: ${RUNNER_DIR}" >&2
    return 1
  fi

  for candidate in \
    "/home/runner/actions-runner" \
    "/home/runner" \
    "/actions-runner" \
    "/opt/actions-runner"
  do
    if [ -f "${candidate}/config.sh" ] && [ -f "${candidate}/run.sh" ]; then
      echo "$candidate"
      return 0
    fi
  done

  echo "Runner directory not found. Set RUNNER_DIR explicitly." >&2
  return 1
}

RUNNER_DIR="$(resolve_runner_dir)"
cd "$RUNNER_DIR"

# Validate required runtime variables.
: "${GITHUB_URL:?GITHUB_URL is required}"
: "${RUNNER_TOKEN:?RUNNER_TOKEN is required}"
: "${RUNNER_NAME:?RUNNER_NAME is required}"
: "${RUNNER_WORKDIR:?RUNNER_WORKDIR is required}"

cleanup() {
  echo "Removing runner registration..."
  ./config.sh remove --unattended --token "$RUNNER_TOKEN" || true
}

shutdown() {
  echo "Received stop signal, shutting down runner..."
  if [ -n "${RUNNER_PID:-}" ] && kill -0 "$RUNNER_PID" 2>/dev/null; then
    kill -TERM "$RUNNER_PID" 2>/dev/null || true
    wait "$RUNNER_PID" 2>/dev/null || true
  fi
}

trap 'shutdown' SIGINT SIGTERM
trap 'cleanup' EXIT

# Ensure the work directory exists before starting.
mkdir -p "$RUNNER_WORKDIR"

# Remove stale registration if present from an unclean exit.
./config.sh remove --unattended --token "$RUNNER_TOKEN" >/dev/null 2>&1 || true

# Optional custom labels (tags), comma-separated.
LABEL_ARGS=()
if [ -n "${RUNNER_LABELS:-}" ]; then
  LABEL_ARGS=(--labels "$RUNNER_LABELS")
fi

# Register this runner instance.
./config.sh \
  --unattended \
  --url "$GITHUB_URL" \
  --token "$RUNNER_TOKEN" \
  --name "$RUNNER_NAME" \
  --work "$RUNNER_WORKDIR" \
  "${LABEL_ARGS[@]}" \
  --replace

# Start the runner in foreground and forward signals.
./run.sh &
RUNNER_PID=$!
wait "$RUNNER_PID"
