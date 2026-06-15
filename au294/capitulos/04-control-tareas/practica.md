# Práctica 4: Control de Tareas

## Objetivo
Implementar condicionales, bucles, handlers, manejo de errores y tags en playbooks.

---

## Paso 1: Condicionales

Crear `playbook-when.yml`:
```yaml
---
- name: Condicionales
  hosts: all
  become: yes
  tasks:
    - name: Instalar httpd solo en webservers
      dnf:
        name: httpd
        state: present
      when: "'webservers' in group_names"

    - name: Instalar mariadb solo en databases
      dnf:
        name: mariadb-server
        state: present
      when: "'databases' in group_names"

    - name: Configurar según versión de RHEL
      sysctl:
        name: net.ipv4.tcp_tw_reuse
        value: '1'
        sysctl_set: yes
      when:
        - ansible_os_family == "RedHat"
        - ansible_distribution_major_version | int >= 8

    - name: Mensaje personalizado por host
      debug:
        msg: "Http puerto {{ http_port | default(80) }}"
      when: http_port is defined
```

Ejecutar:
```bash
ansible-playbook playbook-when.yml
```

## Paso 2: Bucles

Crear `playbook-loop.yml`:
```yaml
---
- name: Bucles en Ansible
  hosts: all
  become: yes

  tasks:
    - name: Instalar paquetes desde lista
      dnf:
        name: "{{ item }}"
        state: present
      loop:
        - vim
        - git
        - htop
        - tmux
        - net-tools

    - name: Crear directorios
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - /opt/app/{logs,config,data}
        - /opt/app/backups

    - name: Crear usuarios desde diccionario
      user:
        name: "{{ item.name }}"
        uid: "{{ item.uid }}"
        groups: "{{ item.groups | default('') }}"
        shell: "{{ item.shell | default('/bin/bash') }}"
        create_home: yes
      loop:
        - { name: dev1, uid: 2001, groups: wheel }
        - { name: dev2, uid: 2002 }
        - { name: dev3, uid: 2003, shell: /bin/zsh, groups: docker }
```

## Paso 3: Bucles con when

Crear `playbook-loop-when.yml`:
```yaml
---
- name: Bucle con condicional
  hosts: all
  vars:
    services:
      - name: httpd
        enabled: "{{ 'webservers' in group_names }}"
      - name: mariadb
        enabled: "{{ 'databases' in group_names }}"
      - name: sshd
        enabled: yes

  tasks:
    - name: Gestionar servicios según grupo
      systemd:
        name: "{{ item.name }}"
        enabled: "{{ item.enabled }}"
        state: started
      loop: "{{ services }}"
      when: item.enabled
```

## Paso 4: Handlers

Crear `playbook-handlers.yml`:
```yaml
---
- name: Handlers en acción
  hosts: webservers
  become: yes

  tasks:
    - name: Instalar httpd
      dnf:
        name: httpd
        state: present
      notify: reiniciar_httpd

    - name: Copiar configuración personalizada
      copy:
        content: |
          Listen {{ http_port | default(8080) }}
        dest: /etc/httpd/conf.d/custom_port.conf
        mode: '0644'
      notify: reiniciar_httpd

    - name: Crear contenido web
      copy:
        content: "Handler test - {{ ansible_date_time.iso8601 }}"
        dest: /var/www/html/index.html
        mode: '0644'
      notify: recargar_httpd

  handlers:
    - name: reiniciar_httpd
      systemd:
        name: httpd
        state: restarted

    - name: recargar_httpd
      systemd:
        name: httpd
        state: reloaded
```

Ejecutar dos veces y observar la idempotencia:
```bash
ansible-playbook playbook-handlers.yml -v
ansible-playbook playbook-handlers.yml -v
```

## Paso 5: Gestión de errores

Crear `playbook-errores.yml`:
```yaml
---
- name: Manejo de errores
  hosts: all
  become: yes

  tasks:
    - name: Tarea que puede fallar (ignorada)
      command: /bin/false
      ignore_errors: yes

    - name: Instalar paquete inexistente
      dnf:
        name: paquete-inexistente
        state: present
      ignore_errors: yes
      register: result

    - name: Mostrar resultado del error
      debug:
        msg: "El paquete no se instaló: {{ result.msg | default('ok') }}"

    - name: Bloque try-rescue
      block:
        - name: Intentar instalar httpd
          dnf:
            name: httpd
            state: present

        - name: Iniciar httpd
          systemd:
            name: httpd
            state: started

      rescue:
        - name: Registrar fallo
          copy:
            content: "Fallo en {{ ansible_date_time.iso8601 }}"
            dest: /tmp/error.log

      always:
        - name: Limpieza
          debug:
            msg: "Bloque terminado (éxito o fallo)"
```

## Paso 6: Tags

Crear `playbook-tags.yml`:
```yaml
---
- name: Demostrar tags
  hosts: all
  become: yes

  tasks:
    - name: Actualizar caché dnf
      dnf:
        update_cache: yes
      tags: always

    - name: Instalar herramientas
      dnf:
        name:
          - vim
          - git
        state: present
      tags: install

    - name: Configurar MOTD
      copy:
        content: "Gestionado por Ansible\n"
        dest: /etc/motd
        mode: '0644'
      tags: config

    - name: Verificar instalación
      command: which git
      register: git_result
      tags: verify

    - name: Mostrar resultado
      debug:
        var: git_result.stdout
      tags: verify

    - name: Servicio operativo
      systemd:
        name: sshd
        state: started
      tags: service
```

Ejecutar selectivamente:
```bash
ansible-playbook playbook-tags.yml --tags "install,config"
ansible-playbook playbook-tags.yml --tags "verify"
ansible-playbook playbook-tags.yml --skip-tags "verify"
ansible-playbook playbook-tags.yml --list-tags
```

## Paso 7: Verificación final

```bash
# Limpiar todo y aplicar de nuevo
ansible-playbook playbook-errores.yml
ansible-playbook playbook-tags.yml --tags "install,config,service"
```
