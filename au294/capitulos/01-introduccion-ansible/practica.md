# Práctica 1: Introducción a Ansible

## Objetivo
Instalar y configurar Ansible en un nodo control, preparar nodos gestionados y verificar conectividad.

## Escenario
- **Nodo control:** rhel-control (192.168.122.100)
- **Nodo gestionado 1:** rhel-node1 (192.168.122.101)
- **Nodo gestionado 2:** rhel-node2 (192.168.122.102)
- **SO:** RHEL 10
- **Usuario:** admin

---

## Paso 1: Instalar Ansible Core en el nodo control

```bash
# Registrar el sistema (si aplica)
sudo subscription-manager register --auto-attach

# Habilitar repositorios
sudo subscription-manager repos --enable ansible-automation-platform-2.6-for-rhel-10-x86_64-rpms

# Instalar
sudo dnf install -y ansible-core

# Verificar
ansible --version
```

> **Salida esperada:** ansible [core 2.16.x]

## Paso 2: Instalar Ansible Development Tools

```bash
sudo dnf install -y ansible-dev-tools

# Verificar herramientas
ansible-lint --version
ansible-navigator --version
```

## Paso 3: Configurar VS Code (opcional pero recomendado)

```bash
# Instalar extensiones
code --install-extension redhat.ansible
code --install-extension redhat.vscode-yaml
```

## Paso 4: Crear el inventario

```bash
mkdir -p ~/au294/lab && cd ~/au294/lab
```

Crear archivo `inventory`:
```ini
[control]
rhel-control ansible_host=192.168.122.100

[nodes]
rhel-node1 ansible_host=192.168.122.101
rhel-node2 ansible_host=192.168.122.102

[all:vars]
ansible_user=admin
```

## Paso 5: Configurar ansible.cfg

Crear `ansible.cfg`:
```ini
[defaults]
inventory = ./inventory
host_key_checking = False
gathering = smart
retry_files_enabled = False
```

## Paso 6: Preparar nodos gestionados

En cada nodo gestionado:
```bash
# Crear usuario admin
sudo useradd admin
echo 'password' | sudo passwd --stdin admin

# Configurar sudo sin contraseña
echo "admin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/admin

# Asegurar SSH activo
sudo systemctl enable --now sshd
```

En el nodo control, copiar clave SSH:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
ssh-copy-id admin@rhel-node1
ssh-copy-id admin@rhel-node2
```

## Paso 7: Verificar conectividad

```bash
# Ping a todos los hosts
ansible all -m ping

# Obtener facts del sistema
ansible all -m setup -a "gather_subset=minimal"

# Ejecutar comando remoto
ansible nodes -m command -a "uptime"
```

**Salida esperada:**
```
rhel-node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
rhel-node2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Paso 8: Verificación final

```bash
# Mostrar inventario
ansible-inventory --list --yaml

# Verificar configuración
ansible-config dump --only-changed
```

## Resolución de problemas comunes

| Problema | Causa | Solución |
|----------|-------|----------|
| `Permission denied (publickey)` | Clave SSH no autorizada | Ejecutar `ssh-copy-id` |
| `Host key verification failed` | Host key desconocido | Usar `host_key_checking = False` en ansible.cfg |
| `sudo: a password is required` | Sin sudoers NOPASSWD | Verificar archivo en `/etc/sudoers.d/` |
| `Module not found` | Faltan dependencias | `dnf install python3` en nodo gestionado |
