# Why this project doesn't use Podman

This project previously supported Podman as an alternative to Docker Desktop, to avoid Docker Desktop's commercial license requirements for organizational use. That path caused enough friction on macOS and Windows that it was dropped in favor of [Rancher Desktop](https://rancherdesktop.io), which is a free, open-source drop-in replacement for Docker Desktop and doesn't have this problem. This document keeps the rootless/rootful reasoning around for reference, in case Podman comes up again.

## Why rootless Podman fails

On macOS and Windows, Podman runs inside a Linux VM (`podman machine`). By default that machine is **rootless**, which breaks bind-mounted workspace files.

Under a rootless `podman machine`, the VM's virtiofs layer cannot map your host user (e.g. macOS uid `501`) into the container. Your host-created files (`.git`, project files) arrive owned by `65534` ("nobody"), which is **outside** the container's user-namespace range — so the container's `vscode` user can neither own nor `chown` them, and Git reports dubious-ownership errors. This is why an earlier rootless config leaned on `--userns=keep-id` and `idmap`: workarounds that still could not map the unmappable `65534` files.

## Why rootful Podman was the workaround, and why it wasn't good enough to keep

A **rootful** machine behaves much like Docker Desktop's VM: it runs the container as real root inside the VM, so host files arrive with mappable ownership and the container's `postCreateCommand` `chown` can take effect. That is why the Docker path worked out of the box and rootless Podman did not. Switching to rootful required a manual, one-time step on every machine:

```bash
podman machine stop
podman machine set --rootful
podman machine start
```

You could verify the workspace mounted with correct, mappable ownership by running:

```bash
podman run --rm -v "$PWD":/w docker.io/library/alpine ls -lan /w
```

Files should show a real uid (e.g. the host's `501`), **not** `65534`. Seeing `65534` meant the machine was still rootless.

Even rootful, one residual difference from Docker Desktop remained: Podman's virtiofs share refuses to let even container-root `chown` Mac-origin **read-only git objects** (`.git/objects/*`, mode `0444`) — a `chown -R /workspace` reports `Permission denied` on them. Docker Desktop's file-sharing layer fakes a successful chown; virtiofs does not. This was harmless (those objects are world-readable and git only ever *reads* existing objects), and the Podman devcontainer config ran the workspace chown fault-tolerantly (`; ... 2>/dev/null`) and relied on `git config --global --add safe.directory '*'` for the rest.

On native Linux, Podman has no VM and bind mounts work directly — no rootful step was needed there. The friction was macOS/Windows-only, but that's most of the user base, which is why Rancher Desktop replaced this option rather than keeping Podman as a documented path.