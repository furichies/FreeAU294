# Práctica 2: Desarrollo de Contenido de Automatización

## Objetivo
Crear inventarios, escribir playbooks básicos con módulos esenciales, y ejecutar comandos ad-hoc.

## Prerrequisitos
- Laboratorio del Capítulo 1 funcionando

---

## Paso 1: Inventario en múltiples formatos

Crear `inventory_ini`:
```ini
[webservers]
rhel-node1

[databases]
rhel-node2

[all:vars]
ansible_user=admin
```

Crear `inventory_yaml`:
```yaml
---
all:
  children:
    webservers:
      hosts:
        rhel-node1:
    databases:
      hosts:
        rhel-node2:
  vars:
    ansible_user: admin
```

Verificar ambos:
```bash
ansible-inventory -i inventory_ini --list
ansible-inventory -i inventory_yaml --list
```

## Paso 2: Comandos ad-hoc

```bash
# 1. Ping
ansible all -i inventory_ini -m ping

# 2. Información del sistema
ansible all -m setup -a "gather_subset=!all,!min"

# 3. Instalar paquetes con dnf
ansible webservers -m dnf -a "name=httpd,mod_ssl state=present" -b

# 4. Verificar instalación
ansible webservers -m command -a "rpm -q httpd mod_ssl"

# 5. Gestionar servicio
ansible webservers -m systemd -a "name=httpd state=started enabled=yes" -b

# 6. Crear directorio
ansible all -m file -a "path=/opt/lab state=directory mode=0755 owner=admin" -b

# 7. Copiar archivo
echo "Hello Ansible" > /tmp/hello.txt
ansible all -m copy -a "src=/tmp/hello.txt dest=/opt/lab/hello.txt mode=0644" -b
```

## Paso 3: Primer playbook

Crear `playbook-basico.yml`:
```yaml
---
- name: Configurar servidor web
  hosts: webservers
  become: yes
  tasks:
    - name: Instalar httpd
      dnf:
        name: httpd
        state: present

    - name: Crear index.html
      copy:
        content: "<h1>Bienvenido a {{ inventory_hostname }}</h1>"
        dest: /var/www/html/index.html
        mode: '0644'

    - name: Iniciar y habilitar httpd
      systemd:
        name: httpd
        state: started
        enabled: yes

    - name: Abrir puerto 80 en firewall
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes
```

Ejecutar:
```bash
ansible-playbook -i inventory_ini playbook-basico.yml --syntax-check
ansible-playbook -i inventory_ini playbook-basico.yml
```

Verificar:
```bash
curl http://rhel-node1
```

## Paso 4: Playbook con handlers y módulos adicionales

Crear `playbook-completo.yml`:
```yaml
---
- name: Configuración completa de servidor
  hosts: all
  become: yes
  vars:
    admin_user: jdoe
    admin_public_key: "{{ lookup('file', '~/.ssh/id_ed25519.pub') }}"

  tasks:
    - name: Crear usuario administrador
      user:
        name: "{{ admin_user }}"
        groups: wheel
        shell: /bin/bash
        create_home: yes

    - name: Configurar clave SSH para admin
      authorized_key:
        user: "{{ admin_user }}"
        key: "{{ admin_public_key }}"

    - name: Configurar sudo sin contraseña
      copy:
        content: "{{ admin_user }} ALL=(ALL) NOPASSWD:ALL"
        dest: "/etc/sudoers.d/{{ admin_user }}"
        mode: '0440'
        validate: /usr/sbin/visudo -cf %s

    - name: Instalar herramientas comunes
      dnf:
        name:
          - vim
          - git
          - curl
          - tree
        state: present

    - name: Configurar /etc/motd
      copy:
        content: |
          ╔══════════════════════════════════╗
          ║  Gestionado por Ansible          ║
          ╚══════════════════════════════════╝
        dest: /etc/motd
        mode: '0644'
```

Ejecutar y verificar:
```bash
ansible-playbook -i inventory_ini playbook-completo.yml
ansible all -m command -a "cat /etc/motd"
```

## Paso 5: Uso de patrones de hosts

```bash
# Todos los hosts
ansible all -m command -a "hostname"

# Solo webservers
ansible webservers -m command -a "hostname"

# Todos excepto databases
ansible all:!databases -m command -a "hostname"

# Solo un host específico
ansible rhel-node1 -m command -a "hostname"
```

## Paso 6: Verificación final

```bash
# Listar tareas de un playbook
ansible-playbook playbook-completo.yml --list-tasks

# Listar hosts afectados
ansible-playbook playbook-completo.yml --list-hosts

# Ejecución en seco (check mode)
ansible-playbook playbook-completo.yml -C

# Ejecución con verbosidad
ansible-playbook playbook-completo.yml -v
```
