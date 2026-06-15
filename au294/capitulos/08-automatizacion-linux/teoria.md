# Capítulo 8: Automatización de Tareas de Administración Linux

## Gestión de usuarios y grupos

```yaml
- name: Crear grupo
  group:
    name: developers
    gid: 5000
    state: present

- name: Crear usuario con múltiples atributos
  user:
    name: jdoe
    comment: "John Doe"
    uid: 5001
    groups: developers, wheel
    shell: /bin/bash
    create_home: yes
    home: /home/jdoe
    password: "{{ 'pass123' | password_hash('sha512') }}"
    update_password: on_create
    ssh_key_file: .ssh/id_rsa

- name: Eliminar usuario
  user:
    name: olduser
    state: absent
    remove: yes
```

### Configuración SSH

```yaml
- name: Configurar sshd
  template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    mode: '0600'
  notify: reiniciar_sshd

- name: Desplegar claves SSH
  authorized_key:
    user: jdoe
    key: "{{ lookup('file', 'files/jdoe.pub') }}"
    state: present

- name: Copiar clave privada (cifrada)
  copy:
    content: "{{ vault_ssh_private_key }}"
    dest: /home/jdoe/.ssh/id_rsa
    owner: jdoe
    group: jdoe
    mode: '0600'
```

## Gestión de paquetes con repositorios

```yaml
- name: Habilitar repositorio EPEL
  dnf:
    name: "https://dl.fedoraproject.org/pub/epel/epel-release-latest-{{ ansible_distribution_major_version }}.noarch.rpm"
    state: present

- name: Agregar repositorio personalizado
  yum_repository:
    name: myrepo
    description: "My Custom Repository"
    baseurl: https://repo.example.com/rhel/$releasever/$basearch
    enabled: yes
    gpgcheck: yes
    gpgkey: https://repo.example.com/RPM-GPG-KEY

- name: Instalar paquetes con versión específica
  dnf:
    name: "httpd-2.4.57-1.el10"
    state: present

- name: Mantener paquete en versión actual
  dnf:
    name: kernel
    state: present
    update_cache: no
    exclude: kernel*
```

## Gestión de servicios y systemd

```yaml
- name: Configurar unidad systemd personalizada
  copy:
    src: files/myapp.service
    dest: /etc/systemd/system/myapp.service
    mode: '0644'
  notify: recargar_systemd

- name: Habilitar e iniciar servicio
  systemd:
    name: myapp
    state: started
    enabled: yes
    daemon_reload: yes

- name: Enmascarar servicio
  systemd:
    name: cups
    masked: yes
    state: stopped

- name: Crear timer systemd
  copy:
    content: |
      [Unit]
      Description=Backup diario

      [Timer]
      OnCalendar=daily
      Persistent=true

      [Install]
      WantedBy=timers.target
    dest: /etc/systemd/system/backup.timer
    mode: '0644'
```

## Gestión de almacenamiento y LVM

```yaml
- name: Crear partición
  parted:
    device: /dev/sdb
    number: 1
    state: present
    flags: [lvm]
    part_end: "100%"

- name: Crear volumen físico
  lvg:
    vg: vg_data
    pvs: /dev/sdb1

- name: Crear volumen lógico
  lvol:
    vg: vg_data
    lv: lv_data
    size: 10G

- name: Formatear filesystem
  filesystem:
    fstype: xfs
    dev: /dev/vg_data/lv_data

- name: Montar filesystem
  mount:
    path: /data
    src: /dev/vg_data/lv_data
    fstype: xfs
    opts: defaults,noatime
    state: mounted

- name: Crear directorio en montura
  file:
    path: /data/backups
    state: directory
    mode: '0755'
```

## Gestión de SELinux

```yaml
- name: Configurar contexto SELinux
  sefcontext:
    target: /data(/.*)?
    setype: httpd_sys_content_t
    state: present

- name: Aplicar contexto a directorio
  command: restorecon -Rv /data

- name: Habilitar booleano SELinux
  seboolean:
    name: httpd_can_network_connect
    state: yes
    persistent: yes

- name: Configurar SELinux modo
  selinux:
    policy: targeted
    state: enforcing
```

## Gestión de redes

```yaml
- name: Configurar interfaz de red
  nmcli:
    type: ethernet
    conn_name: "System eth0"
    ip4: "192.168.1.100/24"
    gw4: "192.168.1.1"
    dns4:
      - 8.8.8.8
      - 8.8.4.4
    state: present

- name: Agregar ruta estática
  nmcli:
    conn_name: "System eth0"
    routes:
      - "10.0.0.0/8 192.168.1.254"

- name: Configurar hostname
  hostname:
    name: "{{ inventory_hostname }}"
    use: systemd
```

## Gestión de logs y monitorización

```yaml
- name: Configurar rsyslog
  template:
    src: rsyslog.conf.j2
    dest: /etc/rsyslog.conf
  notify: reiniciar_rsyslog

- name: Configurar logrotate
  template:
    src: logrotate.j2
    dest: /etc/logrotate.d/app
    mode: '0644'

- name: Verificar logs
  command: journalctl --since "1 hour ago" -p err
  register: logs
  changed_when: no
```

## Ejemplo completo: deploy de aplicación web

```yaml
---
- name: Deploy completo de aplicación web
  hosts: webservers
  become: yes

  tasks:
    # Almacenamiento
    - name: Crear LVM
      parted: device=/dev/sdb number=1 state=present flags=[lvm]
      lvg: vg=vg_web pvs=/dev/sdb1
      lvol: vg=vg_web lv=lv_web size=5G
      filesystem: fstype=xfs dev=/dev/vg_web/lv_web
      mount: path=/var/www src=/dev/vg_web/lv_web fstype=xfs state=mounted

    # Usuario y grupos
    - name: Crear usuario app
      group: name=webapp gid=3000
      user: name=webapp group=webapp uid=3000 home=/var/www

    # Paquetes
    - name: Instalar dependencias
      dnf:
        name: [httpd, php, php-mysqlnd, mariadb-server]

    # SELinux
    - name: Configurar SELinux
      seboolean: name=httpd_can_network_connect state=yes persistent=yes
      sefcontext: target=/var/www(/.*)? setype=httpd_sys_content_t state=present

    # Red
    - name: Configurar firewall
      firewalld: service=http permanent=yes state=enabled immediate=yes

    # Servicios
    - name: Iniciar servicios
      systemd: name={{ item }} state=started enabled=yes
      loop: [httpd, mariadb]
```
