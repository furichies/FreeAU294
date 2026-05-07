#!/bin/bash
# =============================================================================
# setup-proxmox-lab.sh - Configurar infraestructura de laboratorio AU294
# =============================================================================
# Este script automatiza la creación del laboratorio de prácticas para el
# curso AU294: Red Hat Enterprise Linux Automation with Ansible
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# CONFIGURACIÓN - MODIFICAR SEGÚN TU ENTORNO
# -----------------------------------------------------------------------------
PROXMOX_HOST="${PROXMOX_HOST:-localhost}"
PROXMOX_USER="${PROXMOX_USER:-root@pam}"
PROXMOX_PASSWORD="${PROXMOX_PASSWORD:-tu_password}"
PROXMOX_NODE="${PROXMOX_NODE:-pve}"
PROXMOX_STORAGE="${PROXMOX_STORAGE:-local-lvm}"
PROXMOX_API_PORT="${PROXMOX_API_PORT:-8006}"
TEMPLATE_ID="${TEMPLATE_ID:-9000}"
TEMPLATE_NAME="${TEMPLATE_NAME:-template-centos9}"
LAB_BRIDGE="${LAB_BRIDGE:-vmbr1}"
LAB_NETWORK="${LAB_NETWORK:-10.10.10.0/24}"
DNS_SERVER="${DNS_SERVER:-8.8.8.8}"
GATEWAY="${GATEWAY:-10.10.10.1}"

# Configuración de VMs
declare -A VM_CONFIG
VM_CONFIG["ansible-control"]="2,2048,20,10.10.10.10"
VM_CONFIG["managed-node-01"]="2,2048,20,10.10.10.11"
VM_CONFIG["managed-node-02"]="2,2048,20,10.10.10.12"
VM_CONFIG["managed-node-03"]="2,2048,20,10.10.10.13"

# -----------------------------------------------------------------------------
# COLORES Y FUNCIONES DE UTILIDAD
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# -----------------------------------------------------------------------------
# VERIFICACIÓN DE PRERREQUISITOS
# -----------------------------------------------------------------------------
check_dependencies() {
    log_info "Verificando dependencias..."
    for cmd in curl qm pct; do
        if ! command -v $cmd &> /dev/null; then
            log_warn "Comando '$cmd' no encontrado. Asegúrate de estar en el nodo Proxmox."
        fi
    done
}

# -----------------------------------------------------------------------------
# AUTENTICACIÓN PROXMOX API
# -----------------------------------------------------------------------------
get_proxmox_ticket() {
    log_info "Obteniendo ticket de autenticación de Proxmox..."
    local auth_response
    auth_response=$(curl -s -k -data "username=$PROXMOX_USER&password=$PROXMOX_PASSWORD" \
        "https://$PROXMOX_HOST:$PROXMOX_API_PORT/api2/json/access/ticket")

    if echo "$auth_response" | grep -q "data"; then
        TICKET=$(echo "$auth_response" | jq -r '.data.ticket')
        CSRF_TOKEN=$(echo "$auth_response" | jq -r '.data.CSRFPreventionToken')
        log_success "Autenticación exitosa"
    else
        log_error "Fallo en la autenticación. Verifica credenciales."
    fi
}

# -----------------------------------------------------------------------------
# CREACIÓN DEL BRIDGE DE RED
# -----------------------------------------------------------------------------
create_bridge() {
    log_info "Configurando bridge de red $LAB_BRIDGE..."

    local bridge_exists
    bridge_exists=$(pvesh get /cluster/config/nodes/$PROXMOX_NODE/network \
        --output-format=json 2>/dev/null | jq -r ".[] | select(.iface==\"$LAB_BRIDGE\") | .iface" || echo "")

    if [ "$bridge_exists" = "$LAB_BRIDGE" ]; then
        log_warn "Bridge $LAB_BRIDGE ya existe. Omitiendo creación."
    else
        cat >> /etc/network/interfaces <<EOF

# Bridge para laboratorio AU294
auto $LAB_BRIDGE
iface $LAB_BRIDGE inet static
    address ${LAB_NETWORK%.*}.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
EOF
        ifdown $LAB_BRIDGE 2>/dev/null || true
        ifup $LAB_BRIDGE
        log_success "Bridge $LAB_BRIDGE creado"
    fi
}

# -----------------------------------------------------------------------------
# DESCARGA O CREACIÓN DE PLANTILLA
# -----------------------------------------------------------------------------
prepare_template() {
    log_info "Verificando plantilla..."

    if pct list | grep -q "$TEMPLATE_NAME"; then
        log_warn "Plantilla $TEMPLATE_NAME ya existe. Omitiendo."
    else
        log_info "Descargando imagen base CentOS Stream 9..."
        local cloud_image_url="https://cloud.centos.org/centos/9-stream/CTemplates/"
        local image_file="/tmp/centos9-base.qcow2"

        if [ ! -f "$image_file" ]; then
            curl -L -o "$image_file" \
                "https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2" \
                --progress-bar || log_warn "Descarga fallida, intentando método alternativo"
        fi

        if [ -f "$image_file" ]; then
            log_info "Importando imagen como contenedor LXC..."
            pct import "$image_file" "$TEMPLATE_NAME" "$PROXMOX_STORAGE" || true
        else
            log_warn "No se pudo descargar imagen. Crea la plantilla manualmente."
        fi
    fi
}

