# Ejercicio 6.1: Roles de Ansible

## Objetivo
Crear y utilizar roles de Ansible para organizar playbooks reutilizables.

## Estructura de un Rol
```
roles/
  rolename/
    defaults/      # Variables por defecto (main.yml)
    files/         # Archivos estáticos
    handlers/      # Handlers (main.yml)
    meta/          # Metadatos del rol
    tasks/         # Tareas principales (main.yml)
    templates/     # Plantillas Jinja2
    tests/         # Tests del rol
    vars/          # Variables del rol (main.yml)
```

## Crear un Rol
```bash
ansible-galaxy init roles/webserver --offline
```

## Incluir Roles en Playbook
```yaml
- name: Mi Playbook
  hosts: servers
  roles:
    - webserver
    - ntp-config
```

## Ejecución
```bash
ansible-playbook exercises/06-roles/exercise-6.1-create-role.yml
```

## Verificación
```bash
ls -la roles/webserver/
```
