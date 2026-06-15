# Capítulo 5: Despliegue de Archivos

## Módulo copy

```yaml
- name: Copiar archivo estático
  copy:
    src: files/archivo.conf
    dest: /etc/app/archivo.conf
    owner: root
    group: root
    mode: '0644'

- name: Copiar con contenido inline
  copy:
    content: |
      # Configuración generada por Ansible
      port={{ app_port }}
      host={{ ansible_default_ipv4.address }}
    dest: /etc/app/app.conf
    mode: '0644'

- name: Copiar directorio recursivo
  copy:
    src: files/config/
    dest: /etc/app/config/
    owner: app
    group: app
    mode: preserve
```

## Módulo template (Jinja2)

### Sintaxis básica de plantilla

```jinja2
{# templates/app.conf.j2 #}
# Generado: {{ ansible_date_time.date }}
# Host: {{ inventory_hostname }}

[server]
port = {{ app_port }}
host = {{ ansible_default_ipv4.address }}
debug = {{ debug_mode | default(false) }}

{% if database_enabled %}
[database]
host = {{ db_host }}
port = {{ db_port | default(3306) }}
name = {{ db_name }}
{% endif %}

{% for user in app_users %}
user_{{ user.name }} = {{ user.role }}
{% endfor %}
```

### Uso en playbook

```yaml
- name: Desplegar configuración desde plantilla
  template:
    src: templates/app.conf.j2
    dest: /etc/app/app.conf
    owner: app
    group: app
    mode: '0644'
  vars:
    app_port: 8080
    debug_mode: true
    database_enabled: yes
    db_host: localhost
    db_port: 3306
    db_name: myapp
    app_users:
      - { name: alice, role: admin }
      - { name: bob, role: viewer }
```

## Módulos fetch, blockinfile, lineinfile

### fetch — Descargar archivo del nodo gestionado

```yaml
- name: Descargar log al nodo control
  fetch:
    src: /var/log/app.log
    dest: logs/{{ inventory_hostname }}/app.log
    flat: no
```

### blockinfile — Insertar/actualizar bloque de texto

```yaml
- name: Añadir bloque de configuración
  blockinfile:
    path: /etc/hosts
    block: |
      192.168.1.100  backup-server
      192.168.1.101  monitoring-server
    marker: "# {mark} ANSIBLE MANAGED BLOCK - INFRA"

- name: Actualizar bloque existente
  blockinfile:
    path: /etc/hosts
    block: |
      192.168.1.100  backup-server.example.com
    marker: "# {mark} ANSIBLE MANAGED BLOCK - INFRA"
```

### lineinfile — Gestionar líneas individuales

```yaml
- name: Asegurar línea existe
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PermitRootLogin'
    line: 'PermitRootLogin no'
    backup: yes

- name: Añadir línea si no existe
  lineinfile:
    path: /etc/selinux/config
    line: 'SELINUX=enforcing'
    regexp: '^SELINUX='
```

## Módulo file — Atributos y estado

```yaml
- name: Crear directorio
  file:
    path: /opt/app
    state: directory
    owner: app
    group: app
    mode: '0755'

- name: Crear enlace simbólico
  file:
    src: /opt/app/current
    dest: /opt/app/releases/v2
    state: link

- name: Asegurar permisos de archivo
  file:
    path: /opt/app/config.yml
    owner: app
    group: app
    mode: '0600'

- name: Eliminar archivo
  file:
    path: /tmp/old.log
    state: absent
```

## Jinja2 avanzado

### Filtros útiles en plantillas

```jinja2
{{ 'texto' | upper }}
{{ 'TEXTO' | lower }}
{{ ['a', 'b', 'c'] | join(', ') }}
{{ 1024 * 1024 | filesizeformat }}
{{ variable | default('por_defecto') }}
{{ password | password_hash('sha512') }}

# Bucle con índice
{% for user in users %}
{{ loop.index }}. {{ user.name }}
{% endfor %}

# Condiciones en plantilla
{{ 'activo' if enabled else 'inactivo' }}
```

### Multilínea y herencia

```jinja2
{# Uso de raw/endraw para código literal #}
{% raw %}
Esto es texto literal {{ sin_evaluar }}
{% endraw %}
```

## Módulo stat — Estado de archivos

```yaml
- name: Obtener estado de archivo
  stat:
    path: /etc/passwd
  register: passwd_stat

- name: Mostrar información
  debug:
    msg:
      - "Existe: {{ passwd_stat.stat.exists }}"
      - "Tamaño: {{ passwd_stat.stat.size }}"
      - "Modo: {{ passwd_stat.stat.mode }}"
      - "Checksum: {{ passwd_stat.stat.checksum }}"
```
