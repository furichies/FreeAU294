# Práctica 8: Automatización de Tareas de Administración Linux

## Objetivo
Automatizar tareas reales de administración: usuarios, almacenamiento, SELinux, red, y servicios systemd.

---

## Paso 1: Gestión de usuarios y SSH

Crear `playbook-users.yml`:
```yaml
---
- name: Gestión de usuarios
  hosts: all
  become: yes

  tasks:
    - name: Crear grupos
      group:
        name: "{{ item }}"
        state: present
      loop:
        - developers
        - ops
        - interns

    - name: Crear usuarios
      user:
        name: "{{ item.name }}"
        uid: "{{ item.uid }}"
        groups: "{{ item.groups }}"
        shell: /bin/bash
        create_home: yes
        password: "{{ 'password123' | password_hash('sha512') }}"
        update_password: on_create
      loop:
        - { name: alice, uid: 5001, groups: developers }
        - { name: bob, uid: 5002, groups: ops }
        - { name: charlie, uid: 5003, groups: interns }

    - name: Configurar sudo para developers
      copy:
        content: "%developers ALL=(ALL) ALL\n"
        dest: /etc/sudoers.d/developers
        mode: '0440'
        validate: /usr/sbin/visudo -cf %s

    - name: Desplegar clave pública
      authorized_key:
        user: "{{ item }}"
        key: "{{ lookup('file', '~/.ssh/id_ed25519.pub') }}"
        state: present
      loop:
        - alice
        - bob
```

```bash
ansible-playbook playbook-users.yml
```

## Paso 2: Gestión de almacenamiento (LVM)

Crear `playbook-storage.yml`:
```yaml
---
- name: Configurar almacenamiento
  hosts: databases
  become: yes

  tasks:
    - name: Verificar disco disponible
      shell: lsblk -o NAME,SIZE,TYPE | grep -E "disk.*[0-9]+G"
      register: disks
      changed_when: no

    - name: Mostrar discos disponibles
      debug:
        var: disks.stdout_lines

    - name: Crear partición LVM
      parted:
        device: /dev/sdb
        number: 1
        flags: [lvm]
        state: present
        part_end: "100%"
      when: disks.stdout != ""

    - name: Crear volumen físico
      lvg:
        vg: vg_data
        pvs: /dev/sdb1
      when: disks.stdout != ""

    - name: Crear volumen lógico
      lvol:
        vg: vg_data
        lv: lv_mysql
        size: 5G
      when: disks.stdout != ""

    - name: Formatear
      filesystem:
        fstype: xfs
        dev: /dev/vg_data/lv_mysql
      when: disks.stdout != ""

    - name: Montar
      mount:
        path: /var/lib/mysql
        src: /dev/vg_data/lv_mysql
        fstype: xfs
        opts: defaults,noatime
        state: mounted
      when: disks.stdout != ""

    - name: Configurar contexto SELinux
      sefcontext:
        target: /var/lib/mysql(/.*)?
        setype: mysqld_db_t
        state: present
      when: disks.stdout != ""

    - name: Aplicar contexto
      command: restorecon -Rv /var/lib/mysql
      when: disks.stdout != ""
```

> **Nota:** Si no tienes discos adicionales, simula con loopback:
> ```bash
> dd if=/dev/zero of=/root/disk.img bs=1M count=1024
> losetup -f /root/disk.img
> ```

## Paso 3: Gestión de SELinux

Crear `playbook-selinux.yml`:
```yaml
---
- name: Configuración SELinux
  hosts: all
  become: yes

  tasks:
    - name: Verificar estado SELinux
      command: getenforce
      register: selinux_status
      changed_when: no

    - name: Mostrar estado
      debug:
        msg: "SELinux está en modo {{ selinux_status.stdout }}"

    - name: Asegurar SELinux enforcing en boot
      selinux:
        policy: targeted
        state: enforcing

    - name: Habilitar booleanos comunes
      seboolean:
        name: "{{ item }}"
        state: yes
        persistent: yes
      loop:
        - httpd_can_network_connect
        - httpd_can_network_connect_db
        - httpd_enable_homedirs
        - httpd_read_user_content

    - name: Configurar contextos personalizados
      sefcontext:
        target: "/opt/app(/.*)?"
        setype: httpd_sys_content_t
        state: present
      notify: restaurar_contexto

  handlers:
    - name: restaurar_contexto
      command: restorecon -Rv /opt/app
```

## Paso 4: Gestión de red

