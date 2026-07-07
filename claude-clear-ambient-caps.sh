# Claude Code's sandbox uses bubblewrap (bwrap), which refuses to run as a
# non-root process that holds permitted capabilities and dies with:
#   "bwrap: Unexpected capabilities but not setuid, old file caps config?"
#
# Some runtimes (notably rootful Podman) copy the container's --cap-add caps
# (NET_ADMIN/NET_RAW, needed by init-firewall.sh) into the non-root user's
# AMBIENT set, so the vscode shell -> claude -> bwrap all inherit them.
# Wrap `claude` so it launches with the ambient set cleared and bwrap starts
# capability-free. Root's bounding caps are untouched, so the sudo firewall
# still works. On Docker (no ambient caps on the user) this is a no-op.
if command -v setpriv >/dev/null 2>&1 \
   && [ -r /proc/self/status ] \
   && [ "$(awk '/^CapAmb:/{print $2}' /proc/self/status)" != 0000000000000000 ]; then
    # `env claude` resolves the real binary via PATH (env ignores shell
    # functions), so there is no recursion back into this wrapper.
    claude() { setpriv --ambient-caps=-all env claude "$@"; }
fi
