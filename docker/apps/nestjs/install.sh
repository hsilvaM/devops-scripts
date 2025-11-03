#!/bin/bash
# Script de instalacion de NestJS en Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../config"
NESTJS_DIR="${SCRIPT_DIR}/../../apps/nestjs"

# Cargar funciones comunes
if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

# Verificar que estamos como root
check_root

# Verificar que Docker esta instalado y corriendo
docker_is_installed() {
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version 2>/dev/null)
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

docker_service_running() {
    if systemctl is-active --quiet docker; then
        return 0
    fi
    return 1
}

# Funcion para verificar si NestJS esta corriendo
nestjs_is_running() {
    if docker ps | grep -q nestjs-app; then
        return 0
    fi
    return 1
}

# Funcion para instalar NestJS
install_nestjs() {
    log_install "Instalando NestJS en Docker..."
    
    if ! docker_is_installed; then
        log_error "Docker no esta instalado. Ejecuta ./setup/02-docker.sh primero"
        exit 1
    fi
    
    if ! docker_service_running; then
        log_error "Docker no esta corriendo. Ejecuta: systemctl start docker"
        exit 1
    fi
    
    # Crear red si no existe
    if ! docker network ls | grep -q apps-net; then
        log_config "Creando red apps-net..."
        docker network create apps-net
    fi
    
    # Navegar al directorio de NestJS
    cd "$NESTJS_DIR" || {
        log_error "No se puede acceder al directorio de NestJS"
        exit 1
    }
    
    # Construir imagen
    log_download "Construyendo imagen de NestJS..."
    docker compose build
    
    if [ $? -ne 0 ]; then
        log_error "Error al construir imagen de NestJS"
        exit 1
    fi
    
    # Iniciar NestJS
    log_install "Iniciando contenedor de NestJS..."
    docker compose up -d
    
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar NestJS"
        exit 1
    fi
    
    # Esperar a que NestJS inicie
    log_progress "Esperando a que NestJS inicie..."
    sleep 10
    
    # Verificar que NestJS este corriendo
    if nestjs_is_running; then
        log_success "NestJS iniciado exitosamente"
    else
        log_error "NestJS no pudo iniciarse correctamente"
        exit 1
    fi
    
    # Mostrar informacion de acceso
    log_info ""
    log_section "NestJS Instalado Exitosamente"
    log_info "URL de acceso: http://localhost:3001"
    log_info "Puerto: 3001"
    log_info ""
    log_check "Verificar logs de NestJS:"
    log_info "docker logs nestjs-app"
}

# Funcion principal
main() {
    log_section "Instalacion de NestJS en Docker"
    
    # Verificar si NestJS ya esta corriendo
    if nestjs_is_running; then
        log_success "NestJS ya esta corriendo"
        log_info "URL: http://localhost:3001"
        log_info ""
        log_check "Para reiniciar NestJS, ejecuta:"
        log_info "cd ${NESTJS_DIR} && docker compose restart"
        log_info ""
        log_check "Para detener NestJS, ejecuta:"
        log_info "cd ${NESTJS_DIR} && docker compose down"
        return 0
    fi
    
    # NestJS no esta instalado, proceder con instalacion
    install_nestjs
}

# Ejecutar funcion principal
main "$@"
