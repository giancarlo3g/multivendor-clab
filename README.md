# Multivendor EVPN/VXLAN Lab

A [ContainerLab](https://containerlab.dev/) topology that demonstrates **L2 EVPN/VXLAN interoperability** across four different network operating systems in a 2-tier CLOS fabric.

## Topology

![Topology](img/topology.png)

### Nodes

| Node | Role | NOS | Image |
|------|------|-----|-------|
| `sros` | Spine / Route Reflector | Nokia SROS 25.10.R2 | nokia_srsim:25.10.R2 |
| `ptx-gw` | Spine / DC Gateway | Juniper cJunos Evolved | juniper_cjunosevolved:25.4R1.13-EVO |
| `srl` | Leaf | Nokia SR Linux 25.10.1 | ghcr.io/nokia/srlinux:25.10.1 |
| `ceos` | Leaf | Arista EOS 4.34.2F | arista_ceos:4.34.2F |
| `ptx` | Leaf | Juniper cJunos Evolved | juniper_cjunosevolved:25.4R1.13-EVO |
| `sonic` | Leaf | SONiC (FRR-based control plane) | sonic_sonic-vs:2026 |
| `frr` | Leaf (FRR router) | FRRouting | frrouting/frr:latest |
| `client-{1,2,3,4,5}` | Hosts | Linux | ghcr.io/hellt/network-multitool:latest |

> **Note:** The `sonic_sonic-vs:2026` and `frrouting/frr:latest` image tags don't pin an exact software version — confirm what's actually running with `show version`:
>
> ```
> admin@sonic:~$ show version
> 
> SONiC Software Version: SONiC.master.1127735-b93b9f586
> SONiC OS Version: 13
> Distribution: Debian 13.5
> Kernel: 6.12.41+deb13-sonic-amd64
> Build commit: b93b9f586
> Build date: Mon Jun  1 17:33:27 UTC 2026
> Built by: azureuser@b509c9bcc000000
> 
> Platform: x86_64-kvm_x86_64-r0
> HwSKU: Force10-S6000
> ASIC: vs
> ASIC Count: 1
> Serial Number: N/A
> Model Number: N/A
> Hardware Revision: N/A
> Uptime: 16:31:52 up 15 min,  2 users,  load average: 0.05, 0.31, 0.60
> Date: Mon 13 Jul 2026 16:31:52
> 
> Docker images:
> REPOSITORY                    TAG                        IMAGE ID       SIZE
> docker-sonic-bmp              latest                     324fc00eb8f5   291MB
> docker-sonic-bmp              master.1127735-b93b9f586   324fc00eb8f5   291MB
> docker-gnmi-sidecar           latest                     486c45d730c6   290MB
> docker-gnmi-sidecar           master.1127735-b93b9f586   486c45d730c6   290MB
> docker-fpm-frr                latest                     501ef6973ea7   392MB
> docker-fpm-frr                master.1127735-b93b9f586   501ef6973ea7   392MB
> docker-gnmi-watchdog          latest                     49183a73f12c   295MB
> docker-gnmi-watchdog          master.1127735-b93b9f586   49183a73f12c   295MB
> docker-dhcp-relay             latest                     798631ac6c57   332MB
> docker-dhcp-relay             master.1127735-b93b9f586   798631ac6c57   332MB
> docker-dash-ha                latest                     af398cdbab81   349MB
> docker-dash-ha                master.1127735-b93b9f586   af398cdbab81   349MB
> docker-sonic-otel             latest                     c0276eac6b44   632MB
> docker-sonic-otel             master.1127735-b93b9f586   c0276eac6b44   632MB
> docker-platform-monitor       latest                     5c93162dabc1   409MB
> docker-platform-monitor       master.1127735-b93b9f586   5c93162dabc1   409MB
> docker-restapi-sidecar        latest                     cc8c0781933d   290MB
> docker-restapi-sidecar        master.1127735-b93b9f586   cc8c0781933d   290MB
> docker-router-advertiser      latest                     0f8b4163a879   290MB
> docker-router-advertiser      master.1127735-b93b9f586   0f8b4163a879   290MB
> docker-sonic-mgmt-framework   latest                     58a203d4f9aa   353MB
> docker-sonic-mgmt-framework   master.1127735-b93b9f586   58a203d4f9aa   353MB
> docker-sysmgr                 latest                     86fbd71c71c8   295MB
> docker-sysmgr                 master.1127735-b93b9f586   86fbd71c71c8   295MB
> docker-snmp                   latest                     01a448fd133a   316MB
> docker-snmp                   master.1127735-b93b9f586   01a448fd133a   316MB
> docker-dash-engine            latest                     bc16e8cd7a6e   598MB
> docker-dash-engine            master.1127735-b93b9f586   bc16e8cd7a6e   598MB
> docker-sflow                  latest                     20d256bfaa5c   330MB
> docker-sflow                  master.1127735-b93b9f586   20d256bfaa5c   330MB
> docker-macsec                 latest                     395453c3ed3a   332MB
> docker-macsec                 master.1127735-b93b9f586   395453c3ed3a   332MB
> docker-orchagent              latest                     ecb086ff04f4   345MB
> docker-orchagent              master.1127735-b93b9f586   ecb086ff04f4   345MB
> docker-eventd                 latest                     45b0c115a4c8   290MB
> docker-eventd                 master.1127735-b93b9f586   45b0c115a4c8   290MB
> docker-bmp-watchdog           latest                     b062b0ddff75   288MB
> docker-bmp-watchdog           master.1127735-b93b9f586   b062b0ddff75   288MB
> docker-mux                    latest                     96e6fa83a03f   304MB
> docker-mux                    master.1127735-b93b9f586   96e6fa83a03f   304MB
> docker-lldp                   latest                     0cccbf0c0890   299MB
> docker-lldp                   master.1127735-b93b9f586   0cccbf0c0890   299MB
> docker-teamd                  latest                     908f944f4813   329MB
> docker-teamd                  master.1127735-b93b9f586   908f944f4813   329MB
> docker-database               latest                     e05365958bd4   297MB
> docker-database               master.1127735-b93b9f586   e05365958bd4   297MB
> docker-nat                    latest                     fa19d5ed6b47   332MB
> docker-nat                    master.1127735-b93b9f586   fa19d5ed6b47   332MB
> docker-sonic-gnmi             latest                     88c262596685   436MB
> docker-sonic-gnmi             master.1127735-b93b9f586   88c262596685   436MB
> docker-gbsyncd-vs             latest                     204b9b283751   2.19GB
> docker-gbsyncd-vs             master.1127735-b93b9f586   204b9b283751   2.19GB
> docker-syncd-vs               latest                     473266185c55   2.19GB
> docker-syncd-vs               master.1127735-b93b9f586   473266185c55   2.19GB
> ```
>
> ```
> frr# show version 
> FRRouting 10.8.0-dev_git350585613289 (frr) on Linux(5.15.0-157-generic).
> Copyright 1996-2005 Kunihiro Ishiguro, et al.
> configured with:
>     '--prefix=/usr' '--sysconfdir=/etc' '--localstatedir=/var' '--sbindir=/usr/lib/frr' '--libdir=/usr/lib' '--enable-rpki' '--enable-vtysh' '--enable-multipath=64' '--enable-vty-group=frrvty' '--enable-user=frr' '--enable-group=frr' '--enable-pcre2posix' '--enable-scripting' 'CC=cc' 'CXX=c++'
> ```

### Links

Each leaf has a full-mesh uplink to both spines. Clients connect to their respective leaf on access (trunk) ports:

| Link | Interface A | Interface B |
|------|-------------|-------------|
| sros → srl | 1/1/c1/1 | e1-2 |
| sros → ceos | 1/1/c2/1 | eth2 |
| sros → ptx | 1/1/c3/1 | eth2 |
| ptx-gw → srl | eth1 | e1-3 |
| ptx-gw → ceos | eth2 | eth3 |
| ptx-gw → ptx | eth3 | eth3 |
| srl → client-1 | e1-1 | eth1 |
| ceos → client-2 | eth1 | eth1 |
| ptx → client-3 | eth1 | eth1 |
| sros → sonic | 1/1/c4/1 | eth1 |
| ptx-gw → sonic | eth7 | eth2 |
| sros → frr | 1/1/c5/1 | eth1 |
| ptx-gw → frr | eth8 | eth2 |
| sonic → client-4 | eth3 | eth1 |
| frr → client-5 | eth3 | eth1 |

## Protocols

### Underlay — OSPF

All fabric interfaces (dot1q VLAN 1) and loopbacks run **OSPFv2 area 0**, point-to-point. MTU is set to 9194 / 9172 bytes on fabric links.

| Node | Loopback / System IP |
|------|---------------------|
| sros | 192.1.2.1/32 |
| ptx-gw | 192.1.2.2/32 |
| srl | 192.1.1.1/32 |
| ceos | 192.1.1.2/32 |
| ptx | 192.1.1.3/32 |
| sonic | 192.1.1.4/32 |
| frr | 192.1.1.5/32 |

### Overlay — BGP EVPN / VXLAN

| Parameter | Value |
|-----------|-------|
| BGP AS | 65000 (iBGP) |
| Route Reflector | `sros` (cluster-id 192.1.2.1) |
| EVPN mode | VLAN-aware bundle |
| VLAN | 10 |
| VNI | 1010 |
| EVI | 10 |
| Route-target | `target:65000:10` |
| EVPN eth-tag | 1010 |

All leaf VTEP IPs are their loopback addresses. EVPN type-2 (MAC/IP) and type-3 (IMET) routes are exchanged via iBGP.

### Clients

Clients are configured with a VLAN 10 sub-interface and assigned addresses in `192.168.10.0/24`:

| Client | VLAN | IP | MAC |
|--------|------|----|-----|
| client-1 | 10 | 192.168.10.11/24 | 00:c1:ab:00:00:01 |
| client-2 | 10 | 192.168.10.12/24 | 00:c1:ab:00:00:02 |
| client-3 | 10 | 192.168.10.13/24 | 00:c1:ab:00:00:03 |
| client-4 | 10 | 192.168.10.14/24 | 00:c1:ab:00:00:04 |
| client-5 | 10 | 192.168.10.15/24 | 00:c1:ab:00:00:05 |

## Requirements

- [ContainerLab](https://containerlab.dev/install/) installed on the host
- Docker with sufficient resources (RAM-heavy: SROS and Juniper nodes each need several GB)
- Nokia SRSIM license file at `../license-srsim25.txt` (one directory above this repo)
- The following images imported locally (not auto-pulled):
  - `nokia_srsim:25.10.R2`
  - `arista_ceos:4.34.2F`
  - `juniper_cjunosevolved:25.4R1.13-EVO`
  - `docker-sonic-vs:latest` / `sonic_sonic-vs:2026` — download from [sonic.software](https://sonic.software/). SONiC-VS is a bare Docker image, not a container-network-node image, so it must be wrapped with [vrnetlab](https://github.com/hellt/vrnetlab) (the `sonic-vm`/`sonic-vs` builder) before ContainerLab can boot it as a node.
  - `frrouting/frr:latest` — download from [frrouting.org/release](https://frrouting.org/release/), or pull directly from Docker Hub.

## Deploying the lab

```bash
# Deploy
sudo clab deploy -t multivendor.clab.yml

# Redeploy from scratch (wipes node state)
sudo clab deploy -t multivendor.clab.yml --reconfigure

# Check running nodes and management IPs
sudo clab inspect -t multivendor.clab.yml

# Destroy
sudo clab destroy -t multivendor.clab.yml
```

## Post-deploy configuration

A few nodes are **not** fully configured by ContainerLab's `startup-config` mechanism and need manual steps after `clab deploy` finishes.

### SONiC (`mv-sonic`)

The `sonic-vm` kind only loads `config_db.json` on boot — interfaces, OSPF, and BGP/EVPN on the internal FRR control plane still need to be wired up. Run `startup_config/post-deploy-sonic.sh` once against the node's SSH target to inject an SSH key, configure interface IPs/MTUs, enable `ospfd`, and apply OSPF + BGP EVPN config via `vtysh`:

```bash
./startup_config/post-deploy-sonic.sh mv-sonic
```

The script is idempotent — safe to re-run against a node that's already configured.

### Juniper cJunos Evolved (`mv-ptx-gw` and `mv-ptx`)

The `ptx-gw` and `ptx` nodes have their `startup-config` entries commented out in `multivendor.clab.yml`, so `ptxgw.cfg` and `ptx.cfg` must be applied by hand after deploy. SSH into each node, enter configuration mode, and paste in the contents of the matching file:

```bash
# ptx-gw — paste the contents of startup_config/ptxgw.cfg
ssh admin@mv-ptx-gw
configure
<paste contents of startup_config/ptxgw.cfg>
commit

# ptx — paste the contents of startup_config/ptx.cfg
ssh admin@mv-ptx
configure
<paste contents of startup_config/ptx.cfg>
commit
```

## Accessing nodes

| Node | Management IP | Credentials |
|------|--------------|-------------|
| mv-sros | 172.20.20.34 | admin / NokiaSros1! |
| mv-ptx-gw | 172.20.20.10 | admin / admin@123 |
| mv-srl | 172.20.20.35 | admin / NokiaSrl1! |
| mv-ceos | 172.20.20.7 | admin / admin |
| mv-ptx | 172.20.20.8 | admin / admin@123 |
| mv-sonic | 172.20.20.17 | admin / admin |
| mv-frr | — (shell access only, see below) | — |

> **Note:** Management IPs are assigned by ContainerLab and may differ between deployments. Always verify with `clab inspect`.

```bash
# SSH into any node
ssh admin@<Node>

# SR Linux — alternative via Docker
docker exec -it mv-srl sr_cli

# SONiC — ssh in, then configure interfaces from bash or drop into vtysh for routing
ssh admin@mv-sonic
vtysh

# FRR — no SSH; get a shell via Docker, then vtysh for routing config
docker exec -it mv-frr sh
vtysh
```

## Verifying the lab

### Check OSPF neighbors (on sros)
```
show router ospf neighbor
```

### Check BGP EVPN sessions (on sros)
```
show router bgp neighbor
```

### Check EVPN routes (on srl)
```
show network-instance default protocols bgp routes evpn
```

### Ping between clients
```bash
# From client-1
docker exec mv-client-1 ping 192.168.10.12 -c 3   # → client-2 via ceos
docker exec mv-client-1 ping 192.168.10.13 -c 3   # → client-3 via ptx
```

### Expected output — all sessions up (on `mv-sros`)

Once the underlay and overlay are up (including the post-deploy steps above), `sros` should show a full OSPF adjacency and iBGP EVPN session to every other node in the fabric. Sample output — replace with the real output from your own deployment:

```
A:admin@sros# show router ospf neighbor 

===============================================================================
Rtr Base OSPFv2 Instance 0 Neighbors
===============================================================================
Interface-Name                   Rtr Id          State      Pri  RetxQ   TTL
   Area-Id
-------------------------------------------------------------------------------
to_ceos                          192.1.1.2       Full       0    0       31
   0.0.0.0
to_frr                           192.1.1.5       Full       1    0       37
   0.0.0.0
to_ptx                           192.1.1.3       Full       128  0       30
   0.0.0.0
to_sonic                         192.1.1.4       Full       1    0       32
   0.0.0.0
to_srl                           192.1.1.1       Full       1    1       35
   0.0.0.0
-------------------------------------------------------------------------------
No. of Neighbors: 5
===============================================================================
```

```
A:admin@sros# show router bgp summary
===============================================================================
 BGP Router ID:192.1.2.1        AS:65000       Local AS:65000      
===============================================================================
BGP Admin State         : Up          BGP Oper State              : Up
Total Peer Groups       : 1           Total Peers                 : 5         
Total VPN Peer Groups   : 0           Total VPN Peers             : 0         
Current Internal Groups : 1           Max Internal Groups         : 1         
Total BGP Paths         : 35          Total Path Memory           : 12944     
Memory Failures         : 0           Label Failures              : 0         
Next Hop Failures       : 0           Backup Path Failures        : 0         
Tunnel Failures         : 0           Tunnel Next Hop Failures    : 0         
 
Total IPv4 Remote Rts   : 0           Total IPv4 Rem. Active Rts  : 0         
Total IPv6 Remote Rts   : 0           Total IPv6 Rem. Active Rts  : 0         
Total IPv4 Backup Rts   : 0           Total IPv6 Backup Rts       : 0         
Total LblIpv4 Rem Rts   : 0           Total LblIpv4 Rem. Act Rts  : 0         
Total LblIpv6 Rem Rts   : 0           Total LblIpv6 Rem. Act Rts  : 0         
Total LblIpv4 Bkp Rts   : 0           Total LblIpv6 Bkp Rts       : 0          
Total Supressed Rts     : 0           Total Hist. Rts             : 0         
Total Decay Rts         : 0         
 
Total VPN-IPv4 Rem. Rts : 0           Total VPN-IPv4 Rem. Act. Rts: 0         

Total VPN-IPv6 Rem. Rts : 0           Total VPN-IPv6 Rem. Act. Rts: 0         
Total VPN-IPv4 Bkup Rts : 0           Total VPN-IPv6 Bkup Rts     : 0         
Total VPN Local Rts     : 0           Total VPN Supp. Rts         : 0         
Total VPN Hist. Rts     : 0           Total VPN Decay Rts         : 0         
 
Total MVPN-IPv4 Rem Rts : 0           Total MVPN-IPv4 Rem Act Rts : 0         
Total MVPN-IPv6 Rem Rts : 0           Total MVPN-IPv6 Rem Act Rts : 0         
Total MDT-SAFI Rem Rts  : 0           Total MDT-SAFI Rem Act Rts  : 0         
Total McIPv4 Remote Rts : 0           Total McIPv4 Rem. Active Rts: 0         
Total McIPv6 Remote Rts : 0           Total McIPv6 Rem. Active Rts: 0         
Total McVpnIPv4 Rem Rts : 0           Total McVpnIPv4 Rem Act Rts : 0         
Total McVpnIPv6 Rem Rts : 0           Total McVpnIPv6 Rem Act Rts : 0         
 
Total EVPN Rem Rts      : 2           Total EVPN Rem Act Rts      : 0         
Total L2-VPN Rem. Rts   : 0           Total L2VPN Rem. Act. Rts   : 0         
Total MSPW Rem Rts      : 0           Total MSPW Rem Act Rts      : 0         
Total RouteTgt Rem Rts  : 0           Total RouteTgt Rem Act Rts  : 0         
Total FlowIpv4 Rem Rts  : 0           Total FlowIpv4 Rem Act Rts  : 0         
Total FlowIpv6 Rem Rts  : 0           Total FlowIpv6 Rem Act Rts  : 0         
Total FlowVpnv4 Rem Rts : 0           Total FlowVpnv4 Rem Act Rts : 0         
Total FlowVpnv6 Rem Rts : 0           Total FlowVpnv6 Rem Act Rts : 0         
Total Link State Rem Rts: 0           Total Link State Rem Act Rts: 0         
Total SrPlcyIpv4 Rem Rts: 0           Total SrPlcyIpv4 Rem Act Rts: 0         
Total SrPlcyIpv6 Rem Rts: 0           Total SrPlcyIpv6 Rem Act Rts: 0         

===============================================================================
BGP Summary
===============================================================================
Legend : D - Dynamic Neighbor
===============================================================================
Neighbor
Description
                   AS PktRcvd InQ  Up/Down   State|Rcv/Act/Sent (Addr Family)
                      PktSent OutQ
-------------------------------------------------------------------------------
192.1.1.1
                65000     120    0 00h54m30s 1/0/2 (Evpn)
                          127    0           
192.1.1.2
                65000     122    0 00h48m21s 1/0/2 (Evpn)
                          114    0           
192.1.1.3
                65000     113    0 00h50m06s 0/0/2 (Evpn)
                          118    0           
192.1.1.4
                65000     105    0 00h51m12s 0/0/2 (Evpn)
                          120    0           
192.1.1.5
                65000     112    0 00h54m30s 0/0/2 (Evpn)
                          127    0           
```

## Automation inventories

ContainerLab auto-generates two inventory files on deploy inside `clab-mv/`:

- `clab-mv/ansible-inventory.yml` — grouped by NOS, connection type pre-configured
- `clab-mv/nornir-simple-inventory.yml` — Nornir SimpleInventory format
