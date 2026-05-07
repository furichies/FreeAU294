# Ejercicio 4.1: Loops en Ansible

## Objetivo
Utilizar estructuras de repetición para ejecutar tareas múltiples.

## Conceptos Cubiertos
- Loop simple (`loop`)
- Loop con diccionario (`loop` + `item.key`)
- Async loops
- Until loops (reintentos)

## Sintaxis de Loop
```yaml
# Loop simple
- name: Instalar paquetes
  yum:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - httpd

# Loop con diccionario
- name: Crear usuarios
  user:
    name: "{{ item.name }}"
    shell: "{{ item.shell }}"
  loop:
    - { name: user1, shell: /bin/bash }
    - { name: user2, shell: /bin/false }
```

## Ejecución
```bash
ansible-playbook exercises/04-loops/exercise-4.1-loops.yml
```

## Comandos Útiles
```bash
# Ver estructura del loop
ansible-playbook playbook.yml --list-tasks
```
