#!/bin/bash
# Script de verificacion de pre-requisitos del sistema

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

# Cargar funciones comunes
if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Verificar que estamos como root
check_root

# Funcion para verificar si Docker esta instalado
docker_is_installed() {
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version 2>/dev/null)
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

# Funcion para verificar el servicio de Docker
docker_service_running() {
    if systemctl is-active --quiet docker; then
        return 0
    fi
    return 1
}

# Funcion para verificar Docker
check_docker() {
    log_info "Verificando Docker..."
    
    if docker_is_installed; then
        DOCKER_VERSION=$(docker --version)
        log_info "Docker esta instalado: $DOCKER_VERSION"
        
        if docker_service_running; then
            log_info "Servicio Docker esta corriendo"
            
            # Verificar que Docker funcione correctamente
            log_info "Ejecutando prueba de Docker..."
            if docker run --rm hello-world >/dev/null 2>&1; then
                log_info "Docker funciona correctamente"
                return 0
            else
                log_warn "Docker esta instalado pero no pudo ejecutar contenedores"
                log_warn "Esto puede ser normal en instalaciones sin acceso a internet"
                return 0
            fi
        else
            log_warn "Docker esta instalado pero el servicio no esta corriendo"
            log_warn "Ejecuta: systemctl start docker"
            return 1
        fi
    else
        log_warn "Docker no esta instalado"
        log_info "Ejecuta ./setup/02-docker.sh para instalarlo"
        return 1
    fi
}

# Funcion principal
main() {
    log_info "=== Verificacion de Pre-requisitos ==="
    
    # Verificar Docker
    DOCKER_OK=false
    if check_docker; then
        DOCKER_OK=true
    fi
    
    log_info "=== Resumen de Pre-requisitos ==="
    if [ "$DOCKER_OK" = true ]; then
        log_info "Docker: OK"
    else
        log_error "Docker: FALTA"
    fi
    
    if [ "$DOCKER_OK" = false ]; then
        log_error "Algunos pre-requisitos no estan cumplidos"
        exit 1
    fi
    
    log_info "Todos los pre-requisitos estan cumplidos"
    return 0
}

# Ejecutar funcion principal
main "$@"

