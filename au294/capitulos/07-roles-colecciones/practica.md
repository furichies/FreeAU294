# Práctica 7: Roles y Content Collections

## Objetivo
Crear roles reutilizables, instalar colecciones de Ansible Galaxy, y usar roles del sistema Red Hat.

---

## Paso 1: Crear un rol con ansible-galaxy

```bash
cd ~/au294/roles
ansible-galaxy role init nginx
ansible-galaxy role init common
ansible-galaxy role init firewall
```

Ver estructura de `roles/nginx/`:
```bash
find roles/nginx/ -type f
```

## Paso 2: Desarrollar el rol nginx

`roles/nginx/defaults/main.yml`:
```yaml
---
nginx_port: 80
nginx_server_name: localhost
nginx_root: /usr/share/nginx/html
```

`roles/nginx/tasks/main.yml`:
```yaml
---
- name: Instalar nginx
  dnf:
    name: nginx
    state: present

- name: Copiar configuración
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    mode: '0644'
  notify: reiniciar_nginx

- name: Iniciar y habilitar
  systemd:
    name: nginx
    state: started
    enabled: yes

- name: Copiar index.html
  template:
    src: index.html.j2
    dest: "{{ nginx_root }}/index.html"
    mode: '0644'
```

`roles/nginx/handlers/main.yml`:
```yaml
---
- name: reiniciar_nginx
  systemd:
    name: nginx
    state: restarted
```

Crear `roles/nginx/templates/nginx.conf.j2`:
```jinja2
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen {{ nginx_port }};
        server_name {{ nginx_server_name }};
        root {{ nginx_root }};

        location / {
            try_files $uri $uri/ =404;
        }
    }
}
```

Crear `roles/nginx/templates/index.html.j2`:
```jinja2
<html>
<head><title>{{ nginx_server_name }}</title></head>
<body>
  <h1>{{ nginx_server_name }}</h1>
  <p>Servido por nginx</p>
  <p>Host: {{ ansible_hostname }}</p>
  <p>IP: {{ ansible_default_ipv4.address }}</p>
</body>
</html>
```

## Paso 3: Desarrollar el rol common

`roles/common/defaults/main.yml`:
```yaml
---
common_timezone: UTC
common_packages:
  - vim
  - git
  - curl
  - htop
  - bash-completion
```

`roles/common/tasks/main.yml`:
```yaml
---
- name: Configurar zona horaria
  timezone:
    name: "{{ common_timezone }}"

- name: Instalar paquetes base
  dnf:
    name: "{{ common_packages }}"
    state: present

- name: Actualizar todos los paquetes
  dnf:
    name: "*"
    state: latest
    security: yes
```

## Paso 4: Desarrollar el rol firewall

`roles/firewall/defaults/main.yml`:
```yaml
---
firewall_services: []
firewall_ports: []
firewall_zone: public
```

`roles/firewall/tasks/main.yml`:
```yaml
---
- name: Habilitar firewalld
  systemd:
    name: firewalld
    state: started
    enabled: yes

- name: Abrir servicios
  firewalld:
    service: "{{ item }}"
    zone: "{{ firewall_zone }}"
    permanent: yes
    state: enabled
    immediate: yes
  loop: "{{ firewall_services }}"
  when: firewall_services | length > 0

- name: Abrir puertos
  firewalld:
    port: "{{ item }}"
    zone: "{{ firewall_zone }}"
    permanent: yes
    state: enabled
    immediate: yes
  loop: "{{ firewall_ports }}"
  when: firewall_ports | length > 0
```

## Paso 5: Playbook que usa los roles

Crear `playbook-roles.yml`:
```yaml
---
- name: Aprovisionar servidores con roles
  hosts: all
  become: yes

  pre_tasks:
    - name: Mostrar inicio
      debug:
        msg: "Iniciando aprovisionamiento de {{ inventory_hostname }}"

  roles:
    - role: common
      common_timezone: Europe/Madrid

- name: Configurar webservers
  hosts: webservers
  become: yes

  roles:
    - role: nginx
      nginx_port: "{{ http_port | default(80) }}"
      nginx_server_name: "{{ inventory_hostname }}"

    - role: firewall
      firewall_services:
        - http
        - https
        - ssh

- name: Configurar databases
  hosts: databases
  become: yes

  roles:
    - role: firewall
      firewall_services:
        - ssh
      firewall_ports:
        - "3306/tcp"

  post_tasks:
    - name: Verificar estado final
      debug:
        msg: "Aprovisionamiento completado en {{ inventory_hostname }}"
```

Ejecutar:
```bash
cd ~/au294
ansible-galaxy role list
ansible-playbook -i inventory playbook-roles.yml --syntax-check
ansible-playbook -i inventory playbook-roles.yml
```

## Paso 6: Ansible Content Collections

Crear `requirements.yml`:
```yaml
---
collections:
  - name: community.general
  - name: ansible.posix
  - name: redhat.rhel_system_roles
```

Instalar:
```bash
ansible-galaxy collection install -r requirements.yml

# Ver colecciones instaladas
ansible-galaxy collection list | head -20
```

## Paso 7: Usar colecciones en playbook

Crear `playbook-colecciones.yml`:
```yaml
---
- name: Usar colecciones
  hosts: all
  become: yes

  collections:
    - ansible.posix

  tasks:
    - name: Configurar limites de archivos con colección
      pam_limits:
        domain: "*"
        limit_type: hard
        limit_item: nofile
        value: 65536

    - name: Configurar sysctl con colección
      sysctl:
        name: net.core.somaxconn
        value: '65535'
        sysctl_set: yes
```

## Paso 8: Red Hat System Roles

Crear `playbook-rhel-system-roles.yml`:
```yaml
---
- name: Usar roles del sistema Red Hat
  hosts: all
  become: yes

  vars:
    timesync_ntp_servers:
      - hostname: 0.pool.ntp.org
        iburst: yes
      - hostname: 1.pool.ntp.org
        iburst: yes
    timesync_ntp_provider: chrony

  roles:
    - redhat.rhel_system_roles.timesync
```

```bash
ansible-playbook playbook-rhel-system-roles.yml
```

## Paso 9: Verificación final

```bash
# Ver nginx funcionando
ansible webservers -m uri -a "url=http://localhost status_code=200"

# Ver paquetes instalados por common
ansible all -m command -a "rpm -q vim git curl htop"

# Ver zona horaria
ansible all -m command -a "timedatectl show --property=Timezone"

# Ver firewall
ansible all -m command -a "firewall-cmd --list-services"

# Ver puertos abiertos
ansible databases -m command -a "firewall-cmd --list-ports"

# Ver NTP funcionando
ansible all -m command -a "chronyc sources -v"
```