Crear `playbook-network.yml`:
```yaml
---
- name: Configuración de red
  hosts: all
  become: yes

  tasks:
    - name: Configurar hostname
      hostname:
        name: "{{ inventory_hostname }}"
        use: systemd

    - name: Configurar /etc/hosts
      blockinfile:
        path: /etc/hosts
        block: |
          {{ hostvars['rhel-control'].ansible_default_ipv4.address }} rhel-control
          {{ hostvars['rhel-node1'].ansible_default_ipv4.address }} rhel-node1
          {{ hostvars['rhel-node2'].ansible_default_ipv4.address }} rhel-node2
        marker: "# {mark} ANSIBLE MANAGED HOSTS"

    - name: Ver resolución DNS
      command: hostname -f
      register: fqdn
      changed_when: no

    - name: Mostrar FQDN
      debug:
        var: fqdn.stdout
```

## Paso 5: Servicios systemd

Crear `playbook-systemd.yml`:
```yaml
---
- name: Gestión de servicios systemd
  hosts: all
  become: yes

  tasks:
    - name: Deshabilitar servicios innecesarios
      systemd:
        name: "{{ item }}"
        state: stopped
        enabled: no
        masked: yes
      loop:
        - cups
        - avahi-daemon
        - postfix
      ignore_errors: yes

    - name: Crear servicio personalizado
      copy:
        content: |
          [Unit]
          Description=Aplicación personalizada
          After=network.target

          [Service]
          Type=simple
          User=admin
          WorkingDirectory=/opt/app
          ExecStart=/usr/bin/python3 -m http.server 8080
          Restart=on-failure
          RestartSec=5

          [Install]
          WantedBy=multi-user.target
        dest: /etc/systemd/system/app.service
        mode: '0644'
      notify: recargar_systemd

    - name: Iniciar servicio personalizado
      systemd:
        name: app
        state: started
        enabled: yes
        daemon_reload: yes

  handlers:
    - name: recargar_systemd
      systemd:
        daemon_reload: yes
```

## Paso 6: Automatización completa — deploy LAMP

Crear `playbook-lamp.yml`:
```yaml
---
- name: Deploy LAMP completo
  hosts: webservers
  become: yes

  vars:
    db_name: wordpress
    db_user: wpuser
    db_password: "{{ vault_db_password | default('ChangeMe123!') }}"

  tasks:
    # Packages
    - name: Instalar LAMP stack
      dnf:
        name:
          - httpd
          - mariadb-server
          - php
          - php-mysqlnd
          - php-fpm
        state: present

    # Services
    - name: Iniciar servicios base
      systemd:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - httpd
        - mariadb

    # Database
    - name: Crear base de datos
      mysql_db:
        name: "{{ db_name }}"
        state: present
        login_unix_socket: /var/lib/mysql/mysql.sock

    - name: Crear usuario MySQL
      mysql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        priv: "{{ db_name }}.*:ALL"
        state: present
        login_unix_socket: /var/lib/mysql/mysql.sock

    # SELinux
    - name: Configurar booleanos SELinux
      seboolean:
        name: "{{ item }}"
        state: yes
        persistent: yes
      loop:
        - httpd_can_network_connect_db
        - httpd_can_network_connect

    # Content
    - name: Crear index.php
      copy:
        content: |
          <?php
          echo "<h1>LAMP Stack en {{ ansible_hostname }}</h1>";
          echo "<p>IP: {{ ansible_default_ipv4.address }}</p>";
          echo "<p>PHP: " . phpversion() . "</p>";

          $conn = new mysqli("localhost", "{{ db_user }}", "{{ db_password }}", "{{ db_name }}");
          if ($conn->connect_error) {
              echo "<p>MySQL: Error de conexión</p>";
          } else {
              echo "<p>MySQL: Conexión exitosa</p>";
              $conn->close();
          }
          ?>
        dest: /var/www/html/index.php
        mode: '0644'

    # Firewall
    - name: Abrir puertos en firewall
      firewalld:
        service: "{{ item }}"
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - http
        - https

    - name: Verificar aplicación
      uri:
        url: http://localhost/index.php
        status_code: 200
      register: app_check

    - name: Mostrar resultado
      debug:
        msg: "App funcionando correctamente"
```

## Paso 7: Verificación final

```bash
# Verificar usuarios
ansible all -m command -a "getent passwd alice bob charlie"

# Verificar storage
ansible databases -m command -a "df -h /var/lib/mysql"

# Verificar SELinux
ansible all -m command -a "getenforce"
ansible all -m command -a "getsebool httpd_can_network_connect"

# Verificar servicios
ansible all -m command -a "systemctl status httpd --no-pager -l"

# Verificar app LAMP
curl http://rhel-node1/index.php

# Verificar conectividad red
ansible all -m command -a "ping -c 1 rhel-control"
```
