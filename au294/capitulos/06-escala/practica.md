# Práctica 6: Contenido a Escala

## Objetivo
Usar importación dinámica y estática de tareas, estrategias, patrones avanzados de hosts, y estructuras de proyecto grandes.

---

## Paso 1: Estructura de proyecto escalable

```bash
mkdir -p ~/au294/escala/tasks
cd ~/au294/escala
```

## Paso 2: include_tasks (dinámico)

Crear `tasks/paquetes.yml`:
```yaml
---
- name: Instalar paquetes de desarrollo
  dnf:
    name:
      - gcc
      - make
      - python3-devel
    state: present

- name: Instalar herramientas de red
  dnf:
    name:
      - tcpdump
      - nmap-ncat
      - bind-utils
    state: present
```

Crear `tasks/firewall.yml`:
```yaml
---
- name: Abrir puertos según grupo
  firewalld:
    service: "{{ item }}"
    permanent: yes
    state: enabled
    immediate: yes
  loop: "{{ firewall_services | default([]) }}"
  when: ansible_os_family == "RedHat"
```

Crear `playbook-include.yml`:
```yaml
---
- name: Demostrar include_tasks
  hosts: all
  become: yes
  vars:
    firewall_services:
      - http
      - https
      - ssh

  tasks:
    - name: Incluir tareas de paquetes
      include_tasks: tasks/paquetes.yml
      tags: packages

    - name: Incluir tareas de firewall
      include_tasks: tasks/firewall.yml
      when: "'webservers' in group_names"
      tags: firewall
```

Ejecutar:
```bash
ansible-playbook -i ../inventory playbook-include.yml
```

## Paso 3: Loop con include_tasks

Crear `tasks/crear_directorio.yml`:
```yaml
---
- name: Crear directorio {{ current_dir }}
  file:
    path: "{{ current_dir }}"
    state: directory
    mode: '0755'
```

Crear `playbook-loop-include.yml`:
```yaml
---
- name: Bucles con include_tasks
  hosts: all
  become: yes
  vars:
    directorios:
      - /opt/app/code
      - /opt/app/config
      - /opt/app/data
      - /opt/app/logs

  tasks:
    - name: Crear directorios con loop dinámico
      include_tasks: tasks/crear_directorio.yml
      loop: "{{ directorios }}"
      loop_control:
        loop_var: current_dir
```

## Paso 4: import_tasks (estático)

Crear `tasks/seguridad.yml`:
```yaml
---
- name: Configurar SELinux
  selinux:
    policy: targeted
    state: enforcing
  when: ansible_selinux is defined

- name: Configurar umask por defecto
  lineinfile:
    path: /etc/profile
    regexp: '^umask'
    line: 'umask 027'
```

Crear `playbook-import.yml`:
```yaml
---
- name: Demostrar import_tasks
  hosts: all
  become: yes
  tasks:
    - name: Importar tareas de seguridad
      import_tasks: tasks/seguridad.yml
      tags: security
```

Diferencias con `--list-tasks`:
```bash
ansible-playbook playbook-import.yml --list-tasks
ansible-playbook playbook-include.yml --list-tasks
```

## Paso 5: Estrategias y serial

Crear `playbook-strategy.yml`:
```yaml
---
- name: Rolling update
  hosts: all
  serial: 1
  any_errors_fatal: yes

  tasks:
    - name: Instalar actualizaciones de seguridad
      dnf:
        name: "*"
        state: latest
        security: yes
      register: update_result

    - name: Verificar reinicio necesario
      stat:
        path: /var/run/reboot-required
      register: reboot_stat
      when: update_result.changes is defined

    - name: Mostrar resultado
      debug:
        msg: "{{ inventory_hostname }} actualizado"
```

Ejecutar:
```bash
# Serial 1 (un host a la vez)
ansible-playbook playbook-strategy.yml

# Estrategia free (cada host independiente)
cat << 'EOF' > playbook-free.yml
---
- name: Estrategia free
  hosts: all
  strategy: free
  tasks:
    - name: Simular trabajo
      command: sleep 5
    - name: Completado
      debug:
        msg: "{{ inventory_hostname }} terminó"
EOF
ansible-playbook playbook-free.yml
```

## Paso 6: Patrones avanzados

Crear `playbook-patterns.yml`:
```yaml
---
- name: Patrones de hosts
  hosts: "{{ host_pattern | default('all') }}"
  tasks:
    - name: Mostrar hosts seleccionados
      debug:
        msg: "Ejecutando en {{ inventory_hostname }}"
```

Probar patrones:
```bash
# Grupo específico
ansible-playbook playbook-patterns.yml -e "host_pattern=webservers"

# Un solo host
ansible-playbook playbook-patterns.yml -e "host_pattern=rhel-node1"

# Todos menos uno
ansible-playbook playbook-patterns.yml -e "host_pattern=all:!rhel-node2"

# Intersección (si aplica)
ansible-playbook playbook-patterns.yml -e "host_pattern=webservers:&groups_defined"
```

## Paso 7: Proyecto completo

```bash
mkdir -p ~/au294/escala/proyecto/{inventory/{group_vars,host_vars},playbooks,tasks,roles}
```

Crear `~/au294/escala/proyecto/playbooks/site.yml`:
```yaml
---
- name: Aprovisionamiento completo
  hosts: all
  become: yes

  pre_tasks:
    - name: Cargar variables de entorno
      include_vars:
        dir: "vars"
      tags: always

  tasks:
    - name: Ejecutar tareas base
      include_tasks: ../tasks/paquetes.yml
      tags: packages

    - name: Ejecutar tareas de seguridad
      import_tasks: ../tasks/seguridad.yml
      tags: security

  post_tasks:
    - name: Mostrar resumen
      debug:
        msg: "Aprovisionamiento completado en {{ inventory_hostname }}"
      tags: always
```

## Paso 8: Verificación final

```bash
# Probar el proyecto completo
cd ~/au294/escala/proyecto
ansible-playbook -i ../../inventory playbooks/site.yml --list-tasks
ansible-playbook -i ../../inventory playbooks/site.yml

# Verificar directorios creados
ansible all -m command -a "ls -la /opt/app/"

# Ver cambios de seguridad
ansible all -m command -a "umask"
ansible all -m command -a "grep umask /etc/profile"
```
