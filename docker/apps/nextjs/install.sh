#!/bin/bash
# Script de instalacion de NextJS en Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../../config"
NEXTJS_DIR="${SCRIPT_DIR}/../../../apps/nextjs"

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

# Funcion para verificar si NextJS esta corriendo
nextjs_is_running() {
    if docker ps | grep -q nextjs-app; then
        return 0
    fi
    return 1
}

# Funcion para instalar NextJS
install_nextjs() {
    log_install "Instalando NextJS en Docker..."
    
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
    
    # Navegar al directorio de NextJS
    cd "$NEXTJS_DIR" || {
        log_error "No se puede acceder al directorio de NextJS"
        exit 1
    }
    
    # Construir imagen
    log_download "Construyendo imagen de NextJS..."
    docker compose build
    
    if [ $? -ne 0 ]; then
        log_error "Error al construir imagen de NextJS"
        exit 1
    fi
    
    # Iniciar NextJS
    log_install "Iniciando contenedor de NextJS..."
    docker compose up -d
    
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar NextJS"
        exit 1
    fi
    
    # Esperar a que NextJS inicie
    log_progress "Esperando a que NextJS inicie..."
    sleep 10
    
    # Verificar que NextJS este corriendo
    if nextjs_is_running; then
        log_success "NextJS iniciado exitosamente"
    else
        log_error "NextJS no pudo iniciarse correctamente"
        exit 1
    fi
    
    # Mostrar informacion de acceso
    log_info ""
    log_section "NextJS Instalado Exitosamente"
    log_info "URL de acceso: http://localhost:3002"
    log_info "Puerto: 3002"
    log_info ""
    log_check "Verificar logs de NextJS:"
    log_info "docker logs nextjs-app"
}

# Funcion principal
main() {
    log_section "Instalacion de NextJS en Docker"
    
    # Verificar si NextJS ya esta corriendo
    if nextjs_is_running; then
        log_success "NextJS ya esta corriendo"
        log_info "URL: http://localhost:3002"
        log_info ""
        log_check "Para reiniciar NextJS, ejecuta:"
        log_info "cd ${NEXTJS_DIR} && docker compose restart"
        log_info ""
        log_check "Para detener NextJS, ejecuta:"
        log_info "cd ${NEXTJS_DIR} && docker compose down"
        return 0
    fi
    
    # NextJS no esta instalado, proceder con instalacion
    install_nextjs
}

# Ejecutar funcion principal
main "$@"
