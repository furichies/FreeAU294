# Capítulo 4: Control de Tareas

## Condicionales (when)

```yaml
- name: Ejecutar solo en RHEL
  dnf:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"

- name: Ejecutar condicion compuesta
  systemd:
    name: httpd
    state: restarted
  when:
    - ansible_os_family == "RedHat"
    - ansible_distribution_major_version | int >= 8

- name: Condicion negada
  user:
    name: testuser
    state: absent
  when: not ansible_check_mode

- name: Condicion booleana desde variable
  template:
    src: config.j2
    dest: /etc/app.conf
  when: install_app | default(false) | bool
```

## Bucles (loop)

### loop (lista simple)
```yaml
- name: Instalar múltiples paquetes
  dnf:
    name: "{{ item }}"
    state: present
  loop:
    - httpd
    - mod_ssl
    - php
    - mariadb
```

### loop (lista de diccionarios)
```yaml
- name: Crear usuarios
  user:
    name: "{{ item.name }}"
    uid: "{{ item.uid }}"
    groups: "{{ item.groups | default(omit) }}"
    shell: "{{ item.shell | default('/bin/bash') }}"
  loop:
    - { name: alice, uid: 1001, groups: wheel }
    - { name: bob, uid: 1002 }
    - { name: charlie, uid: 1003, shell: /bin/zsh }
```

### loop con dict
```yaml
- name: Configurar usuarios desde diccionario
  user:
    name: "{{ item.key }}"
    uid: "{{ item.value.uid }}"
    groups: "{{ item.value.groups }}"
  loop: "{{ usuarios \| dict2items }}"
  vars:
    usuarios:
      alice:
        uid: 1001
        groups: wheel
      bob:
        uid: 1002
        groups: ""
```

## Handlers

```yaml
tasks:
  - name: Cambiar configuracion
    template:
      src: config.j2
      dest: /etc/app/config.yml
    notify: reiniciar_app

  - name: Cambiar configuracion 2
    template:
      src: other.j2
      dest: /etc/app/other.yml
    notify: reiniciar_app

handlers:
  - name: reiniciar_app
    systemd:
      name: app
      state: restarted
```

### Handlers con listen
```yaml
tasks:
  - name: Cambiar config
    template:
      src: config.j2
      dest: /etc/app/config.yml
    notify: recargar_app

handlers:
  - name: recargar_app
    systemd:
      name: app
      state: reloaded
    listen: "evento_recarga"

  - name: rearrancar_app
    systemd:
      name: app
      state: restarted
    listen: "evento_recarga"
```

## Gestión de errores

### ignore_errors
```yaml
- name: Tarea que puede fallar
  command: /bin/false
  ignore_errors: yes
```

### failed_when
```yaml
- name: Comprobar salida de comando
  command: /usr/bin/app-status
  register: result
  failed_when:
    - result.rc != 0
    - '"FATAL" in result.stderr'
```

### changed_when
```yaml
- name: Ejecutar script
  shell: /opt/deploy.sh
  register: result
  changed_when: result.rc != 0
```

### block/rescue/always
```yaml
- name: Probar bloque try-catch
  block:
    - name: Tarea que puede fallar
      command: /bin/false

    - name: Configurar servicio
      systemd:
        name: app
        state: started

  rescue:
    - name: Tarea de recuperación
      debug:
        msg: "La tarea falló, ejecutando recuperación"

    - name: Notificar error
      slack:
        token: "{{ slack_token }}"
        msg: "Fallo en la automatización"

  always:
    - name: Tarea que se ejecuta siempre
      debug:
        msg: "Esto se ejecuta incluso si falla o no"
```

## Tags

```yaml
tasks:
  - name: Instalar paquetes
    dnf:
      name: httpd
      state: present
    tags: install

  - name: Configurar servicio
    template:
      src: config.j2
      dest: /etc/httpd/conf/httpd.conf
    tags: config

  - name: Iniciar servicio
    systemd:
      name: httpd
      state: started
    tags: service

  - name: Verificar conectividad
    uri:
      url: http://localhost
      status_code: 200
    tags: verify
```

```bash
# Ejecutar solo tags específicos
ansible-playbook playbook.yml --tags "install,config"
ansible-playbook playbook.yml --tags "config" --skip-tags "verify"
ansible-playbook playbook.yml --list-tags
```

## Delegación y ejecución local

```yaml
- name: Ejecutar localmente
  local_action:
    module: command
    cmd: echo "Ejecutado en el nodo control"

- name: Delegar a localhost
  debug:
    msg: "Ejecutado en {{ inventory_hostname }}"
  delegate_to: localhost

- name: Ejecutar en un host específico
  command: /usr/bin/backup
  delegate_to: backup-server

- name: Delegar facts
  setup:
  delegate_to: localhost
  delegate_facts: yes
```
