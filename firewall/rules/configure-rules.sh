#!/bin/bash
# Script para configurar reglas de firewall en RHEL

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../config"

# Cargar funciones comunes
if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Verificar que estamos como root
check_root

# Verificar si firewalld esta instalado y corriendo
if ! command_exists firewall-cmd; then
    log_error "firewalld no esta instalado. Ejecuta firewall/services/enable-services.sh primero"
    exit 1
fi

if ! systemctl is-active --quiet firewalld; then
    log_error "firewalld no esta corriendo"
    exit 1
fi

# Funcion principal
main() {
    log_section "Configuracion de Reglas de Firewall"
    
    # Verificar zona por defecto
    local default_zone=$(firewall-cmd --get-default-zone)
    log_info "Zona por defecto: ${default_zone}"
    
    # Mostrar informacion de servicios y puertos habilitados
    log_info ""
    log_check "Servicios habilitados:"
    firewall-cmd --list-services --zone="${default_zone}"
    
    log_info ""
    log_check "Puertos abiertos:"
    local ports=$(firewall-cmd --list-ports --zone="${default_zone}")
    if [ -n "$ports" ]; then
        echo "$ports"
    else
        log_info "Ningun puerto abierto"
    fi
    
    log_info ""
    log_success "Configuracion de reglas completada"
}

main "$@"