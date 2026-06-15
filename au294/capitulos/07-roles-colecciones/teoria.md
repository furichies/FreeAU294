# Capítulo 7: Roles y Ansible Content Collections

## Roles

### Estructura de un rol

```
rol_ejemplo/
├── defaults/         # Variables por defecto (baja prioridad)
│   └── main.yml
├── vars/             # Variables del rol (alta prioridad)
│   └── main.yml
├── tasks/            # Tareas principales
│   └── main.yml
├── handlers/         # Handlers del rol
│   └── main.yml
├── templates/        # Plantillas Jinja2
│   └── *.j2
├── files/            # Archivos estáticos
│   └── *.conf
├── meta/             # Metadatos y dependencias
│   └── main.yml
├── library/          # Módulos personalizados
├── lookup_plugins/   # Plugins lookup
├── module_utils/     # Utilidades para módulos
└── README.md
```

### Crear un rol con ansible-galaxy

```bash
ansible-galaxy role init --init-path roles nginx

# Estructura generada:
# roles/
# └── nginx/
#     ├── defaults/
#     ├── vars/
#     ├── tasks/
#     ├── handlers/
#     ├── templates/
#     ├── files/
#     └── meta/
```

### Ejemplo de rol nginx

`roles/nginx/defaults/main.yml`:
```yaml
---
nginx_port: 80
nginx_user: nginx
nginx_worker_processes: "{{ ansible_processor_vcpus }}"
nginx_enable_ssl: false
nginx_ssl_cert: /etc/pki/tls/certs/server.crt
nginx_ssl_key: /etc/pki/tls/private/server.key
```

`roles/nginx/tasks/main.yml`:
```yaml
---
- name: Instalar nginx
  dnf:
    name: nginx
    state: present

- name: Configurar nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    mode: '0644'
  notify: reiniciar_nginx

- name: Iniciar y habilitar nginx
  systemd:
    name: nginx
    state: started
    enabled: yes
```

`roles/nginx/handlers/main.yml`:
```yaml
---
- name: reiniciar_nginx
  systemd:
    name: nginx
    state: restarted
```

### Usar roles en playbooks

```yaml
---
- name: Aplicar roles
  hosts: webservers
  become: yes

  roles:
    - role: nginx
      nginx_port: 8080
      nginx_enable_ssl: true

    - role: common
      common_timezone: Europe/Madrid

  # También se pueden usar roles con tareas (post_tasks)
  post_tasks:
    - name: Verificar estado
      uri:
        url: http://localhost:{{ nginx_port }}
        status_code: 200
```

### Orden de ejecución

```
pre_tasks (antes que roles)
  ↓
roles
  ↓
tasks (después de roles)
  ↓
post_tasks (después de tasks)
  ↓
handlers (al final)
```

### Dependencias entre roles

`roles/nginx/meta/main.yml`:
```yaml
---
dependencies:
  - role: common
  - role: epel
    epel_release: "{{ ansible_distribution_major_version }}"
```

## Ansible Content Collections

### ¿Qué son?

Paquetes que agrupan roles, módulos, plugins y documentación. Reemplazan el modelo tradicional de roles sueltos.

```
ansible.builtin/       # Colección oficial de Ansible Core
community.general/     # Mantenida por la comunidad
redhat.rhel_system_roles/  # Roles oficiales de Red Hat
```

### Instalar colecciones

```bash
# Desde Ansible Galaxy
ansible-galaxy collection install community.general

# Desde archivo de requisitos
ansible-galaxy collection install -r requirements.yml

# Especificar versión
ansible-galaxy collection install community.general:==9.0.0
```

`requirements.yml`:
```yaml
---
collections:
  - name: community.general
    version: ">=9.0.0"
  - name: ansible.posix
  - name: redhat.rhel_system_roles
```

### Usar colecciones en playbooks

```yaml
---
- name: Usar colecciones
  hosts: all
  become: yes

  collections:
    - community.general
    - ansible.posix

  tasks:
    - name: Usar módulo de colección
      community.general.nginx_config:
        name: default
        state: present

    - name: Sin especificar namespace (por collections arriba)
      nginx_config:
        name: default
        state: present

    - name: Usando FQCN completo
      ansible.posix.acl:
        path: /opt/app
        entity: admin
        etype: user
        permissions: rwx
        state: present
```

### Red Hat System Roles

Colección oficial de Red Hat con roles validados:

```bash
ansible-galaxy collection install redhat.rhel_system_roles
```

```yaml
---
- hosts: all
  become: yes
  vars:
    timesync_ntp_servers:
      - hostname: 0.pool.ntp.org
        iburst: yes
      - hostname: 1.pool.ntp.org
        iburst: yes

  roles:
    - redhat.rhel_system_roles.timesync
    - redhat.rhel_system_roles.firewall
```

## Construir y compartir colecciones

```
mi_coleccion/
├── galaxy.yml          # Metadatos
├── README.md
├── roles/
│   └── mi_rol/
└── plugins/
    ├── modules/
    └── lookup/
```

`galaxy.yml`:
```yaml
---
namespace: miempresa
name: infra
version: 1.0.0
authors:
  - Mi Nombre
description: Colección de automatización de infraestructura
dependencies:
  community.general: ">=9.0.0"
  ansible.posix: "*"
```

```bash
# Construir
ansible-galaxy collection build

# Publicar (requiere token)
ansible-galaxy collection publish miempresa-infra-1.0.0.tar.gz
```
