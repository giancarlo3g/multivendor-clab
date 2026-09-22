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

echo ">>> Configuring VXLAN/VLAN dataplane on ${NODE}"
ssh "${NODE}" bash -s << 'REMOTE_EOF'
set -e
# Ethernet8 ships with a stray L3 IP from sonic-vs's default T2 template;
# it must be removed before the port can join a VLAN as an L2 member.
sudo config interface ip remove Ethernet8 10.0.0.4/31 2>/dev/null || true
sudo config vxlan add vtep1 192.1.1.4 2>/dev/null || true
sudo config vxlan evpn_nvo add nvo1 vtep1 2>/dev/null || true
sudo config vlan add 10 2>/dev/null || true
sudo config vxlan map add vtep1 10 1010 2>/dev/null || true
sudo config vlan member add 10 Ethernet8 2>/dev/null || true
sudo config save -y
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
network 192.1.1.4/32 area 0
exit
exit
write memory
VTYSH_EOF
REMOTE_EOF

echo ">>> Verifying OSPF neighbor state on ${NODE}"
ssh "${NODE}" "docker exec bgp vtysh -c 'show ip ospf neighbor'"

echo ">>> Applying BGP configuration via vtysh on ${NODE}"
ssh "${NODE}" bash -s << 'REMOTE_EOF'
vtysh << 'VTYSH_EOF'
configure
no router bgp 65100
router bgp 65000
neighbor 192.1.2.1 remote-as 65000
neighbor 192.1.2.2 remote-as 65000
address-family l2vpn evpn
neighbor 192.1.2.1 activate
neighbor 192.1.2.2 activate
advertise-all-vni
vni 1010
rd 10:4
route-target import 65000:10
route-target export 65000:10
exit-vni
exit
exit
exit
write memory
VTYSH_EOF
REMOTE_EOF

echo ">>> Verifying BGP neighbor state on ${NODE}"
ssh "${NODE}" "docker exec bgp vtysh -c 'show bgp summary'"

echo ">>> Verifying VXLAN/EVPN state on ${NODE}"
ssh "${NODE}" "sudo config vxlan list; docker exec bgp vtysh -c 'show bgp l2vpn evpn vni'"

echo ">>> Done with ${NODE}"