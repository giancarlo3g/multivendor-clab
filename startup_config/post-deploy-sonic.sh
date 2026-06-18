#!/usr/bin/env bash
# post-deploy-sonic.sh
# Usage: ./post-deploy-sonic.sh <ssh-target> 
# Example: ./post-deploy-sonic.sh mv-sonic
#
# Run this once per node, right after `clab deploy`.
# Idempotent: safe to re-run on a node that's already configured.

set -euo pipefail

NODE="${1:?Usage: $0 <ssh-target>}"

echo ">>> Injecting SSH key on ${NODE}"
ssh "${NODE}" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
cat ~/.ssh/id_rsa.pub | ssh "${NODE}" "cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

echo ">>> Configuring interfaces on ${NODE}"
ssh "${NODE}" bash -s << 'REMOTE_EOF'
set -e
sudo config interface ip add Ethernet0 101.1.4.0/31 2>/dev/null || true
sudo config interface mtu Ethernet0 9172
sudo config interface ip add Ethernet4 101.1.4.2/31 2>/dev/null || true
sudo config interface mtu Ethernet4 9172
sudo config interface ip add Loopback0 192.1.1.4/32 2>/dev/null || true
REMOTE_EOF

echo ">>> Enabling ospfd in FRR container on ${NODE}"
ssh "${NODE}" bash -s << 'REMOTE_EOF'
set -e
docker exec bgp bash -c '
  if ! grep -q "program:ospfd" /etc/supervisor/conf.d/supervisord.conf; then
    cat >> /etc/supervisor/conf.d/supervisord.conf << "EOF"

[program:ospfd]
command=/usr/lib/frr/ospfd -A 127.0.0.1
priority=4
autostart=true
autorestart=false
startsecs=0
stdout_logfile=NONE
stdout_syslog=true
stderr_logfile=NONE
stderr_syslog=true
dependent_startup=true
dependent_startup_wait_for=zebra:running
EOF
    supervisorctl reread
    supervisorctl update
  fi
'
sudo config save -y
REMOTE_EOF

echo ">>> Waiting for ospfd to come up"
sleep 3

echo ">>> Applying OSPF configuration via vtysh on ${NODE}"
ssh "${NODE}" bash -s << 'REMOTE_EOF'
vtysh << 'VTYSH_EOF'
configure
interface Ethernet0
ip ospf network point-to-point
exit
interface Ethernet4
ip ospf network point-to-point
exit
router ospf
ospf router-id 192.1.1.4
network 101.1.4.0/31 area 0
network 101.1.4.2/31 area 0
exit
exit
write memory
VTYSH_EOF
REMOTE_EOF

echo ">>> Verifying OSPF neighbor state on ${NODE}"
ssh "${NODE}" "docker exec bgp vtysh -c 'show ip ospf neighbor'"

echo ">>> Done with ${NODE}"