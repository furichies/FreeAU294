#!/bin/bash
# =============================================================================
# 00-setup-control-node.sh - Configurar el nodo de control Ansible
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

CONTROL_HOST="${CONTROL_HOST:-10.10.10.10}"
MANAGED_HOSTS=("10.10.10.11" "10.10.10.12" "10.10.10.13")
SSH_KEY_PATH="${HOME}/.ssh/id_rsa_au294"

echo ""
echo "=============================================="
echo "  CONFIGURACIÓN DEL NODO DE CONTROL"
echo "  AU294 - Ansible Automation"
echo "=============================================="
echo ""

log_info "Instalando Ansible..."
if command -v ansible &> /dev/null; then
    echo "  Ansible ya instalado: $(ansible --version | head -1)"
else
    dnf install -y ansible-core pybluez python3-pip 2>/dev/null || pip3 install ansible || echo "Instala Ansible manualmente"
fi

log_info "Creando directorio de trabajo..."
mkdir -p ~/ansible-au294/{playbooks,roles,inventory,scripts}
cd ~/ansible-au294

log_info "Generando clave SSH..."
if [ -f "$SSH_KEY_PATH" ]; then
    echo "  Clave SSH ya existe"
else
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "au294-lab-key"
fi

log_info "Distribuyendo clave pública a nodos gestionados..."
for host in "${MANAGED_HOSTS[@]}"; do
    echo "  Copiando clave a $host..."
    ssh-copy-id -i "${SSH_KEY_PATH}.pub" "-o StrictHostKeyChecking=no" "root@$host" 2>/dev/null || \
    sshpass -p 'root' ssh-copy-id -i "${SSH_KEY_PATH}.pub" "-o StrictHostKeyChecking=no" "root@$host" 2>/dev/null || \
    echo "  Advertencia: No se pudo copiar clave a $host (configura manualmente)"
done

log_info "Copiando archivos de configuración..."
if [ -f "/root/ansible-au294/ansible.cfg" ]; then
    cp /root/ansible-au294/ansible.cfg ~/ansible-au294/
fi
if [ -f "/root/ansible-au294/inventory/inventory.ini" ]; then
    cp -r /root/ansible-au294/inventory/* ~/ansible-au294/inventory/ 2>/dev/null || true
fi

log_info "Verificando conectividad..."
ansible all -i inventory -m ping --diff 2>/dev/null || echo "Verifica inventario y red"

log_success "Nodo de control configurado"
echo ""
echo "  Directorio de trabajo: ~/ansible-au294"
echo "  Ejecuta: cd ~/ansible-au294"
echo ""
