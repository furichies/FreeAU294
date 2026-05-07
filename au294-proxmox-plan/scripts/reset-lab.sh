#!/bin/bash
# =============================================================================
# reset-lab.sh - Reiniciar laboratorio AU294 a estado limpio
# =============================================================================
# Este script permite revertir las VMs a su estado inicial usando
# snapshots o volviendo a clonar desde la plantilla.
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RESET_MODE="${1:-snapshot}"

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

declare -A VMs
VMs["ansible-control"]="100"
VMs["managed-node-01"]="101"
VMs["managed-node-02"]="102"
VMs["managed-node-03"]="103"

reset_from_snapshot() {
    local vm_name=$1
    local vm_id=$2

    log_info "Restaurando $vm_name desde snapshot..."
    if qm listsnapshot "$vm_id" | grep -q "clean-state"; then
        qm snapshot-restore "$vm_id" "clean-state"
        log_success "$vm_name restaurado"
    else
        log_warn "No se encontró snapshot 'clean-state' para $vm_name"
        return 1
    fi
}

reset_from_template() {
    local vm_name=$1
    local vm_id=$2
    local template_id="9000"

    log_info "Recreando $vm_name desde plantilla..."
    qm stop "$vm_id" 2>/dev/null || true
    qm destroy "$vm_id" 2>/dev/null || true
    qm clone "$template_id" "$vm_id" -name "$vm_name" -full
    qm start "$vm_id"
    log_success "$vm_name recreado"
}

create_snapshots() {
    log_info "Creando snapshots de estado limpio..."

    for vm_name in "${!VMs[@]}"; do
        local vm_id="${VMs[$vm_name]}"
        if qm list | grep -q "$vm_id"; then
            qm snapshot-delete "$vm_id" "clean-state" 2>/dev/null || true
            qm snapshot "$vm_id" "clean-state"
            log_success "Snapshot creado para $vm_name"
        fi
    done
}

main() {
    echo ""
    echo "=============================================="
    echo "  RESETEAR LABORATORIO AU294"
    echo "=============================================="
    echo ""
    echo "Modo: $RESET_MODE"
    echo ""

    case "$RESET_MODE" in
        snapshot)
            for vm_name in "${!VMs[@]}"; do
                reset_from_snapshot "$vm_name" "${VMs[$vm_name]}" || true
            done
            ;;
        template)
            for vm_name in "${!VMs[@]}"; do
                reset_from_template "$vm_name" "${VMs[$vm_name]}" || true
            done
            ;;
        backup)
            create_snapshots
            ;;
        *)
            echo "Uso: $0 {snapshot|template|backup}"
            echo "  snapshot  - Restaurar desde snapshot 'clean-state'"
            echo "  template  - Recrear VMs desde plantilla"
            echo "  backup    - Crear snapshots de backup"
            ;;
    esac

    echo ""
    log_success "Operación completada"
    echo ""
}

main "$@"
