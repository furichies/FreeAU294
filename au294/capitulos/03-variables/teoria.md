# Capítulo 3: Variables

## Declaración de variables

### En un playbook
```yaml
---
- hosts: all
  vars:
    http_port: 8080
    server_name: "{{ ansible_fqdn }}"
    packages:
      - httpd
      - mod_ssl
```

### En un archivo externo
```yaml
# vars/webserver.yml
http_port: 8080
server_admin: admin@example.com
```

```yaml
# playbook.yml
- hosts: webservers
  vars_files:
    - vars/webserver.yml
```

### En el inventario
```ini
[webservers]
web1 http_port=8080
web2 http_port=8081

[webservers:vars]
ntp_server=ntp.example.com
```

### En group_vars y host_vars
```
inventory/
├── group_vars/
│   ├── all.yml
│   ├── webservers.yml
│   └── databases.yml
└── host_vars/
    ├── web1.yml
    └── db1.yml
```

## Precedencia de variables (de menor a mayor)

1. Valores por defecto de roles
2. `group_vars/all`
3. `group_vars/*` (grupo específico)
4. `host_vars/*`
5. Inventario (INI vars)
6. `vars_files`
7. `vars` en el play
8. `vars_prompt`
9. Variables pasadas con `--extra-vars` (máxima prioridad)

## Facts del sistema

Ansible recopila información de los nodos gestionados mediante el módulo `setup`.

```yaml
- name: Mostrar facts comunes
  debug:
    msg:
      - "IP: {{ ansible_default_ipv4.address }}"
      - "OS: {{ ansible_os_family }} {{ ansible_distribution_version }}"
      - "Memoria: {{ ansible_memtotal_mb }} MB"
      - "Arquitectura: {{ ansible_architecture }}"
      - "Hostname: {{ ansible_hostname }}"
      - "Interfaces: {{ ansible_interfaces }}"
```

### Facts personalizados

Colocar archivos `.fact` en `/etc/ansible/facts.d/`:

```ini
# /etc/ansible/facts.d/server_role.fact
[server]
role=webserver
environment=production
```

Se acceden como `ansible_local.server_role.server.role`.

## Variables mágicas

Son variables especiales que Ansible proporciona automáticamente:

```yaml
- name: Mostrar variables mágicas
  debug:
    msg:
      - "Host inventario: {{ inventory_hostname }}"
      - "Grupos del host: {{ group_names }}"
      - "Todos los hosts: {{ groups.all }}"
      - "Hosts en webservers: {{ groups.webservers }}"
      - "Hosts del play: {{ ansible_play_hosts }}"
      - "Directorio del playbook: {{ playbook_dir }}"
```

## Ansible Vault

### Crear archivos cifrados

```bash
ansible-vault create secret.yml
ansible-vault encrypt vars/credentials.yml
```

### Usar archivos cifrados

```bash
# Pedir contraseña
ansible-playbook playbook.yml --ask-vault-pass

# Archivo con contraseña
ansible-playbook playbook.yml --vault-password-file vault-pass

# Múltiples vaults
ansible-playbook playbook.yml --vault-id dev@dev-pass --vault-id prod@prod-pass
```

### Ejemplo en playbook

```yaml
- name: Usar vault
  hosts: all
  vars_files:
    - vars/credentials.yml
  tasks:
    - name: Crear usuario con contraseña desde vault
      user:
        name: "{{ app_user }}"
        password: "{{ app_password | password_hash('sha512') }}"
```

## Filtros de variables

| Filtro | Ejemplo | Resultado |
|--------|---------|-----------|
| `default` | `{{ variable \| default('valor') }}` | Valor por defecto |
| `upper` | `{{ 'hola' \| upper }}` | `HOLA` |
| `lower` | `{{ 'HOLA' \| lower }}` | `hola` |
| `password_hash` | `{{ 'pass' \| password_hash('sha512') }}` | Hash SHA-512 |
| `ipaddr` | `{{ '192.168.1.1' \| ipaddr }}` | Validación IP |
| `bool` | `{{ 'yes' \| bool }}` | `True` |
| `to_json` / `to_yaml` | `{{ var \| to_json }}` | Conversión formato |
| `b64encode` | `{{ 'texto' \| b64encode }}` | Base64 |
