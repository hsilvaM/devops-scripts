#!/bin/bash
# Script para habilitar servicios en firewalld

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../config"
SERVICES_LIST="${SCRIPT_DIR}/../services-list.conf"

# Cargar funciones comunes
if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Verificar que estamos como root
check_root

# Verificar si firewalld esta instalado
if ! command_exists firewall-cmd; then
    log_install "firewalld no esta instalado. Instalando..."
    if command_exists dnf; then
        dnf install -y firewalld
    elif command_exists yum; then
        yum install -y firewalld
    else
        log_error "No se encuentra gestor de paquetes"
        exit 1
    fi
fi

# Iniciar firewalld si no esta corriendo
if ! systemctl is-active --quiet firewalld; then
    log_config "Iniciando servicio firewalld..."
    systemctl start firewalld
    systemctl enable firewalld
fi

# Funcion para habilitar un servicio
enable_service() {
    local service=$1
    
    if firewall-cmd --list-services | grep -q "^${service}$"; then
        log_check "Servicio '${service}' ya esta habilitado"
        return 0
    fi
    
    log_config "Habilitando servicio '${service}'..."
    firewall-cmd --permanent --add-service="${service}"
    
    if [ $? -eq 0 ]; then
        log_success "Servicio '${service}' habilitado"
    else
        log_warn "No se pudo habilitar el servicio '${service}'"
        return 1
    fi
}

# Funcion principal
main() {
    log_section "Habilitacion de Servicios de Firewall"
    
    if [ ! -f "$SERVICES_LIST" ]; then
        log_warn "Archivo $SERVICES_LIST no encontrado"
        return 0
    fi
    
    while IFS= read -r service; do
        # Saltar lineas vacias y comentarios
        if [[ -z "$service" || "$service" =~ ^#.* ]]; then
            continue
        fi
        
        enable_service "$service"
    done < "$SERVICES_LIST"
    
    # Recargar firewall
    log_config "Recargando configuracion de firewall..."
    firewall-cmd --reload
    
    log_success "Servicios de firewall configurados exitosamente"
}

main "$@"