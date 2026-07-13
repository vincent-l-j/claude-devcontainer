# Claude Code - Dev Container Setup

A secure, consistent environment for using Claude Code. Works on Windows and macOS.

---

## Prerequisites

Install these once on your machine.

**Required for everyone:**

| Tool | Download |
|------|----------|
| VS Code | https://code.visualstudio.com |
| VS Code Dev Containers extension | Search "Dev Containers" in VS Code Extensions, or: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers |

**Then choose one container runtime:**

### Option A — Docker Desktop

Download and install Docker Desktop: https://www.docker.com/products/docker-desktop

On **Windows**: make sure Docker Desktop is set to use WSL 2 (the default). You do not need to install WSL yourself.

### Option B — Rancher Desktop

Download and install Rancher Desktop: https://rancherdesktop.io — a free, open-source alternative to Docker Desktop, used here to avoid Docker Desktop's commercial license requirements for organizational use.

On first launch, in Rancher Desktop's preferences, set the **Container Engine** to **dockerd (moby)** (not `containerd`). This gives you a Docker-compatible engine and CLI, so no VS Code settings changes are needed — the Dev Containers extension detects it the same way it detects Docker Desktop.

> Podman was evaluated as an option here previously and dropped due to rootless/rootful file-ownership issues on macOS and Windows. See [`docs/why-not-podman.md`](docs/why-not-podman.md) if that history is useful context.

---

## Using the container

> **For each new folder you want to work in:** copy the `.devcontainer/` folder into it first.

1. Ensure your container runtime (Docker Desktop or Rancher Desktop) is running.
2. Open your working folder in VS Code (`File > Open Folder`).
3. Click **"Reopen in Container"** when prompted, or open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and run **Dev Containers: Reopen in Container**.
   - The first build takes a few minutes; subsequent opens are fast.
4. Run `claude` in the terminal to start.

---

## What is and isn't accessible inside the container

- **Only the folder you opened** is accessible inside the container. Claude cannot see other files on your machine.
- Organisation security settings are enforced via server-managed settings and cannot be changed.

### Network access

A firewall runs automatically on every container start and restricts outbound traffic to a fixed allowlist:

| Service | Purpose |
|---------|---------|
| `api.anthropic.com`, `platform.claude.com` | Claude Code |
| GitHub IP ranges | Git operations |
| `pypi.org`, `files.pythonhosted.org` | Python package installs (`pip`) |
| `registry.npmjs.org` | Node.js package installs (`npm`) |

All other outbound internet access is blocked. If a tool or script tries to reach an unlisted host it will be rejected immediately (ICMP admin-prohibited).

The `NET_ADMIN`/`NET_RAW` capabilities used by the firewall are scoped to the container's own network namespace and grant no privilege on your host.

### Included tooling

- **Node.js** (via the `node` dev container feature, installed through nvm) and **Python 3** are both preinstalled, so `npm` and `pip`/`python3` work out of the box against the allowlisted registries above.
- **zsh** (with the Powerlevel10k theme) is the default shell, in both the integrated VS Code terminal and any terminal you open.
- Common CLI utilities are included: `git`, `curl`, `jq`, `vim`, `nano`, `unzip`, `build-essential`.

### Persistent configuration

Claude's configuration and settings are stored in a named Docker volume (`devc-<folder-name>-config-<container-id>`), not inside the container filesystem. This means your Claude settings survive container rebuilds and image updates. Shell command history is similarly persisted in its own named volume, so it survives rebuilds too.

### Auto-updates and telemetry

`DISABLE_AUTOUPDATER=1` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` are set by default. Claude Code will not auto-update inside the container and non-essential network traffic (telemetry, update checks) is suppressed.

---

## For administrators

Organisation-level policy is enforced via server-managed settings in the Claude.ai admin console - these are fetched at login and cannot be overridden by users or project files.
