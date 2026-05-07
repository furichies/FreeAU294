#!/usr/bin/env python3
# =============================================================================
# inventory-gen.py - Generar inventario Ansible dinámicamente desde Proxmox
# =============================================================================
# Consulta la API de Proxmox para descubrir VMs y generar automáticamente
# el archivo de inventario para Ansible.
# =============================================================================

import json
import os
import sys
import argparse
import requests
from requests.auth import HTTPBasicAuth
from urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

PROXMOX_HOST = os.getenv("PROXMOX_HOST", "localhost")
PROXMOX_USER = os.getenv("PROXMOX_USER", "root@pam")
PROXMOX_PASSWORD = os.getenv("PROXMOX_PASSWORD", "")
PROXMOX_NODE = os.getenv("PROXMOX_NODE", "pve")
API_PORT = int(os.getenv("PROXMOX_API_PORT", "8006"))
USE_SSL = os.getenv("PROXMOX_SSL", "false").lower() == "true"

BASE_URL = f"{'https' if USE_SSL else 'http'}://{PROXMOX_HOST}:{API_PORT}/api2/json"


def get_ticket():
    """Obtiene ticket de autenticación de Proxmox."""
    url = f"{BASE_URL}/access/ticket"
    data = {"username": PROXMOX_USER, "password": PROXMOX_PASSWORD}

    try:
        response = requests.post(url, data=data, verify=False)
        response.raise_for_status()
        return response.json()["data"]
    except requests.RequestException as e:
        print(f"Error de autenticación: {e}", file=sys.stderr)
        sys.exit(1)


def get_api_data(endpoint, ticket):
    """Consulta un endpoint de la API de Proxmox."""
    url = f"{BASE_URL}{endpoint}"
    headers = {"CSRFPreventionToken": ticket["CSRFPreventionToken"]}
    cookies = {"PVEAuthCookie": ticket["ticket"]}

    try:
        response = requests.get(url, headers=headers, cookies=cookies, verify=False)
        response.raise_for_status()
        return response.json()["data"]
    except requests.RequestException as e:
        print(f"Error consultando API: {e}", file=sys.stderr)
        return []


def get_vms(ticket):
    """Obtiene lista de VMs del nodo Proxmox."""
    return get_api_data(f"/nodes/{PROXMOX_NODE}/qemu", ticket)


def get_vm_config(vmid, ticket):
    """Obtiene configuración detallada de una VM."""
    return get_api_data(f"/nodes/{PROXMOX_NODE}/qemu/{vmid}/config", ticket)


def generate_inventory(vms, groups=None):
    """Genera contenido del inventario Ansible."""
    lines = [
        "# Inventario Ansible - Generado por inventory-gen.py",
        "# Fecha: " + __import__("datetime").datetime.now().isoformat(),
        "",
        "[all:vars]",
        "ansible_python_interpreter=/usr/bin/python3",
        "ansible_user=root",
        "",
    ]

    if groups is None:
        groups = {
            "control": ["ansible-control"],
            "webservers": ["managed-node-01", "managed-node-02"],
            "dbservers": ["managed-node-03"],
            "managed": ["managed-node-01", "managed-node-02", "managed-node-03"],
        }

    nodes = {"control": [], "managed": []}

    for vm in vms:
        vmid = vm.get("vmid")
        name = vm.get("name", f"vm-{vmid}")
        config = get_vm_config(vmid, get_ticket())

        net = config.get("net0", "")
        ip = None
        if "net1" in config:
            net = config["net1"]
        if "virtio,bridge" in net:
            bridge = net.split(",bridge=")[-1] if ",bridge=" in net else ""
            ip = config.get("ip", "").split(",")[0]

        status = vm.get("status", "unknown")
        template = vm.get("template", "0")

        if template == "1":
            continue

        if ip:
            lines.append(f"{name} ansible_host={ip}")
        else:
            lines.append(f"# {name} ansible_host=<IP_NO_DETECTADA>  # {status}")

        if name.startswith("ansible-control"):
            nodes["control"].append(name)
        else:
            nodes["managed"].append(name)

    lines.extend(["", "[control]", *[f"  {n}" for n in nodes["control"]], ""])

    lines.extend(["[managed]", *[f"  {n}" for n in nodes["managed"]], ""])

    for group_name, group_vms in groups.items():
        if group_name not in ["control", "managed"]:
            lines.extend([f"[{group_name}]", *[f"  {n}" for n in group_vms if n in nodes["managed"]], ""])

    lines.extend(["[lab:children]", "  control", "  managed", ""])

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generador de inventario Ansible desde Proxmox")
    parser.add_argument("-o", "--output", default="inventory.ini", help="Archivo de salida")
    parser.add_argument("-g", "--groups", help="Archivo JSON con definiciones de grupos")
    args = parser.parse_args()

    print("Obteniendo ticket de Proxmox...", file=sys.stderr)
    ticket = get_ticket()

    print("Consultando VMs...", file=sys.stderr)
    vms = get_vms(ticket)

    print(f"Encontradas {len(vms)} VMs", file=sys.stderr)

    groups = None
    if args.groups and os.path.exists(args.groups):
        with open(args.groups) as f:
            groups = json.load(f)

    inventory_content = generate_inventory(vms, groups)

    with open(args.output, "w") as f:
        f.write(inventory_content)

    print(f"Inventario generado: {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
