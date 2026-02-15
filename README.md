# github-runner

Minimal, production-ready Docker Compose setup for running a self-hosted GitHub Actions runner on Linux and macOS hosts.

## Features

- Multi-architecture container support (`arm64`, `amd64`)
- Simple configuration through environment variables
- Graceful startup and shutdown handling
- Automatic runner deregistration on container exit
- Persistent runner work directory via named Docker volume

## Requirements

- Linux host (`arm64` or `amd64`) or macOS with Docker Desktop
- Docker Engine
- Docker Compose plugin (`docker compose`)

## Project Structure

```text
.
├── docker-compose.yml
├── .env.example
├── README.md
├── .gitignore
└── scripts/
    └── entrypoint.sh
```

## Setup

1. Copy the example environment file:

```bash
cp .env.example .env
```

2. Edit `.env` and set values for:

- `GITHUB_URL`
- `RUNNER_TOKEN`
- `RUNNER_NAME`
- `RUNNER_WORKDIR`
- `RUNNER_LABELS` (optional, comma-separated tags)
- `RUNNER_DIR` (optional, set only if auto-detection fails)

## Generate a Runner Token

1. Open your GitHub repository or organization settings.
2. Go to **Actions** -> **Runners**.
3. Click **New self-hosted runner**.
4. Generate a registration token.
5. Put the token into `RUNNER_TOKEN` in `.env`.

Note: Registration tokens are short-lived. Generate a new token if the previous one expires.

Labels note: use `RUNNER_LABELS` for custom runner tags, for example `github,arm64,prod`.
Runner path note: if the container logs `Runner directory not found`, set `RUNNER_DIR` (for example `/home/runner`).

## Start

```bash
docker compose up -d
```

## Stop

```bash
docker compose down
```

## Security

- Do not commit `.env`.
- Treat `RUNNER_TOKEN` as sensitive.
- Mounting `/var/run/docker.sock` gives workflows broad access to the host. Use only in trusted environments.

## Platform Notes

- On Linux, the runner uses the host Docker engine through `/var/run/docker.sock`.
- On macOS, the container runs inside Docker Desktop's Linux VM and uses Docker Desktop's socket.

## Example Usage

After starting the stack, trigger a workflow in the configured repository. In your workflow file:

```yaml
jobs:
  build:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - run: uname -a
```
