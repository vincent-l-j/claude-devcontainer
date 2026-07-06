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

### Option B — Podman

Install Podman via your package manager or Podman Desktop: https://podman.io

Then tell VS Code to use Podman instead of Docker. Add this to your VS Code `settings.json` (`Ctrl+Shift+P` → "Open User Settings (JSON)"):

```json
"dev.containers.dockerPath": "podman"
```

Alternatively, open VS Code Settings (`Ctrl+,` / `Cmd+,`) and set **Dev > Containers: Docker Path** to `podman`.

#### Required on macOS: make the Podman machine rootful

On macOS (and Windows), Podman runs inside a Linux VM (`podman machine`). By default that machine is **rootless**, which breaks bind-mounted workspace files — see [Why rootless fails](#why-rootless-fails) below. Switch the machine to rootful **once** before opening the container:

```bash
podman machine stop
podman machine set --rootful
podman machine start
```

You can verify the workspace mounts with correct, mappable ownership by running:

```bash
podman run --rm -v "$PWD":/w docker.io/library/alpine ls -lan /w
```

Your files should show a real uid (e.g. your host `501`), **not** `65534`. If you see `65534`, the machine is still rootless.

On native Linux, Podman has no VM and bind mounts work directly — no rootful step is needed.

#### Why rootless fails

Under a rootless `podman machine`, the VM's virtiofs layer cannot map your host user (e.g. macOS uid `501`) into the container. Your host-created files (`.git`, project files) arrive owned by `65534` ("nobody"), which is **outside** the container's user-namespace range — so the container's `vscode` user can neither own nor `chown` them, and Git reports dubious-ownership errors. This is why the earlier rootless config leaned on `--userns=keep-id` and `idmap`: workarounds that still could not map the unmappable `65534` files.

A **rootful** machine behaves much like Docker Desktop's VM: it runs the container as real root inside the VM, so host files arrive with mappable ownership and the container's `postCreateCommand` `chown` can take effect. That is why the Docker path worked out of the box and rootless Podman did not.

One residual difference from Docker Desktop remains, and the Podman config accounts for it: Podman's virtiofs share refuses to let even container-root `chown` your Mac-origin **read-only git objects** (`.git/objects/*`, mode `0444`) — a `chown -R /workspace` will report `Permission denied` on them. Docker Desktop's file-sharing layer fakes a successful chown; virtiofs does not. This is harmless — those objects are world-readable and git only ever *reads* existing objects — so `podman/devcontainer.json` runs the workspace chown fault-tolerantly (`; ... 2>/dev/null`) and relies on `git config --global --add safe.directory '*'` for the rest. The files that git actually needs to write (config, index, refs, working tree) are not read-only and chown normally.

The `NET_ADMIN`/`NET_RAW` capabilities used by the firewall are scoped to the container's own network namespace and grant no privilege on your host.

---

## Using the container

> **For each new folder you want to work in:** copy the `.devcontainer/` folder into it first.

1. Ensure your container runtime (Docker or Podman) is running.
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

All other outbound internet access is blocked. If a tool or script tries to reach an unlisted host it will be rejected immediately (ICMP admin-prohibited).

### Persistent configuration

Claude's configuration and settings are stored in a named Docker volume (`claude-code-config-<id>`), not inside the container filesystem. This means your Claude settings survive container rebuilds and image updates.

### Auto-updates and telemetry

`DISABLE_AUTOUPDATER=1` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` are set by default. Claude Code will not auto-update inside the container and non-essential network traffic (telemetry, update checks) is suppressed.

---

## For administrators

Organisation-level policy is enforced via server-managed settings in the Claude.ai admin console - these are fetched at login and cannot be overridden by users or project files.
