# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## What this is

A [ContainerLab](https://containerlab.dev/) multivendor network lab that demonstrates L2 EVPN/VXLAN interoperability across Nokia SR Linux, Nokia SROS, Arista cEOS, Juniper cJunos Evolved, SONiC, and FRRouting in a 2-tier CLOS fabric.

## Lab management

```bash
# Deploy (from repo root)
sudo clab deploy -t multivendor.clab.yml

# Redeploy from scratch (wipes node state)
sudo clab deploy -t multivendor.clab.yml --reconfigure

# Destroy
sudo clab destroy -t multivendor.clab.yml

# Inspect running state and management IPs
sudo clab inspect -t multivendor.clab.yml
```

The `clab-mv/` directory is auto-generated on deploy and contains runtime data (management IPs, Ansible/Nornir inventories, node-specific bind mounts).

### Post-deploy configuration (required for some nodes)

A few nodes are **not** fully brought up by ContainerLab's `startup-config` mechanism alone:

- **SONiC (`mv-sonic`)** — the `sonic-vm` kind only loads `config_db.json` on boot; interfaces, the VXLAN/VLAN dataplane, OSPF, and BGP/EVPN on the internal FRR control plane still need to be wired up. The script currently has to be run **twice** after a fresh deploy (idempotent, safe to re-run): on the first run OSPF and BGP come up, but VLAN 10 / `vtep1` / the VNI 1010 map are not created, so no EVPN routes are advertised for the VNI. The second run creates them.
  ```bash
  ./startup_config/post-deploy-sonic.sh mv-sonic
  ./startup_config/post-deploy-sonic.sh mv-sonic
  ```
- **Juniper cJunos Evolved (`mv-ptx-gw`, `mv-ptx`)** — their `startup-config` entries are commented out in `multivendor.clab.yml`, so `ptxgw.cfg`/`ptx.cfg` must be pasted in by hand after deploy: SSH in, `configure`, paste the matching file from `startup_config/`, `commit`.

## Node access

| Node | Kind | Management IP | Credentials |
|------|------|--------------|-------------|
| sros | Nokia SRSIM (spine, route reflector) | 172.20.20.34 | admin / NokiaSros1! |
| ptx-gw | Juniper cJunos-E (spine / DC gateway) | 172.20.20.10 | admin / admin@123 |
| srl | Nokia SR Linux (leaf) | 172.20.20.35 | admin / NokiaSrl1! |
| ceos | Arista cEOS (leaf) | 172.20.20.7 | admin / admin |
| ptx | Juniper cJunos-E (leaf) | 172.20.20.8 | admin / admin@123 |
| sonic | SONiC / FRR control plane (leaf) | 172.20.20.17 | admin / YourPaSsWoRd |
| frr | FRRouting (leaf) | — (shell access only) | — |

```bash
# SSH into any node
ssh admin@172.20.20.34

# SR Linux CLI via Docker (alternative)
docker exec -it mv-srl sr_cli

# SONiC — ssh in, then vtysh for routing config
ssh admin@mv-sonic
vtysh

# FRR — no SSH; get a shell via Docker, then vtysh for routing config
docker exec -it mv-frr sh
vtysh
```

IPs above are from the last deploy. Always use `clab inspect` to get current IPs after redeployment.

## Architecture

### Topology

```
        [sros spine]              [ptx-gw spine]
           |  |  |  \      /  |  |  |
          srl ceos ptx sonic frr (full mesh to both spines)
```

- **Spines** (route reflectors): `sros` (Nokia) and `ptx-gw` (Juniper cJunos Evolved)
- **Leaves**: `srl` (Nokia), `ceos` (Arista), `ptx` (Juniper), `sonic` (SONiC), `frr` (FRRouting)
- **Clients**: 5 Linux containers (`client-1` → srl, `client-2` → ceos, `client-3` → ptx, `client-4` → sonic, `client-5` → frr)

### Underlay

- **OSPF** area 0.0.0.0, point-to-point links
- Loopback/system IPs: leaves use `192.1.1.x/32`, spines use `192.1.2.x/32`
- Fabric links use dot1q encapsulation (VLAN ID 1) with 9194/9172 byte MTU

### Overlay

- **iBGP EVPN** (AS 65000), SROS acts as route reflector with cluster-id
- **VXLAN** VNI 1010 for VLAN 10 — L2 stretch across all leaf nodes
- **Vlan-aware-bundle** mode: route-target `65000:10`, EVI 10, eth-tag 1010
- Clients on `192.168.10.0/24` with MAC addresses `00:c1:ab:00:00:0x`

### Startup configs

`startup_config/` holds configs applied at deploy time (or manually post-deploy, where noted above):
- `srl.partial.txt` — SR Linux set-format CLI
- `sros.partial.txt` — SROS MD-CLI `configure` commands
- `ceos_startup.cfg` / `ceos_commands.txt` — EOS configuration
- `ptxgw_startup.cfg` / `ptxgw_commands.txt` — Juniper spine config (applied manually, see post-deploy above)
- `ptx_startup.cfg` / `ptx_commands.txt` — Juniper leaf config (applied manually, see post-deploy above)
- `sonic.json` / `sonic.txt` — SONiC `config_db.json` and reference commands
- `post-deploy-sonic.sh` — injects SSH key, interface IPs/MTUs, OSPF, and BGP EVPN into SONiC's FRR control plane
- `frr.conf` / `frr_daemons` / `frr-evpnvxlan.txt` — FRR node config

## Image requirements

Nokia SRSIM requires a license file at `../license-srsim25.txt` (one level above the repo root, relative to `multivendor.clab.yml`). The lab will fail to start without it.

Images must be pre-pulled/imported locally (not auto-pulled from a registry):
- `nokia_srsim:25.10.R2`
- `arista_ceos:4.34.2F`
- `juniper_cjunosevolved:25.4R1.13-EVO`
- `vrnetlab/sonic_sonic-vs:26` — a VM image (not a container image), built with [vrnetlab](https://github.com/hellt/vrnetlab)'s `sonic-vm`/`sonic-vs` builder from a SONiC-VS image downloaded via [sonic.software](https://sonic.software/)
- `quay.io/frrouting/frr:containerlab-10.7.1` — from [frrouting.org/release](https://frrouting.org/release/) or pulled directly

The `sonic` and `frr` image tags don't pin an exact software version — confirm what's actually running with `show version` (SONiC) or `vtysh` → `show version` (FRR).

## Automation inventories

Two automation inventory files are generated into `clab-mv/` on deploy:

- `clab-mv/ansible-inventory.yml` — Ansible inventory grouped by NOS kind, with `ansible_connection` pre-configured (httpapi for SRL, network_cli for SROS)
- `clab-mv/nornir-simple-inventory.yml` — Nornir SimpleInventory format with platform and hostname per node
