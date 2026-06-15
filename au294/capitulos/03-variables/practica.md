# Práctica 3: Variables, Facts y Ansible Vault

## Objetivo
Trabajar con variables en múltiples niveles, facts del sistema, y proteger datos sensibles con Ansible Vault.

---

## Paso 1: Variables en inventario

Crear `inventory_vars`:
```ini
[webservers]
rhel-node1 http_port=8080 httpd_server_name="Node 1"

[databases]
rhel-node2

[all:vars]
ansible_user=admin
timezone=Europe/Madrid
```

Crear `group_vars/all.yml`:
```yaml
---
ntp_server: 0.pool.ntp.org
dns_server: 8.8.8.8
```

Crear `group_vars/databases.yml`:
```yaml
---
db_port: 3306
db_name: myapp
```

Crear `host_vars/rhel-node2.yml`:
```yaml
---
db_user: admin
```

Ejecutar:
```bash
ansible-inventory -i inventory_vars --list --yaml
```

## Paso 2: Playbook con variables

Crear `playbook-vars.yml`:
```yaml
---
- name: Demostrar variables
  hosts: all
  become: yes
  vars:
    admin_email: admin@example.com

  tasks:
    - name: Mostrar variables del play
      debug:
        msg:
          - "Host: {{ inventory_hostname }}"
          - "Puerto HTTP: {{ http_port | default('no definido') }}"
          - "Zona horaria: {{ timezone }}"
          - "Email admin: {{ admin_email }}"
          - "Servidor NTP: {{ ntp_server }}"

    - name: Mostrar grupos del host
      debug:
        msg: "Pertenece a: {{ group_names }}"

    - name: Configurar zona horaria
      timezone:
        name: "{{ timezone }}"
```

## Paso 3: Facts del sistema

Crear `playbook-facts.yml`:
```yaml
---
- name: Recopilar facts del sistema
  hosts: all
  gather_facts: yes

  tasks:
    - name: Mostrar facts básicos
      debug:
        msg:
          - "Hostname: {{ ansible_hostname }}"
          - "Sistema: {{ ansible_os_family }} {{ ansible_distribution_version }}"
          - "Kernel: {{ ansible_kernel }}"
          - "Arquitectura: {{ ansible_architecture }}"
          - "IP: {{ ansible_default_ipv4.address }}"
          - "Memoria: {{ ansible_memtotal_mb }} MB"
          - "vCPUs: {{ ansible_processor_vcpus }}"

    - name: Mostrar interfaces de red
      debug:
        var: ansible_interfaces

    - name: Mostrar discos
      debug:
        msg:
          - "Discos: {{ ansible_devices.keys() | list }}"

    - name: Detener si no es RHEL
      fail:
        msg: "Este playbook requiere RHEL"
      when: ansible_os_family != "RedHat"
```

## Paso 4: Facts personalizados

En el nodo gestionado:
```bash
sudo mkdir -p /etc/ansible/facts.d
cat <<EOF | sudo tee /etc/ansible/facts.d/role.fact
[general]
role=webserver
environment=production
backup_enabled=true
EOF
```

En el nodo control:
```bash
ansible rhel-node1 -m setup -a "filter=ansible_local"
```

Crear `playbook-facts-local.yml`:
```yaml
---
- name: Usar facts personalizados
  hosts: all
  tasks:
    - name: Mostrar facts personalizados
      debug:
        msg: "Rol: {{ ansible_local.role.general.role }}, Entorno: {{ ansible_local.role.general.environment }}"
```

## Paso 5: Ansible Vault

```bash
# Crear archivo cifrado
ansible-vault create secret.yml
# Contenido (se abrirá editor):
# ---
# db_password: SuperSecurePass123
# api_key: abc123def456

# Cifrar archivo existente
echo 'db_password: SuperSecurePass123' > credentials.yml
ansible-vault encrypt credentials.yml

# Ver archivo cifrado
ansible-vault view credentials.yml

# Editar archivo cifrado
ansible-vault edit credentials.yml

# Cambiar contraseña
ansible-vault rekey credentials.yml

# Descifrar (temporal)
ansible-vault decrypt credentials.yml
```

Crear `playbook-vault.yml`:
```yaml
---
- name: Usar vault
  hosts: databases
  become: yes
  vars_files:
    - secret.yml
  tasks:
    - name: Mostrar contraseña
      debug:
        msg: "DB Password: {{ db_password }}"

    - name: Crear archivo de configuración con credenciales
      copy:
        content: |
          [database]
          password={{ db_password }}
        dest: /tmp/db.conf
        mode: '0600'
```

Ejecutar:
```bash
ansible-playbook playbook-vault.yml --ask-vault-pass
```

## Paso 6: Precedencia de variables

Crear `playbook-precedencia.yml`:
```yaml
---
- hosts: all
  vars:
    mensaje: "Variable del play"

  tasks:
    - name: Mostrar mensaje
      debug:
        msg: "{{ mensaje }}"
```

```bash
# Probar diferentes niveles de precedencia
ansible-playbook -e "mensaje='Variable extra-args'" playbook-precedencia.yml
```

## Paso 7: Verificación final

```bash
# Crear playbook completo que combine todo
cat << 'EOF' > playbook-consolidado.yml
---
- name: Consolidación de variables y facts
  hosts: all
  vars:
    backup_dir: /backup
    app_user: ansibleapp
  tasks:
    - name: Obtener facts mínimos
      setup:
        gather_subset: min

    - name: Configurar facts personalizados
      blockinfile:
        path: /etc/ansible/facts.d/setup.fact
        create: yes
        block: |
          [custom]
          configured_by={{ ansible_user_id }}
          configured_at={{ ansible_date_time.iso8601 }}
      when: ansible_local.setup is not defined

    - name: Mostrar resumen del host
      debug:
        msg: |
          Host: {{ inventory_hostname }}
          OS: {{ ansible_os_family }} {{ ansible_distribution_version }}
          IP: {{ ansible_default_ipv4.address }}
          Memoria: {{ ansible_memtotal_mb }}MB
          Discos: {{ ansible_devices.keys() | list | join(', ') }}
EOF
```
