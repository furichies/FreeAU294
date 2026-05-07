# Ejercicio 2.1: Tu Primer Playbook

## Objetivo
Crear y ejecutar tu primer playbook de Ansible.

## Conceptos Cubiertos
- Estructura básica de un playbook YAML
- Módulo `debug`
- Módulo `file`
- Módulo `copy`

## Estructura de un Playbook
```yaml
- name: Nombre del playbook
  hosts: destinos
  gather_facts: yes|no
  vars:
    - variable: valor
  tasks:
    - name: Descripción de la tarea
      módulo:
        opción: valor
```

## Ejecución
```bash
ansible-playbook exercises/02-playbooks/exercise-2.1-first-playbook.yml
```

## Verificación
- Se crea `/opt/au294-app/status.txt`
- El archivo contiene información del servidor

## Desafíos
1. Modificar el mensaje de bienvenida
2. Agregar más información al archivo de estado
3. Cambiar el directorio de destino