# -----------------------------------------------------------------------------
# CREACIÓN DE VMs
# -----------------------------------------------------------------------------
create_vms() {
    log_info "Creando máquinas virtuales del laboratorio..."

    for vm_name in "${!VM_CONFIG[@]}"; do
        local config="${VM_CONFIG[$vm_name]}"
        IFS=',' read -r vcpus memory disk_size ip_addr <<< "$config"

        if qm list | grep -q "$vm_name"; then
            log_warn "VM $vm_name ya existe. Omitiendo."
            continue
        fi

        local vm_id
        vm_id=$(qm list | awk 'NR>2 {print $1}' | sort -n | tail -1)
        vm_id=$((vm_id + 1))

        log_info "Creando $vm_name (ID: $vm_id)..."

        qm clone "$TEMPLATE_ID" "$vm_id" -name "$vm_name" -full

        qm set "$vm_id" \
            --cores "$vcpus" \
            --memory "$memory" \
            --net0 "virtio,bridge=$LAB_BRIDGE" \
            --ostype l26 \
            --agent 1

        qm resize "$vm_id" rootfs "${disk_size}G"

        log_success "VM $vm_name creada con ID $vm_id"
    done
}

# -----------------------------------------------------------------------------
# CONFIGURACIÓN POST-VM (DNS, SSH, etc.)
# -----------------------------------------------------------------------------
configure_vms() {
    log_info "Configurando VMs después del despliegue..."

    for vm_name in "${!VM_CONFIG[@]}"; do
        local config="${VM_CONFIG[$vm_name]}"
        IFS=',' read -r vcpus memory disk_size ip_addr <<< "$config"
        local vm_id
        vm_id=$(qm list | grep "$vm_name" | awk '{print $1}')

        [ -z "$vm_id" ] && continue

        log_info "Configurando red estática en $vm_name..."
        qm run "$vm_id" bash -c "cat > /etc/NetworkManager/system-connections/eth1.nmconnection <<EOF
[connection]
id=eth1
type=ethernet
interface-name=eth1
autoconnect-priority=100

[ipv4]
method=manual
address1=$ip_addr/24
gateway=$GATEWAY
dns=$DNS_SERVER
dns-search=
EOF
systemctl restart NetworkManager" 2>/dev/null || true

        log_info "Instalando Ansible en $vm_name..."
        qm run "$vm_id" bash -c "curl -s https://bootstrap.pypa.io/get-pip.py | python3 && pip3 install ansible" 2>/dev/null || true
    done
}

# -----------------------------------------------------------------------------
# GENERACIÓN DE INVENTARIO ANSIBLE
# -----------------------------------------------------------------------------
generate_inventory() {
    log_info "Generando inventario Ansible..."
    local inv_file="inventory/inventory.ini"
    mkdir -p inventory

    cat > "$inv_file" <<EOF
# Inventario para laboratorio AU294
# Generado automáticamente por setup-proxmox-lab.sh

[control]
ansible-control ansible_host=10.10.10.10 ansible_connection=local

[managed]
managed-node-01 ansible_host=10.10.10.11
managed-node-02 ansible_host=10.10.10.12
managed-node-03 ansible_host=10.10.10.13

[managed:children]
managed

[webservers]
managed-node-01
managed-node-02

[dbservers]
managed-node-03

[lab:children]
control
managed
EOF

    log_success "Inventario creado en $inv_file"
}

# -----------------------------------------------------------------------------
# EXPORTAR VARIABLES DE ENTORNO
# -----------------------------------------------------------------------------
export_env_vars() {
    log_info "Exportando variables de entorno..."

    cat > .env <<EOF
# Variables de configuración del laboratorio AU294
export PROXMOX_HOST=$PROXMOX_HOST
export PROXMOX_NODE=$PROXMOX_NODE
export PROXMOX_STORAGE=$PROXMOX_STORAGE
export LAB_NETWORK=$LAB_NETWORK
export ANSIBLE_INVENTORY=inventory/inventory.ini
EOF

    chmod +x .env
    log_success "Variables exportadas a .env"
}

# -----------------------------------------------------------------------------
# FUNCIÓN PRINCIPAL
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "=============================================="
    echo "  CONFIGURADOR LABORATORIO AU294"
    echo "  Red Hat Ansible Automation"
    echo "=============================================="
    echo ""

    check_dependencies
    get_proxmox_ticket
    create_bridge
    prepare_template
    create_vms
    configure_vms
    generate_inventory
    export_env_vars

    echo ""
    echo "=============================================="
    log_success "Laboratorio configurado correctamente"
    echo "=============================================="
    echo ""
    echo "Próximos pasos:"
    echo "  1. Inicia las VMs:  qm start <vm_id> ..."
    echo "  2. Accede al nodo de control: qm terminal <control_vm_id>"
    echo "  3. Configura SSH keys y prueba conectividad"
    echo "  4. Explora los ejercicios en exercises/"
    echo ""
}

# Ejecutar
main "$@"
