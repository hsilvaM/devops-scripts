#!/bin/bash
# Script de instalacion de la app PHP con Oracle en Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../../config"
PHP_APP_DIR="${SCRIPT_DIR}/../../../apps/php"
CONTAINER_NAME="php-oracle-app"

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

php_app_is_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

install_php_app() {
    log_install "Instalando app PHP con Oracle en Docker..."

    if ! docker_is_installed; then
        log_error "Docker no esta instalado. Ejecuta ./setup/02-docker.sh primero."
        exit 1
    fi

    if ! docker_service_running; then
        log_error "Docker no esta corriendo. Ejecuta: systemctl start docker"
        exit 1
    fi

    if [ ! -f "${PHP_APP_DIR}/.env" ]; then
        log_warn "No se encontro .env. Copia .env.example y define tus credenciales antes de continuar."
        exit 1
    fi

    if [ ! -d "${SCRIPT_DIR}/instantclient" ] || [ -z "$(ls -A "${SCRIPT_DIR}/instantclient")" ]; then
        log_error "No se encontraron los paquetes de Oracle Instant Client en ${SCRIPT_DIR}/instantclient"
        log_info "Descarga los ZIP (BasicLite y SDK) desde Oracle y colocalos en esa carpeta."
        exit 1
    fi

    if ! docker network ls | grep -q "apps-net"; then
        log_config "Creando red apps-net..."
        docker network create apps-net
    fi

    cd "${PHP_APP_DIR}" || {
        log_error "No se puede acceder al directorio de la app PHP"
        exit 1
    }

    log_download "Construyendo imagen de la app PHP..."
    docker compose build
    if [ $? -ne 0 ]; then
        log_error "Error al construir la imagen"
        exit 1
    fi

    log_install "Iniciando contenedor de la app PHP..."
    docker compose up -d
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar la app PHP"
        exit 1
    fi

    log_progress "Esperando a que Apache responda..."
    sleep 8

    if php_app_is_running; then
        log_success "App PHP con Oracle iniciada correctamente"
        log_section "Datos de acceso"
        log_info "URL: http://localhost:8080/"
        log_info "Container: ${CONTAINER_NAME}"
        log_check "Ver logs: docker logs -f ${CONTAINER_NAME}"
    else
        log_error "El contenedor no quedo en ejecucion"
        exit 1
    fi
}

main() {
    log_section "Instalacion de app PHP con Oracle"

    if php_app_is_running; then
        log_success "La app PHP ya esta corriendo"
        log_info "URL: http://localhost:8080/"
        log_check "Reiniciar: cd ${PHP_APP_DIR} && docker compose restart"
        log_check "Detener: cd ${PHP_APP_DIR} && docker compose down"
        return 0
    fi

    install_php_app
}

main "$@"

