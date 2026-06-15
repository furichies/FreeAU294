# Capítulo 1: Introducción a Ansible

## ¿Qué es Ansible?

Ansible es una herramienta de automatización de TI **sin agente** (agentless) que permite gestionar configuraciones, aprovisionar servidores, desplegar aplicaciones y orquestar tareas complejas. Utiliza **SSH** como mecanismo de transporte por defecto y **YAML** como lenguaje de definición de playbooks.

## Principios fundamentales

| Concepto | Descripción |
|----------|-------------|
| **Agentless** | No requiere instalar software en los nodos gestionados |
| **Idempotencia** | Ejecutar un playbook múltiples veces produce el mismo resultado |
| **Declarativo** | Se describe el estado deseado, no los pasos para alcanzarlo |
| **Push-based** | El nodo controlador empuja la configuración a los nodos gestionados |

## Arquitectura

```
┌──────────────────┐       SSH        ┌──────────────────┐
│  Nodo Control    │ ──────────────►  │  Nodo Gestionado │
│  (Ansible Core)  │                  │  (RHEL 10)       │
└──────────────────┘                  └──────────────────┘
        │
        ├── Inventario (hosts)
        ├── Playbooks (YAML)
        ├── Roles
        └── ansible.cfg
```

## Componentes principales

### Ansible Core
Motor principal que ejecuta la automatización. Incluye módulos básicos, plugins de conexión y el lenguaje de playbooks.

### Ansible Development Tools (VS Code)
Conjunto de herramientas oficiales para desarrollar contenido Ansible:
- **ansible-lint**: verificador de sintaxis y buenas prácticas
- **ansible-navigator**: interfaz TUI para ejecutar y depurar playbooks
- **ansible-builder**: construye Execution Environments
- **ansible-playbook-grapher**: visualiza dependencias entre plays

### Inventario
Lista de nodos gestionados organizados por grupos. Puede ser estático (archivo INI/YAML) o dinámico (script que consulta cloud, LDAP, etc.).

```
[web]
web1.example.com
web2.example.com

[database]
db1.example.com

[all:vars]
ansible_user=admin
```

### Módulos
Unidades de trabajo que Ansible ejecuta en los nodos gestionados. Ejemplos:
- `dnf` — gestiona paquetes
- `copy` — copia archivos
- `systemd` — gestiona servicios
- `user` — gestiona usuarios
- `firewalld` — gestiona reglas de firewall

### Playbooks
Archivos YAML que definen la configuración deseada. Contienen uno o más **plays**, y cada play asocia un conjunto de **tasks** a un grupo de hosts.

```yaml
---
- name: Configurar servidor web
  hosts: web
  become: yes
  tasks:
    - name: Instalar httpd
      dnf:
        name: httpd
        state: present

    - name: Iniciar servicio
      systemd:
        name: httpd
        state: started
        enabled: yes
```

### Execution Environments
Contenedores que empaquetan Ansible Core, colecciones, módulos y dependencias. Garantizan consistencia entre entornos de desarrollo y producción.

## Flujo de trabajo típico

1. **Nodo control**: máquina con Ansible instalado (RHEL 10 + Ansible Core 2.16)
2. **Inventario**: define qué hosts gestionar
3. **Playbook**: describe el estado deseado
4. **Conexión SSH**: Ansible se conecta a los nodos gestionados
5. **Ejecución**: el nodo control transfiere módulos (Python) a los nodos gestionados
6. **Idempotencia**: cada tarea verifica el estado actual antes de actuar

## ansible.cfg — Configuración principal

```ini
[defaults]
inventory = ./inventory
remote_user = admin
host_key_checking = False
gathering = smart

[ssh_connection]
pipelining = True
```

## Comandos esenciales

| Comando | Descripción |
|---------|-------------|
| `ansible --version` | Muestra versión y configuración |
| `ansible all -m ping` | Prueba conectividad con todos los hosts |
| `ansible-inventory --list` | Muestra el inventario en JSON |
| `ansible-playbook playbook.yml --syntax-check` | Verifica sintaxis |
| `ansible-playbook playbook.yml -C` | Ejecuta en modo check (dry-run) |
| `ansible-lint playbook.yml` | Analiza buenas prácticas |
