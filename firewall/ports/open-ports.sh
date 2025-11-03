#!/bin/bash
# Script para abrir puertos especificos en firewalld

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../config"
PORTS_LIST="${SCRIPT_DIR}/../ports-list.conf"

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

# Funcion para abrir un puerto
open_port() {
    local protocol=$1
    local port=$2
    local description=$3
    local full_port="${protocol}/${port}"
    
    if firewall-cmd --list-ports | grep -q "${full_port}"; then
        log_check "Puerto '${full_port}' ($description) ya esta abierto"
        return 0
    fi
    
    log_config "Abriendo puerto '${full_port}' ($description)..."
    firewall-cmd --permanent --add-port="${full_port}"
    
    if [ $? -eq 0 ]; then
        log_success "Puerto '${full_port}' ($description) abierto"
    else
        log_warn "No se pudo abrir el puerto '${full_port}'"
        return 1
    fi
}

# Funcion principal
main() {
    log_section "Apertura de Puertos de Firewall"
    
    if [ ! -f "$PORTS_LIST" ]; then
        log_warn "Archivo $PORTS_LIST no encontrado"
        return 0
    fi
    
    while IFS= read -r line; do
        # Saltar lineas vacias y comentarios
        if [[ -z "$line" || "$line" =~ ^#.* ]]; then
            continue
        fi
        
        # Parsear formato: PROTOCOL:PORT|DESCRIPTION
        # Usar | como separador entre puerto y descripcion
        if [[ "$line" =~ ^([^:]+):([^|]+)\|(.*)$ ]]; then
            protocol="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
            description="${BASH_REMATCH[3]}"
            
            if [ -n "$protocol" ] && [ -n "$port" ]; then
                open_port "$protocol" "$port" "$description"
            else
                log_warn "Linea mal formateada: $line"
            fi
        else
            log_warn "Linea mal formateada: $line"
        fi
    done < "$PORTS_LIST"
    
    # Recargar firewall
    log_config "Recargando configuracion de firewall..."
    firewall-cmd --reload
    
    log_success "Puertos de firewall configurados exitosamente"
}

main "$@"