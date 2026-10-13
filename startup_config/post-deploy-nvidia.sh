#!/usr/bin/env bash
# post-deploy-nvidia.sh
# Usage: ./post-deploy-nvidia.sh [ssh-target]
# Example: ./post-deploy-nvidia.sh mv-nvidia
#
# Run this right after `clab deploy`. The nvidia_cumulusvx image ignores
# containerlab's startup-config, so this pushes nvidia_startup.cfg (NVUE
# `nv set` commands) over SSH and applies it.
# Idempotent: safe to re-run on a node that's already configured.

set -euo pipefail

NODE="${1:-mv-nvidia}"
USER_NAME="${NVIDIA_USER:-cumulus}"
PASSWORD="${NVIDIA_PASSWORD:-Clab123!}"
CFG="$(cd "$(dirname "$0")" && pwd)/nvidia_startup.cfg"

[[ -f "${CFG}" ]] || { echo "Config file not found: ${CFG}" >&2; exit 1; }

# No sshpass on the host: feed the password through SSH_ASKPASS instead.
ASKPASS="$(mktemp)"
trap 'rm -f "${ASKPASS}"' EXIT
printf "#!/bin/sh\necho '%s'\n" "${PASSWORD}" > "${ASKPASS}"
chmod 700 "${ASKPASS}"

nv_ssh() {
  SSH_ASKPASS="${ASKPASS}" SSH_ASKPASS_REQUIRE=force DISPLAY=:0 setsid \
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o PreferredAuthentications=password -o ConnectTimeout=10 \
        -o LogLevel=ERROR "${USER_NAME}@${NODE}" "$@"
}

echo ">>> Waiting for NVUE to be ready on ${NODE}"
for _ in $(seq 1 60); do
  if nv_ssh 'nv config show >/dev/null 2>&1' </dev/null 2>/dev/null; then
    break
  fi
  sleep 10
done
nv_ssh 'nv config show >/dev/null' </dev/null

echo ">>> Staging configuration from $(basename "${CFG}") on ${NODE}"
grep -E '^nv (set|unset) ' "${CFG}" | nv_ssh 'bash -s'

# Apply in its own session: `nv config apply` does not take effect when run
# from the piped script above.
echo ">>> Applying configuration on ${NODE}"
nv_ssh 'if [ -z "$(nv config diff)" ]; then
  nv config detach; echo "No changes, already configured"
else
  nv config apply -y 2>&1 | tr -d "\033" | tail -1; echo; nv config save >/dev/null
fi' </dev/null

echo ">>> Waiting for OSPF adjacencies on ${NODE}"
sleep 40
nv_ssh 'nv show vrf default router ospf neighbor' </dev/null

echo ">>> Verifying BGP neighbor state on ${NODE}"
nv_ssh 'nv show vrf default router bgp neighbor' </dev/null

echo ">>> Verifying VXLAN/EVPN state on ${NODE}"
nv_ssh 'nv show evpn vni 1010' </dev/null

echo ">>> Done with ${NODE}"
