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
| `client-{1,2,3}` | Hosts | Linux | ghcr.io/hellt/network-multitool:latest |

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

## Requirements

- [ContainerLab](https://containerlab.dev/install/) installed on the host
- Docker with sufficient resources (RAM-heavy: SROS and Juniper nodes each need several GB)
- Nokia SRSIM license file at `../license-srsim25.txt` (one directory above this repo)
- The following images imported locally (not auto-pulled):
  - `nokia_srsim:25.10.R2`
  - `arista_ceos:4.34.2F`
  - `juniper_cjunosevolved:25.4R1.13-EVO`

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

## Accessing nodes

| Node | Management IP | Credentials |
|------|--------------|-------------|
| sros | 172.20.20.34 | admin / NokiaSros1! |
| ptx-gw | 172.20.20.10 | admin / admin@123 |
| srl | 172.20.20.35 | admin / NokiaSrl1! |
| ceos | 172.20.20.7 | admin / admin |
| ptx | 172.20.20.8 | admin / admin@123 |

> **Note:** Management IPs are assigned by ContainerLab and may differ between deployments. Always verify with `clab inspect`.

```bash
# SSH into any node
ssh admin@172.20.20.34

# SR Linux — alternative via Docker
docker exec -it mv-srl sr_cli
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

## Automation inventories

ContainerLab auto-generates two inventory files on deploy inside `clab-mv/`:

- `clab-mv/ansible-inventory.yml` — grouped by NOS, connection type pre-configured
- `clab-mv/nornir-simple-inventory.yml` — Nornir SimpleInventory format
