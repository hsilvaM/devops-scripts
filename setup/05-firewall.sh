#!/bin/bash
# Script de configuracion de firewall

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIREWALL_DIR="${SCRIPT_DIR}/../firewall"

# Cargar funciones comunes
if [ -f "${SCRIPT_DIR}/../config/common.sh" ]; then
    source "${SCRIPT_DIR}/../config/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Verificar que estamos como root
check_root

# Funcion principal
main() {
    log_section "Configuracion de Firewall"
    
    if [ ! -f "${FIREWALL_DIR}/firewall-config.sh" ]; then
        log_warn "Script de configuracion de firewall no encontrado"
        return 0
    fi
    
    log_progress "Ejecutando configuracion de firewall..."
    bash "${FIREWALL_DIR}/firewall-config.sh"
    
    if [ $? -eq 0 ]; then
        log_success "Firewall configurado exitosamente"
        log_info ""
        log_check "Servicios y puertos habilitados:"
        log_info "  - Jenkins (puerto 8080)"
        log_info "  - SSH (puerto 22)"
        log_info "  - HTTP/HTTPS (puertos 80, 443)"
        log_info "  - Docker"
        return 0
    else
        log_error "Error al configurar firewall"
        return 1
    fi
}

main "$@"
