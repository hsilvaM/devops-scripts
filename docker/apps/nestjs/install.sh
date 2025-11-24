#!/bin/bash
# Script de instalacion de las APIs NestJS (api-portal y api-autenticacion) en Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../../config"
NESTJS_DIR="${SCRIPT_DIR}/../../../apps/nestjs"
PORTAL_DIR="${NESTJS_DIR}/api-portal"
AUTH_DIR="${NESTJS_DIR}/api-autenticacion"
COMPOSE_FILE="${NESTJS_DIR}/docker-compose.yml"
PORTAL_ENV_FILE="${PORTAL_DIR}/.env"
AUTH_ENV_FILE="${AUTH_DIR}/.env"
PORTAL_CONTAINER_NAME="nestjs-api-portal"
AUTH_CONTAINER_NAME="nestjs-api-autenticacion"

if [ -f "${CONFIG_DIR}/common.sh" ]; then
    source "${CONFIG_DIR}/common.sh"
else
    echo "Error: No se encuentra common.sh"
    exit 1
fi

check_root

docker_is_installed() {
    if command_exists docker; then
        docker --version >/dev/null 2>&1 && return 0
    fi
    return 1
}

docker_service_running() {
    systemctl is-active --quiet docker
}

portal_is_running() {
    docker ps --format '{{.Names}}' | grep -q "^${PORTAL_CONTAINER_NAME}$"
}

auth_is_running() {
    docker ps --format '{{.Names}}' | grep -q "^${AUTH_CONTAINER_NAME}$"
}

ensure_env_file() {
    local env_file="$1"
    local app_name="$2"
    
    if [ ! -f "${env_file}" ]; then
        log_warn "No se encontro ${env_file}. Se creara uno vacio."
        touch "${env_file}"
    fi
}

install_nestjs() {
    log_install "Instalando APIs NestJS en Docker..."
    
    if ! docker_is_installed; then
        log_error "Docker no esta instalado. Ejecuta ./setup/02-docker.sh primero."
        exit 1
    fi
    
    if ! docker_service_running; then
        log_error "Docker no esta corriendo. Ejecuta: systemctl start docker"
        exit 1
    fi
    
    if [ ! -d "${PORTAL_DIR}" ]; then
        log_error "No se encuentra la aplicacion api-portal en ${PORTAL_DIR}"
        log_info ""
        log_info "Clona el repositorio antes de ejecutar este instalador:"
        log_info "git clone git@github.com-hsilvaM:EMETRA/api-portal.git ${PORTAL_DIR}"
        exit 1
    fi

    if [ ! -d "${AUTH_DIR}" ]; then
        log_error "No se encuentra la aplicacion api-autenticacion en ${AUTH_DIR}"
        log_info ""
        log_info "Clona el repositorio antes de ejecutar este instalador:"
        log_info "git clone git@github.com-hsilvaM:EMETRA/api-autenticacion.git ${AUTH_DIR}"
        exit 1
    fi

    if [ ! -f "${COMPOSE_FILE}" ]; then
        log_error "No se encontro docker-compose.yml en ${NESTJS_DIR}"
        exit 1
    fi

    ensure_env_file "${PORTAL_ENV_FILE}" "api-portal"
    ensure_env_file "${AUTH_ENV_FILE}" "api-autenticacion"

    if ! docker network ls | grep -q "apps-net"; then
        log_config "Creando red apps-net..."
        docker network create apps-net
    fi
    
    cd "${NESTJS_DIR}" || {
        log_error "No se puede acceder al directorio de NestJS"
        exit 1
    }
    
    log_download "Construyendo imagenes de las APIs NestJS..."
    docker compose build --pull
    if [ $? -ne 0 ]; then
        log_error "Error al construir las imagenes de NestJS"
        exit 1
    fi
    
    log_install "Iniciando contenedores de las APIs NestJS..."
    docker compose up -d
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar los contenedores de NestJS"
        exit 1
    fi
    
    log_progress "Esperando a que las APIs NestJS respondan..."
    sleep 8
    
    local portal_running=false
    local auth_running=false
    
    if portal_is_running; then
        portal_running=true
        log_success "API Portal iniciada correctamente"
    else
        log_error "El contenedor de API Portal no quedo en ejecucion"
    fi
    
    if auth_is_running; then
        auth_running=true
        log_success "API Autenticacion iniciada correctamente"
    else
        log_error "El contenedor de API Autenticacion no quedo en ejecucion"
    fi
    
    if [ "$portal_running" = true ] || [ "$auth_running" = true ]; then
        log_section "Datos de acceso"
        if [ "$portal_running" = true ]; then
            log_info "API Portal URL: http://localhost:3003"
            log_info "Container: ${PORTAL_CONTAINER_NAME}"
            log_check "Ver logs: docker logs -f ${PORTAL_CONTAINER_NAME}"
        fi
        if [ "$auth_running" = true ]; then
            log_info "API Autenticacion URL: http://localhost:3004"
            log_info "Container: ${AUTH_CONTAINER_NAME}"
            log_check "Ver logs: docker logs -f ${AUTH_CONTAINER_NAME}"
        fi
    fi
    
    if [ "$portal_running" = false ] && [ "$auth_running" = false ]; then
        log_error "Ningun contenedor de NestJS quedo en ejecucion"
        exit 1
    fi
}

main() {
    log_section "Instalacion de APIs NestJS en Docker"
    
    local portal_running=false
    local auth_running=false
    
    if portal_is_running; then
        portal_running=true
    fi
    
    if auth_is_running; then
        auth_running=true
    fi
    
    if [ "$portal_running" = true ] || [ "$auth_running" = true ]; then
        log_success "Las APIs NestJS ya estan corriendo"
        if [ "$portal_running" = true ]; then
            log_info "API Portal URL: http://localhost:3003"
        fi
        if [ "$auth_running" = true ]; then
            log_info "API Autenticacion URL: http://localhost:3004"
        fi
        log_check "Reiniciar: cd ${NESTJS_DIR} && docker compose restart"
        log_check "Detener: cd ${NESTJS_DIR} && docker compose down"
        return 0
    fi
    
    install_nestjs
}

main "$@"

