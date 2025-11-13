#!/bin/bash
# Script de instalacion de la API NestJS (api-portal) en Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../../config"
NESTJS_DIR="${SCRIPT_DIR}/../../../apps/nestjs"
APP_DIR="${NESTJS_DIR}/api-portal"
COMPOSE_FILE="${NESTJS_DIR}/docker-compose.yml"
ENV_FILE="${APP_DIR}/.env"
CONTAINER_NAME="nestjs-api-portal"

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

nestjs_is_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

ensure_env_file() {
    if [ ! -f "${ENV_FILE}" ]; then
        log_warn "No se encontro ${ENV_FILE}. Se creara uno vacio."
        touch "${ENV_FILE}"
    fi
}

install_nestjs() {
    log_install "Instalando API NestJS en Docker..."
    
    if ! docker_is_installed; then
        log_error "Docker no esta instalado. Ejecuta ./setup/02-docker.sh primero."
        exit 1
    fi
    
    if ! docker_service_running; then
        log_error "Docker no esta corriendo. Ejecuta: systemctl start docker"
        exit 1
    fi
    
    if [ ! -d "${APP_DIR}" ]; then
        log_error "No se encuentra la aplicacion api-portal en ${APP_DIR}"
        log_info ""
        log_info "Clona el repositorio antes de ejecutar este instalador:"
        log_info "git clone git@github.com-hsilvaM:EMETRA/api-portal.git ${APP_DIR}"
        exit 1
    fi

    if [ ! -f "${COMPOSE_FILE}" ]; then
        log_error "No se encontro docker-compose.yml en ${NESTJS_DIR}"
        exit 1
    fi

    ensure_env_file

    if ! docker network ls | grep -q "apps-net"; then
        log_config "Creando red apps-net..."
        docker network create apps-net
    fi
    
    cd "${NESTJS_DIR}" || {
        log_error "No se puede acceder al directorio de NestJS"
        exit 1
    }
    
    log_download "Construyendo imagen de la API NestJS..."
    docker compose build --pull
    if [ $? -ne 0 ]; then
        log_error "Error al construir la imagen de NestJS"
        exit 1
    fi
    
    log_install "Iniciando contenedor de la API NestJS..."
    docker compose up -d
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar el contenedor de NestJS"
        exit 1
    fi
    
    log_progress "Esperando a que la API NestJS responda..."
    sleep 8
    
    if nestjs_is_running; then
        log_success "API NestJS iniciada correctamente"
        log_section "Datos de acceso"
        log_info "URL: http://localhost:3003"
        log_info "Container: ${CONTAINER_NAME}"
        log_check "Ver logs: docker logs -f ${CONTAINER_NAME}"
    else
        log_error "El contenedor de NestJS no quedo en ejecucion"
        exit 1
    fi
}

main() {
    log_section "Instalacion de API NestJS en Docker"
    
    if nestjs_is_running; then
        log_success "La API NestJS ya esta corriendo"
        log_info "URL: http://localhost:3003"
        log_check "Reiniciar: cd ${NESTJS_DIR} && docker compose restart"
        log_check "Detener: cd ${NESTJS_DIR} && docker compose down"
        return 0
    fi
    
    install_nestjs
}

main "$@"

