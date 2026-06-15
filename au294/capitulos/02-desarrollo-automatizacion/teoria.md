# Capítulo 2: Desarrollo de Contenido de Automatización

## Inventarios

### Inventario estático en INI

```ini
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com

[atlanta:children]
webservers
databases

[atlanta:vars]
ntp_server=ntp.atlanta.example.com
```

### Inventario estático en YAML

```yaml
---
all:
  children:
    webservers:
      hosts:
        web1.example.com:
          http_port: 8080
        web2.example.com:
    databases:
      hosts:
        db1.example.com:
    atlanta:
      children:
        webservers:
        databases:
      vars:
        ntp_server: ntp.atlanta.example.com
```

### Patrones de hosts

| Patrón | Descripción |
|--------|-------------|
| `all` | Todos los hosts del inventario |
| `web*` | Hosts que empiezan por "web" |
| `webservers:databases` | Unión de grupos |
| `webservers:!web1` | Diferencia (webservers menos web1) |
| `webservers:&production` | Intersección |
| `~^(web\|db).*\.example\.com$` | Expresión regular |

## Módulos esenciales

### Gestión de paquetes (dnf)
```yaml
- name: Instalar paquetes
  dnf:
    name:
      - httpd
      - mod_ssl
    state: present

- name: Actualizar todos los paquetes
  dnf:
    name: "*"
    state: latest
```

### Gestión de servicios (systemd)
```yaml
- name: Iniciar y habilitar servicio
  systemd:
    name: httpd
    state: started
    enabled: yes

- name: Recargar servicio
  systemd:
    name: httpd
    state: reloaded
```

### Gestión de archivos (copy)
```yaml
- name: Copiar archivo
  copy:
    src: /local/archivo.conf
    dest: /etc/archivo.conf
    owner: root
    group: root
    mode: '0644'
```

### Gestión de usuarios (user)
```yaml
- name: Crear usuario
  user:
    name: jdoe
    groups: wheel
    shell: /bin/bash
    create_home: yes
```

### Gestión de firewalld
```yaml
- name: Abrir puerto en firewall
  firewalld:
    port: 8080/tcp
    permanent: yes
    state: enabled
    immediate: yes
```

## Playbooks: estructura y sintaxis

### Anatomía de un playbook

```yaml
---
- name: Título del play
  hosts: webservers
  become: yes
  vars:
    http_port: 8080

  tasks:
    - name: Tarea 1
      dnf:
        name: httpd
        state: present

    - name: Tarea 2
      template:
        src: httpd.conf.j2
        dest: /etc/httpd/conf/httpd.conf
      notify: reiniciar httpd

  handlers:
    - name: reiniciar httpd
      systemd:
        name: httpd
        state: restarted
```

### Componentes de un play

| Elemento | Descripción |
|----------|-------------|
| `name` | Descripción del play (opcional pero recomendada) |
| `hosts` | Patrón de hosts sobre los que actuar |
| `become` | Escalar privilegios (sudo) |
| `vars` | Variables locales al play |
| `tasks` | Lista de tareas a ejecutar |
| `handlers` | Tareas especiales que se ejecutan solo si se les notifica |

### Módulos de depuración

```yaml
- name: Depurar mensaje
  debug:
    msg: "El puerto es {{ http_port }}"

- name: Depurar variable
  debug:
    var: ansible_os_family
```

## Comandos ad-hoc

```bash
# Reboot diferido de varios hosts
ansible all -m reboot -a "reboot_timeout=300"

# Verificar espacio en disco
ansible all -m command -a "df -h"

# Crear directorio en todos los nodos
ansible nodes -m file -a "path=/opt/app state=directory mode=0755"

# Instalar paquete
ansible webservers -m dnf -a "name=httpd state=latest" -b
```

## Troubleshooting básico

```bash
# Verificar sintaxis
ansible-playbook playbook.yml --syntax-check

# Ejecución en seco
ansible-playbook playbook.yml -C

# Modo verbose
ansible-playbook playbook.yml -v     # tareas exitosas
ansible-playbook playbook.yml -vv    # más detalle
ansible-playbook playbook.yml -vvvv  # conexión SSH incluida

# Ver tareas que se ejecutarían
ansible-playbook playbook.yml --list-tasks

# Ver hosts afectados
ansible-playbook playbook.yml --list-hosts
```
