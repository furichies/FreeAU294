# AU294 — Red Hat Enterprise Linux Automation with Ansible

Material de estudio para el curso **AU294 (RH294)**: *Red Hat Enterprise Linux Automation with Ansible*.

Basado en **RHEL 10**, **Ansible Core 2.16** y **Red Hat Ansible Automation Platform 2.5/2.6**.

## Estructura

```
au294/
├── README.md
└── capitulos/
    ├── 01-introduccion-ansible/     # Conceptos, arquitectura, instalación
    ├── 02-desarrollo-automatizacion/ # Inventarios, módulos, playbooks básicos
    ├── 03-variables/                 # Variables, facts, Ansible Vault
    ├── 04-control-tareas/            # Condicionales, bucles, handlers, errores
    ├── 05-despliegue-archivos/       # copy, template, Jinja2, blockinfile
    ├── 06-escala/                    # include/import, estrategias, patrones
    ├── 07-roles-colecciones/         # Roles, Ansible Galaxy, Collections
    └── 08-automatizacion-linux/      # LVM, SELinux, systemd, red, usuarios
```

Cada capítulo contiene:
- **teoria.md** — Conceptos, sintaxis, ejemplos de código
- **practica.md** — Laboratorio paso a paso con objetivos y verificación

## Requisitos

- RHEL 10 (nodo control y nodos gestionados)
- Ansible Core 2.16, `ansible-dev-tools`
- Acceso SSH por clave entre nodos
- Usuario con sudo NOPASSWD en nodos gestionados

## Cómo usar

```bash
# 1. Leer la teoría
cat capitulos/01-introduccion-ansible/teoria.md

# 2. Seguir la práctica en el laboratorio
# Ajustar IPs y nombres de host según tu entorno
```

## Preparación del laboratorio

```bash
# Nodo control
sudo dnf install -y ansible-core ansible-dev-tools
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Cada nodo gestionado
sudo useradd admin
echo "admin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/admin
```

## Licencia

Material educativo de uso libre.
