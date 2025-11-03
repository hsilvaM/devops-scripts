#!/bin/bash
# Script de instalacion de Prometheus en Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../../config"
PROMETHEUS_DIR="${SCRIPT_DIR}/../../monitoring/prometheus"

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

# Funcion para verificar si Prometheus esta corriendo
prometheus_is_running() {
    if docker ps | grep -q prometheus; then
        return 0
    fi
    return 1
}

# Funcion para instalar Prometheus
install_prometheus() {
    log_install "Instalando Prometheus en Docker..."
    
    if ! docker_is_installed; then
        log_error "Docker no esta instalado. Ejecuta ./setup/02-docker.sh primero"
        exit 1
    fi
    
    if ! docker_service_running; then
        log_error "Docker no esta corriendo. Ejecuta: systemctl start docker"
        exit 1
    fi
    
    # Crear red si no existe
    if ! docker network ls | grep -q monitoring-net; then
        log_config "Creando red monitoring-net..."
        docker network create monitoring-net
    fi
    
    # Navegar al directorio de Prometheus
    cd "$PROMETHEUS_DIR" || {
        log_error "No se puede acceder al directorio de Prometheus"
        exit 1
    }
    
    # Descargar la imagen de Prometheus
    log_download "Descargando imagen oficial de Prometheus..."
    docker compose pull prometheus
    
    if [ $? -ne 0 ]; then
        log_error "Error al descargar imagen de Prometheus"
        exit 1
    fi
    
    # Iniciar Prometheus
    log_install "Iniciando contenedor de Prometheus..."
    docker compose up -d
    
    if [ $? -ne 0 ]; then
        log_error "Error al iniciar Prometheus"
        exit 1
    fi
    
    # Esperar a que Prometheus inicie
    log_progress "Esperando a que Prometheus inicie..."
    sleep 10
    
    # Verificar que Prometheus este corriendo
    if prometheus_is_running; then
        log_success "Prometheus iniciado exitosamente"
    else
        log_error "Prometheus no pudo iniciarse correctamente"
        exit 1
    fi
    
    # Mostrar informacion de acceso
    log_info ""
    log_section "Prometheus Instalado Exitosamente"
    log_info "URL de acceso: http://localhost:9090"
    log_info "Puerto: 9090"
    log_info ""
    log_check "Verificar logs de Prometheus:"
    log_info "docker logs prometheus"
}

# Funcion principal
main() {
    log_section "Instalacion de Prometheus en Docker"
    
    # Verificar si Prometheus ya esta corriendo
    if prometheus_is_running; then
        log_success "Prometheus ya esta corriendo"
        log_info "URL: http://localhost:9090"
        log_info ""
        log_check "Para reiniciar Prometheus, ejecuta:"
        log_info "cd ${PROMETHEUS_DIR} && docker compose restart"
        log_info ""
        log_check "Para detener Prometheus, ejecuta:"
        log_info "cd ${PROMETHEUS_DIR} && docker compose down"
        return 0
    fi
    
    # Prometheus no esta instalado, proceder con instalacion
    install_prometheus
}

# Ejecutar funcion principal
main "$@"
