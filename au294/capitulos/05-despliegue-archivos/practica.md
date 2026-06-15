# Práctica 5: Despliegue de Archivos

## Objetivo
Desplegar archivos estáticos y dinámicos con copy, template, blockinfile y lineinfile. Usar plantillas Jinja2.

---

## Paso 1: Módulo copy

Crear `playbook-copy.yml`:
```yaml
---
- name: Despliegue con copy
  hosts: all
  become: yes

  tasks:
    - name: Copiar archivo estático
      copy:
        content: |
          # Archivo de ejemplo generado por Ansible
          # Host: {{ inventory_hostname }}
          # Fecha: {{ ansible_date_time.iso8601 }}
        dest: /opt/lab/README.txt
        mode: '0644'

    - name: Copiar con permisos específicos
      copy:
        content: |
          [defaults]
          log_level=info
          max_connections=100
        dest: /opt/lab/app.cfg
        owner: root
        group: root
        mode: '0600'

    - name: Verificar archivo copiado
      stat:
        path: /opt/lab/app.cfg
      register: file_stat

    - name: Mostrar estado del archivo
      debug:
        msg:
          - "Existe: {{ file_stat.stat.exists }}"
          - "Modo: {{ file_stat.stat.mode }}"
          - "Tamaño: {{ file_stat.stat.size }}"
```

## Paso 2: Plantillas Jinja2

Crear `templates/`:
```bash
mkdir -p templates
```

Crear `templates/motd.j2`:
```jinja2
╔══════════════════════════════════════════════╗
║  {{ ansible_hostname }}                       ║
║  {{ ansible_default_ipv4.address }}           ║
║  {{ ansible_os_family }} {{ ansible_distribution_version }} ║
║  Gestionado por Ansible                       ║
║  Última actualización: {{ ansible_date_time.date }} ║
╚══════════════════════════════════════════════╝
```

Crear `templates/nginx.conf.j2`:
```jinja2
server {
    listen {{ http_port | default(80) }};
    server_name {{ inventory_hostname }};

    root /var/www/html;
    index index.html;

    access_log /var/log/nginx/{{ inventory_hostname }}_access.log;
    error_log /var/log/nginx/{{ inventory_hostname }}_error.log;

    {% if enable_ssl %}
    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/{{ inventory_hostname }}.crt;
    ssl_certificate_key /etc/ssl/private/{{ inventory_hostname }}.key;
    {% endif %}

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Crear `playbook-template.yml`:
```yaml
---
- name: Despliegue con templates
  hosts: all
  become: yes
  vars:
    http_port: 8080
    enable_ssl: false

  tasks:
    - name: Desplegar MOTD dinámico
      template:
        src: templates/motd.j2
        dest: /etc/motd
        mode: '0644'

    - name: Desplegar configuración Nginx
      template:
        src: templates/nginx.conf.j2
        dest: /opt/lab/nginx.conf
        mode: '0644'

    - name: Mostrar resultado
      debug:
        msg: "Plantilla generada para {{ inventory_hostname }}"
```

Ejecutar:
```bash
ansible-playbook playbook-template.yml -v
```

## Paso 3: blockinfile y lineinfile

Crear `playbook-block.yml`:
```yaml
---
- name: Gestionar archivos de texto
  hosts: all
  become: yes

  tasks:
    - name: Añadir hosts al /etc/hosts
      blockinfile:
        path: /etc/hosts
        block: |
          192.168.122.100  rhel-control
          192.168.122.101  rhel-node1
          192.168.122.102  rhel-node2
        marker: "# {mark} ANSIBLE INFRA HOSTS"
        backup: yes

    - name: Configurar SSH (denegar root)
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin no'
        backup: yes
      notify: reiniciar_sshd

    - name: Configurar KeepAlive SSH
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?ClientAliveInterval'
        line: 'ClientAliveInterval 300'
        backup: yes

    - name: Añadir alias global
      lineinfile:
        path: /etc/bashrc
        line: 'alias ll="ls -lh"'
        regexp: '^alias ll='

  handlers:
    - name: reiniciar_sshd
      systemd:
        name: sshd
        state: restarted
```

## Paso 4: Módulo fetch (descargar logs)

Crear `playbook-fetch.yml`:
```yaml
---
- name: Recopilar logs desde nodos
  hosts: all
  tasks:
    - name: Crear directorio local para logs
      local_action:
        module: file
        path: "logs/{{ inventory_hostname }}"
        state: directory

    - name: Descargar /etc/motd
      fetch:
        src: /etc/motd
        dest: "logs/{{ inventory_hostname }}/"
        flat: no

    - name: Descargar configuración
      fetch:
        src: /opt/lab/nginx.conf
        dest: "logs/{{ inventory_hostname }}/"
        flat: no
      ignore_errors: yes
```

## Paso 5: Caso completo — deploy web app

Crear `playbook-full-deploy.yml`:
```yaml
---
- name: Deploy completo de aplicación web
  hosts: webservers
  become: yes
  vars:
    app_port: 8080
    app_user: webapp
    index_title: "Bienvenido a {{ inventory_hostname }}"

  tasks:
    - name: Crear usuario de la aplicación
      user:
        name: "{{ app_user }}"
        shell: /sbin/nologin
        create_home: no

    - name: Crear directorios
      file:
        path: "/opt/{{ app_user }}/{{ item }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'
      loop:
        - bin
        - config
        - logs
        - www

    - name: Desplegar configuración
      template:
        src: templates/nginx.conf.j2
        dest: "/opt/{{ app_user }}/config/app.conf"
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0644'

    - name: Desplegar index.html
      copy:
        content: |
          <html>
          <head><title>{{ index_title }}</title></head>
          <body>
            <h1>{{ index_title }}</h1>
            <p>Server IP: {{ ansible_default_ipv4.address }}</p>
            <p>Deploy time: {{ ansible_date_time.iso8601 }}</p>
          </body>
          </html>
        dest: "/opt/{{ app_user }}/www/index.html"
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0644'

    - name: Configurar firewall
      firewalld:
        port: "{{ app_port }}/tcp"
        permanent: yes
        state: enabled
        immediate: yes
      when: ansible_os_family == "RedHat"
```

## Paso 6: Verificación final

```bash
# Ver archivos desplegados
ansible all -m command -a "cat /etc/motd"
ansible webservers -m command -a "cat /opt/lab/nginx.conf"

# Ver blockinfile
ansible all -m command -a "cat /etc/hosts"

# Descargar archivos
ansible-playbook playbook-fetch.yml

# Verificar estructura local
find logs/ -type f
```
