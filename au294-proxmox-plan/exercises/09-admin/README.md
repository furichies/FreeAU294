# Ejercicio 9.1: Gestión de Usuarios

## Objetivo
Gestionar usuarios y grupos en sistemas Linux con Ansible.

## Conceptos Cubiertos
- Módulo `group`
- Módulo `user`
- Contraseñas con password_hash
- Autorización SSH
- Configuración de sudo

## Módulos Utilizados
```yaml
# Crear grupo
- name: Crear grupo
  group:
    name: developers
    gid: 5000

# Crear usuario
- name: Crear usuario
  user:
    name: john
    comment: "John Developer"
    group: developers
    password: "{{ 'Pass123!' | password_hash('sha512') }}"
    shell: /bin/bash

# Agregar clave SSH
- name: Agregar clave SSH
  authorized_key:
    user: john
    key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
```

## Ejecución
```bash
ansible-playbook exercises/09-admin/exercise-9.1-users-groups.yml
```

## Verificación
```bash
ansible managed -m command -a "getent group developers"
ansible managed -m command -a "id john"
```
