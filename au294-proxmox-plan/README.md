# Laboratorio AU294: Red Hat Enterprise Linux Automation with Ansible

## Descripción General

Este repositorio contiene los ejercicios prácticos para el curso **AU294: Red Hat Enterprise Linux Automation with Ansible**, diseñados para ejecutarse en una infraestructura de laboratorio basada en **Proxmox VE**.

## Estructura del Proyecto

```
au294-proxmox-plan/
├── scripts/              # Scripts de automatización
│   ├── setup-proxmox-lab.sh
│   ├── reset-lab.sh
│   ├── inventory-gen.py
│   └── 00-setup-control-node.sh
├── inventory/            # Archivos de inventario Ansible
│   └── inventory.ini
├── ansible.cfg          # Configuración global de Ansible
├── roles/                # Roles personalizados
│   ├── webserver/
│   └── ntp-config/
├── templates/           # Plantillas Jinja2 globales
├── exercises/           # Ejercicios por capítulo
│   ├── 01-intro/
│   ├── 02-playbooks/
│   ├── 03-variables/
│   ├── 04-loops/
│   ├── 05-templates/
│   ├── 06-roles/
│   ├── 07-execution/
│   ├── 08-security/
│   ├── 09-admin/
│   └── 10-integration/
└── PLAN.md              # Plan maestro del laboratorio
```

## Requisitos Previos

### Hardware
- Servidor Proxmox con virtualización habilitada (VT-x/AMD-V)
- Mínimo 8 GB RAM, 50 GB disco disponible
- Conexión a red para descargas

### Software
- Proxmox VE 8.x
- Plantilla de CentOS Stream 9 o RHEL 9

### Conocimiento
- Fundamentos de administración Linux
- Conceptos básicos de redes TCP/IP
- Familiaridad con línea de comandos bash

## Configuración Rápida

### 1. Clonar el Repositorio
```bash
git clone <repository-url> au294-proxmox-plan
cd au294-proxmox-plan
```

### 2. Ejecutar el Script de Configuración
```bash
chmod +x scripts/*.sh
sudo ./scripts/setup-proxmox-lab.sh
```

### 3. Configurar el Nodo de Control
```bash
cd ~/ansible-au294
./scripts/00-setup-control-node.sh
```

### 4. Verificar Conectividad
```bash
ansible all -i inventory/inventory.ini -m ping
```

## Ejecución de Ejercicios

### Capítulo 1: Introducción
```bash
ansible-playbook exercises/01-intro/exercise-1.1-verify-ansible.yml
ansible-playbook exercises/01-intro/exercise-1.2-adhoc-commands.yml
ansible-playbook exercises/01-intro/exercise-1.3-inventory.yml
```

### Capítulo 2: Playbooks
```bash
ansible-playbook exercises/02-playbooks/exercise-2.1-first-playbook.yml
ansible-playbook exercises/02-playbooks/exercise-2.2-modules.yml
```

### Capítulo 3: Variables
```bash
ansible-playbook exercises/03-variables/exercise-3.1-variables.yml
ansible-playbook exercises/03-variables/exercise-3.3-templates.yml
```

### Capítulo 4: Loops y Condicionales
```bash
ansible-playbook exercises/04-loops/exercise-4.1-loops.yml
ansible-playbook exercises/04-loops/exercise-4.2-conditionals.yml
```

### Capítulo 5: Plantillas Avanzadas
```bash
ansible-playbook exercises/05-templates/exercise-5.2-jinja2-filters.yml
```

### Capítulo 6: Roles
```bash
ansible-playbook exercises/06-roles/exercise-6.1-create-role.yml
ansible-playbook exercises/06-roles/exercise-6.3-ntp-role.yml
```

### Capítulo 7: Control de Ejecución
```bash
ansible-playbook exercises/07-execution/exercise-7.1-tags.yml --tags install
ansible-playbook exercises/07-execution/exercise-7.2-execution-control.yml --start-at-task="Tarea de verificación"
```

### Capítulo 8: Seguridad
```bash
ansible-playbook exercises/08-security/exercise-8.2-hardening.yml
```

### Capítulo 9: Administración Linux
```bash
ansible-playbook exercises/09-admin/exercise-9.1-users-groups.yml
ansible-playbook exercises/09-admin/exercise-9.3-network-config.yml
```

### Capítulo 10: Integración
```bash
ansible-playbook exercises/10-integration/exercise-10.2-proxmox-api.yml
```

## Gestión de Snapshots

Para guardar el estado del laboratorio:
```bash
./scripts/reset-lab.sh backup
```

Para restaurar:
```bash
./scripts/reset-lab.sh snapshot
```

## Troubleshooting

### Problemas de Conexión SSH
```bash
ssh -o StrictHostKeyChecking=no root@10.10.10.11
```

### Verificar Inventario
```bash
ansible-inventory -i inventory/inventory.ini --list
```

### Verbose Debug
```bash
ansible-playbook exercises/01-intro/exercise-1.2-adhoc-commands.yml -vvv
```

## Referencias

- [Documentación oficial de Ansible](https://docs.ansible.com/)
- [Red Hat Training AU294](https://www.redhat.com/)
- [Documentación Proxmox VE](https://pve.proxmox.com/wiki/Main_Page)

## Licencia

Material educativo preparado para el curso AU294. Consultar términos de uso de Red Hat.
